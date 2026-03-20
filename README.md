
---

# 🚀 DMI Book Review: Agentic 3-Tier Production Stack

This repository contains a fully automated, 3-tier production environment for the **Book Review App**, orchestrated via **Agentic AI (Claude Code)** and **Terraform**.

## 🏗️ Architecture Overview
The infrastructure is deployed on **Azure** across multiple Availability Zones for High Availability.

* **Web Tier:** Next.js Frontend on Ubuntu VMs (Public Subnets via App Gateway).
* **App Tier:** Node.js Backend APIs (Private Subnets via Internal LB).
* **Database Tier:** Azure MySQL Flexible Server (Private VNet Integration).
* **Security:** Tier-to-Tier NSG lockdown and NAT Gateway for private outbound traffic.



---

## 🤖 Agentic DevOps Framework
This project uses a "Skill & Hook" system to allow an AI Agent to manage infrastructure safely.

### **The Workforce (subagents.json)**
* **Sentry:** Handles environment validation and drift audits.
* **Pilot:** Handles deployments and application synchronization.
* **Janitor:** Handles safe decommissioning of resources.

### **The Orchestrator (hooks.sh)**
All actions must be routed through the `hooks.sh` orchestrator to ensure safety guardrails are triggered.

| Command | Subagent Triggered | Purpose |
| :--- | :--- | :--- |
| `./hooks.sh deploy` | Sentry ➔ Pilot | Audit environment then apply Terraform. |
| `./hooks.sh sync` | Pilot | Map TF outputs to App `.env` and verify health. |
| `./hooks.sh teardown`| Janitor | Safe destruction with `--force` requirement. |

---

## 🛠️ Quick Start

### **1. Prerequisites**
* Azure CLI (`az login`)
* Terraform v1.5+
* Claude Code (for Agentic execution)
* SSH Key in `~/.ssh/id_rsa.pub`

### **2. Initialization**
```bash
git clone https://github.com/adekiitan/Terraform-dmi.git
cd Terraform-dmi
terraform -chdir=terraform init
```

### **3. Agentic Deployment**
Ask Claude:
> *"Claude, follow the `TEST_PROTOCOL.md`. Start by running the `deploy` hook and report the Sentry audit results."*

---

## 📝 Governance & Documentation
* **`claude.md`**: The System Prompt and Standard Operating Procedures.
* **`TEST_PROTOCOL.md`**: The 6-Phase verification checklist.
* **`LESSONS_LEARNED.md`**: A living document of architectural "gotchas" and fixes.

---

### **Next Step for You**
Now that the `README.md` is ready, add it to your git staging and push:

```bash
git add README.md
git commit -m "docs: add comprehensive README for Agentic DevOps framework"
git push
```

