
---

# 🚀 Agentic 3-Tier Book Review Stack on Azure

A production-grade, 3-tier web application architecture deployed using **Agentic Infrastructure as Code (IaC)**. This project demonstrates the evolution from manual "Click-Ops" to modular, AI-orchestrated deployment in the **Sweden Central** region.

---

## 🏗️ Architecture Overview

The stack consists of **38 managed resources** organized into three distinct, isolated tiers. This setup ensures high availability, security, and scalability.

| Layer | Component | Technical Specification | Purpose |
| :--- | :--- | :--- | :--- |
| **Ingress** | **App Gateway v2** | Standard_v2 SKU w/ WAF Policies | SSL Termination & Path-based routing (`/api` vs `/`) |
| **Web Tier** | **2x Ubuntu VMs** | `Standard_D2s_v3` (Sweden Central) | Nginx Reverse Proxy hosting the Next.js Frontend |
| **App Tier** | **2x Ubuntu VMs** | `Standard_D2s_v3` (Sweden Central) | Node.js Runtime for the Book Review API |
| **Internal LB**| **Standard ILB** | Private VIP: `10.0.7.10` | High Availability & Decoupling for the App Tier |
| **Data Tier** | **MySQL Flexible** | `GP_Standard_D2ds_v4` (General Purpose) | Persistent storage with Private VNet access |
| **Security** | **NSG & DNS** | State-aware Rules & Private DNS | Zero public DB exposure; Least Privilege access |

---

## 🌐 Networking Topology

We implemented a **Zero-Trust** network model across 7 subnets within a `10.0.0.0/16` Virtual Network.

| Subnet Name | Address Prefix | Resource | Private IP | Role |
| :--- | :--- | :--- | :--- | :--- |
| `snet-appgw` | `10.0.0.0/24` | **App Gateway v2** | `20.91.201.118` (Public) | External Entry Point |
| `snet-web-01`| `10.0.1.0/24` | `vm-dmi-web-01` | `10.0.1.4` | Web Server (Node A) |
| `snet-web-02`| `10.0.2.0/24` | `vm-dmi-web-02` | `10.0.2.4` | Web Server (Node B) |
| **`snet-ilb`** | **`10.0.7.0/24`** | **Internal LB** | **`10.0.7.10`** | **Internal VIP (App Tier)** |
| `snet-app-01`| `10.0.3.0/24` | `vm-dmi-app-01` | `10.0.3.5` | API Server (Node A) |
| `snet-app-02`| `10.0.4.0/24` | `vm-dmi-app-02` | `10.0.4.4` | API Server (Node B) |
| `snet-db-01` | `10.0.5.0/24` | **MySQL Flexible**| `10.0.5.4` | Private Data Tier |

---

## 🤖 The Agentic Workflow (Claude Code)

This project moves beyond standard automation by using **Claude Code** as an autonomous SRE agent to orchestrate the lifecycle.

* **Model Context Protocol (MCP)**: Leveraged to give the agent "project memory" via a custom `CLAUDE.md`.
* **Sub-Agent Skills**: Specialized Python scripts used by the agent to perform **Raw Socket Handshakes** to Port 3306, verifying the MySQL backend before confirming the deployment.
* **Safety Hooks**: Implemented `SAY/DO/LOG` workflows to provide a transparent audit trail of every automated action.

---

## 🛠️ Lessons Learned & Troubleshooting

### **1. The Sweden Central Pivot**
Originally targeted for **West Europe**, the deployment hit regional capacity blocks for the `D2ds_v4` SKU. Using the agent, we instantly refactored the Terraform modules and shifted the entire 38-resource stack to **Sweden Central** in minutes.

### **2. State Recovery (403 Forbidden Error)**
Encountered a tenant-level Conditional Access policy that locked the remote backend storage account.
* **Strategy**: Executed a "Scorched Earth" recovery—force-cleared partial Resource Groups, migrated to a **Local Backend**, and re-initialized the stack to maintain project momentum.

### **3. Zero-Trust Verification**
Confirmed that the database is "dark" to the public internet. Connectivity was verified via a **Private DNS Zone** (`dmi.mysql.database.azure.com`) linked exclusively to the production VNet.

---

## 🚀 Deployment & Destruction

1.  **Initialize**: `terraform init`
2.  **Audit**: `claude run "Verify networking modules and regional compliance"`
3.  **Apply**: `terraform apply -auto-approve`
4.  **Destroy**: Once verified, the stack was deleted via `terraform destroy` to maintain strict cost governance.

---
*Developed as part of the DevOps Micro Internship by Emmanuel Opeyemi Adekiitan.*

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
git clone https://github.com/emmanuel-adekiitan/Terraform-DMI-Book-Review.git 
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