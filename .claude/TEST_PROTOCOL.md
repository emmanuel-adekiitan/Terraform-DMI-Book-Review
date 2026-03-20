
---

# 🧪 3-Tier Infrastructure Test Protocol
**Project:** Book Review App (Azure/Terraform)  
**Engineer:** Emmanuel Adekiitan  
**Environment:** Production (Lagos / West Europe)

---

## **Phase 1: Pre-Flight & Environment Check**
*Goal: Ensure the local environment is synced with the Azure Cloud subscription.*

| Step | Action | Expected Result | Command |
| :--- | :--- | :--- | :--- |
| **1.1** | Verify Azure Login | Sub ID matches `terraform.tfvars` | `./skills/validation/verify-env.sh` |
| **1.2** | Initialize Directory | Providers downloaded & modules linked | `terraform -chdir=terraform init` |
| **1.3** | Syntax Validation | "The configuration is valid" | `terraform -chdir=terraform validate` |

---

## **Phase 2: Infrastructure Audit (Safety Gate)**
*Goal: Prevent accidental resource destruction before deployment.*

* **Action:** Run `./skills/validation/check-drift.sh`.
* **Success Criteria:** Script returns `Safe to proceed`.
* **Failure Criteria:** If "to destroy" is detected, manually inspect `skills/tmp/last_plan.json`.

---

## **Phase 3: Deployment & Automated Sync**
*Goal: Provision resources and map connection strings.*

* **Action:** Run `./skills/core/apply.sh`.
* **Verification Steps:**
    1. Check Azure Portal for `rg-dmi-book-review-prod`.
    2. Verify `.env` exists in `book-review-app/` with correct `DB_HOST`.
    3. Confirm `terraform.tfstate` is updated locally.

---

## **Phase 4: Multi-Tier Connectivity Tests**
*Goal: Ensure traffic flows correctly through Web, App, and DB layers.*

### **4.1 External Connectivity (Tier 1)**
* **Action:** Run `./skills/validation/verify-health.sh`.
* **Requirement:** App Gateway Public IP must return HTTP `200 OK`.

### **4.2 Internal App-to-DB Link (Tier 2 & 3)**
* **Manual Validation:** ```bash
    # 1. SSH into Web VM
    ssh bookadmin@<WEB_VM_IP>
    
    # 2. Test DB Port from VM
    nc -zv <DB_HOST_FROM_ENV> 3306
    ```
* **Success Criteria:** Connection to **3306** is `Succeeded`.

---

## **Phase 5: Security & Governance Audit**
*Goal: Confirm "Agentic Safety Hooks" and NSGs are active.*

* **NSG Lockdown:** Confirm Database subnet has **no** Public IP.
* **Secret Rotation:** Run `./skills/automation/rotate-keys.sh`; verify `db_password` change in `.tfvars`.
* **Destruction Guard:** Run `./skills/core/destroy.sh` (no flags). **Must fail** without `--force`.

---

## **Phase 6: Cleanup (Optional)**
* **Command:** `./skills/core/destroy.sh --force`
* **Verification:** Confirm Resource Group deletion in Azure Portal.

---

### **How to Trigger the Agent**
Copy and paste this into your chat with Claude Code:
> *"Claude, I have finalized the `TEST_PROTOCOL.md`. Please execute **Phase 1** and **Phase 2** now. Report the status of each step and stop if you encounter any mismatches."*

