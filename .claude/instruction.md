# Project: DMI-Book-Review-Production
# Role: Senior Agentic DevOps Engineer

## 1. High-Level Architecture
- **Cloud Provider:** Azure
- **Architecture:** Three-Tier (Web, App, Database)
- **High Availability:** Multi-AZ (Zones 1 & 2)
- **Governance:** Infrastructure as Code (Terraform) with Agentic Hooks.

## 2. Networking Spec (CIDR: 10.0.0.0/16)
| Tier | Subnet Name | CIDR Block | Purpose |
| :--- | :--- | :--- | :--- |
| **Web** | `snet-web-01` | `10.0.1.0/24` | Public (Zone 1) - Frontend VMs |
| **Web** | `snet-web-02` | `10.0.2.0/24` | Public (Zone 2) - Frontend VMs |
| **App** | `snet-app-01` | `10.0.3.0/24` | Private (Zone 1) - Backend APIs |
| **App** | `snet-app-02` | `10.0.4.0/24` | Private (Zone 2) - Backend APIs |
| **DB** | `snet-db-01`  | `10.0.5.0/24` | Private (Zone 1) - MySQL Flexible |
| **DB** | `snet-db-02`  | `10.0.6.0/24` | Private (Zone 2) - MySQL Flexible |

## 3. Resource Naming Conventions
- **Prefix:** `dmi-br-` (DMI Book Review)

- **Resource Group:** `rg-dmi-book-review-prod`
- **Application Gateway:** `agw-dmi-frontend`
- **Internal LB:** `ilb-dmi-backend`
- **Database:** `mysql-dmi-prod`

## 4. Security Enforcement (NSG Rules)
1. **Web Tier:** Allow Port 80/443 from Internet (via AgW).
2. **App Tier:** Allow Port 3001 **only** from Web Subnets.
3. **DB Tier:** Allow Port 3306 **only** from App Subnets.
4. **Management:** SSH allowed only from Admin Public IP.

## 5. Agentic Skills & Hooks
- **Skill [Swap]:** Must verify 2GB Swap file exists on all VMs.
- **Skill [NAT]:** App Subnets must route via NAT Gateway for outbound updates.
- **Hook [Pre-Apply]:** Validate CIDR overlaps before running Terraform.

## 6. Database Tier (MySQL Flexible)
- **SKU:** `GP_Standard_D2ds_v4` (General Purpose) or `B2ms` (Burstable - check regional availability).
- **Version:** `8.0.21`
- **High Availability:** `SameZone` or `ZoneRedundant` (Zone 1 Primary, Zone 2 Standby).
- **Storage:** 20GB Auto-grow enabled.
- **Constraint:** Must use `private_dns_zone` for VNet integration.

## Agentic Rules
1. **Always** verify the Application Gateway `operationalState` before deploying.
2. **Never** run `npm run build` without verifying Swap Space is active (Min 2GB).

## 🧩 Subagent Configurations

## 🧩 Agentic Workforce (Registry)
Refer to `./subagents.json` for detailed persona definitions, command restrictions, and mission parameters.

1. **Sentry:** Run for all audits and health checks.
2. **Pilot:** Run for deployments once Sentry clears the path.
3. **Janitor:** Run only for authorized decommissioning.

**Rule:** Claude must announce which subagent persona it is adopting before executing a skill category.
*(Example: "Adopting Sentry persona to verify environment...")*

## 🛡️ Execution Governance (The Hook Rule)
Claude is **PROHIBITED** from calling scripts in `./skills/core/` directly. 
All infrastructure actions MUST route through the `hooks.sh` orchestrator.

- **To Deploy:** Run `./hooks.sh deploy` (Triggers Sentry -> Pilot).
- **To Sync:** Run `./hooks.sh sync` (Triggers Automation -> Health).
- **To Destroy:** Run `./hooks.sh teardown --force` (Triggers Janitor).