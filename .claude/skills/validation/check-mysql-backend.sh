#!/bin/bash
# ============================================================
# Skill : check_mysql_backend
# Target: vm-dmi-app-01 (10.0.3.5) — run directly on the VM
# Purpose: Validate DNS resolution, TCP reachability, and
#          MySQL protocol handshake for the private Flexible
#          Server endpoint.
# Usage : bash check-mysql-backend.sh
# ============================================================

# ── Colour helpers (inline — no dependency on common.sh) ────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; RESULTS+=("PASS  | $1"); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; RESULTS+=("FAIL  | $1"); FAILURES=$((FAILURES+1)); }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
sep()  { echo -e "${BOLD}──────────────────────────────────────────────────────${NC}"; }

# ── Config ───────────────────────────────────────────────────
MYSQL_HOST="mysql-dmi-prod-server.mysql.database.azure.com"
MYSQL_PORT=3306
EXPECTED_SUBNET="10.0."        # Private IP must start with this prefix
TIMEOUT=5
FAILURES=0
declare -a RESULTS

sep
echo -e "${BOLD}  MySQL Backend Diagnostic — vm-dmi-app-01${NC}"
echo -e "  Target : ${MYSQL_HOST}:${MYSQL_PORT}"
echo -e "  Date   : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
sep

# ════════════════════════════════════════════════════════════
# CHECK 1 — DNS Resolution
# ════════════════════════════════════════════════════════════
echo ""
info "CHECK 1/3 — DNS Resolution via Private DNS Zone"

if ! command -v dig &>/dev/null && ! command -v nslookup &>/dev/null; then
    fail "Neither 'dig' nor 'nslookup' found. Install dnsutils: apt-get install -y dnsutils"
else
    # Prefer dig; fall back to nslookup
    if command -v dig &>/dev/null; then
        RESOLVED_IP=$(dig +short "$MYSQL_HOST" | tail -1)
    else
        RESOLVED_IP=$(nslookup "$MYSQL_HOST" 2>/dev/null | awk '/^Address: / { print $2 }' | tail -1)
    fi

    if [ -z "$RESOLVED_IP" ]; then
        fail "DNS: '$MYSQL_HOST' did not resolve to any address"
        warn "Ensure the Private DNS Zone 'dmi.mysql.database.azure.com' is linked to vnet-dmi-br-prod"
    elif [[ "$RESOLVED_IP" == ${EXPECTED_SUBNET}* ]]; then
        pass "DNS: '$MYSQL_HOST' → ${RESOLVED_IP} (private IP confirmed)"
    else
        fail "DNS: '$MYSQL_HOST' resolved to ${RESOLVED_IP} — expected a ${EXPECTED_SUBNET}x.x address"
        warn "Public endpoint may be resolving. Check Private DNS Zone VNet link."
    fi
fi

# ════════════════════════════════════════════════════════════
# CHECK 2 — TCP Port Reachability (nc)
# ════════════════════════════════════════════════════════════
echo ""
info "CHECK 2/3 — TCP Port ${MYSQL_PORT} Reachability (nc)"

if ! command -v nc &>/dev/null; then
    fail "'nc' not found. Install: apt-get install -y netcat-openbsd"
else
    NC_OUTPUT=$(nc -zv -w "$TIMEOUT" "$MYSQL_HOST" "$MYSQL_PORT" 2>&1)
    NC_EXIT=$?

    if [ $NC_EXIT -eq 0 ]; then
        pass "TCP: Port ${MYSQL_PORT} is OPEN on ${MYSQL_HOST}"
        info "  nc output: ${NC_OUTPUT}"
    else
        fail "TCP: Port ${MYSQL_PORT} is CLOSED or filtered on ${MYSQL_HOST}"
        warn "  nc output: ${NC_OUTPUT}"
        warn "  Check: nsg-dmi-db AllowAppToDB rule (src 10.0.3.0/24 + 10.0.4.0/24 → port 3306)"
    fi
fi

# ════════════════════════════════════════════════════════════
# CHECK 3 — MySQL Protocol Handshake
# Tries mysql-connector-python first; falls back to raw socket.
# No credentials needed — the server greeting arrives before auth.
# ════════════════════════════════════════════════════════════
echo ""
info "CHECK 3/3 — MySQL Protocol Handshake"

PYTHON_BIN=$(command -v python3 || command -v python)

if [ -z "$PYTHON_BIN" ]; then
    fail "Python not found. Install: apt-get install -y python3"
else
    info "  Python: $PYTHON_BIN"

    # ── 3a: Try mysql-connector-python (if installed) ────────
    CONNECTOR_AVAILABLE=$($PYTHON_BIN -c "import mysql.connector; print('yes')" 2>/dev/null)

    if [ "$CONNECTOR_AVAILABLE" = "yes" ]; then
        info "  Strategy: mysql-connector-python (full driver handshake)"

        CONNECTOR_RESULT=$($PYTHON_BIN - <<'PYEOF' 2>&1
import sys
import mysql.connector
from mysql.connector import errorcode

HOST  = "mysql-dmi-prod-server.mysql.database.azure.com"
PORT  = 3306

try:
    # We intentionally connect with a wrong password.
    # A successful TCP+TLS handshake will return ER_ACCESS_DENIED_ERROR (1045),
    # confirming the server is live and reachable — not a network failure.
    cnx = mysql.connector.connect(
        host=HOST, port=PORT,
        user="diagnostic_probe", password="probe_intentionally_wrong",
        connect_timeout=5, ssl_disabled=False
    )
    cnx.close()
    print("CONNECTED")
except mysql.connector.Error as err:
    if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
        # Access denied = server responded = handshake succeeded
        print(f"HANDSHAKE_OK: {err.msg}")
    elif err.errno == errorcode.CR_CONN_HOST_ERROR:
        print(f"CONN_FAILED: {err.msg}")
        sys.exit(1)
    else:
        print(f"ERROR_{err.errno}: {err.msg}")
        sys.exit(1)
except Exception as e:
    print(f"EXCEPTION: {e}")
    sys.exit(1)
PYEOF
)
        if echo "$CONNECTOR_RESULT" | grep -qE "^(CONNECTED|HANDSHAKE_OK)"; then
            pass "Handshake: MySQL server responded (mysql-connector-python)"
            info "  Result: ${CONNECTOR_RESULT}"
        else
            fail "Handshake: mysql-connector-python failed — ${CONNECTOR_RESULT}"
        fi

    else
        # ── 3b: Raw socket fallback ──────────────────────────
        warn "  mysql-connector-python not installed. Install: pip3 install mysql-connector-python"
        info "  Strategy: raw socket — reading MySQL server greeting packet"

        SOCKET_RESULT=$($PYTHON_BIN - <<'PYEOF' 2>&1
import socket
import sys

HOST    = "mysql-dmi-prod-server.mysql.database.azure.com"
PORT    = 3306
TIMEOUT = 5

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(TIMEOUT)
    s.connect((HOST, PORT))
    greeting = s.recv(256)
    s.close()

    if len(greeting) < 5:
        print(f"SHORT_PACKET: only {len(greeting)} bytes received")
        sys.exit(1)

    # MySQL Initial Handshake Packet (protocol v10):
    #   Bytes 0-3  : packet length + sequence (little-endian)
    #   Byte  4    : protocol version (0x0a = 10 for MySQL 5+/8)
    #   Bytes 5+   : null-terminated server version string
    protocol_version = greeting[4]

    if protocol_version == 10:
        # Extract server version string (null-terminated, starts at byte 5)
        try:
            null_pos  = greeting.index(b'\x00', 5)
            version   = greeting[5:null_pos].decode('utf-8', errors='replace')
        except ValueError:
            version   = "<version string not terminated>"
        print(f"GREETING_OK  protocol=10  version={version}")
    elif protocol_version == 255:
        # Error packet — server sent an error instead of greeting
        error_msg = greeting[7:].decode('utf-8', errors='replace').lstrip('\x00')
        print(f"SERVER_ERROR: {error_msg}")
        sys.exit(1)
    else:
        # Might be TLS-first (protocol_version byte is part of TLS ClientHello)
        # Acceptable — server is responding
        print(f"GREETING_RECEIVED  protocol_byte={protocol_version:#04x}  len={len(greeting)}")

except socket.timeout:
    print(f"TIMEOUT: no response from {HOST}:{PORT} within {TIMEOUT}s")
    sys.exit(1)
except ConnectionRefusedError:
    print(f"REFUSED: {HOST}:{PORT} actively refused the connection")
    sys.exit(1)
except OSError as e:
    print(f"NETWORK_ERROR: {e}")
    sys.exit(1)
PYEOF
)
        SOCKET_EXIT=$?
        if [ $SOCKET_EXIT -eq 0 ]; then
            pass "Handshake: MySQL greeting received (raw socket)"
            info "  Result: ${SOCKET_RESULT}"
        else
            fail "Handshake: raw socket failed — ${SOCKET_RESULT}"
        fi
    fi
fi

# ════════════════════════════════════════════════════════════
# FINAL REPORT
# ════════════════════════════════════════════════════════════
echo ""
sep
echo -e "${BOLD}  DIAGNOSTIC REPORT — $(date -u '+%Y-%m-%d %H:%M UTC')${NC}"
sep
for LINE in "${RESULTS[@]}"; do
    if [[ "$LINE" == PASS* ]]; then
        echo -e "  ${GREEN}${LINE}${NC}"
    else
        echo -e "  ${RED}${LINE}${NC}"
    fi
done
sep

if [ $FAILURES -eq 0 ]; then
    echo -e "\n  ${GREEN}${BOLD}OVERALL: ALL CHECKS PASSED ✓${NC}"
    echo -e "  MySQL backend on snet-db-01 is reachable from the App Tier.\n"
    exit 0
else
    echo -e "\n  ${RED}${BOLD}OVERALL: ${FAILURES} CHECK(S) FAILED ✗${NC}"
    echo -e "  Review NSG rules, Private DNS Zone link, and MySQL server status.\n"
    exit 1
fi
