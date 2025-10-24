# Azure Environment Start & Stop Automation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-1.10.3-blue.svg)](https://www.terraform.io/)

This repository contains PowerShell scripts and Terraform templates to automate the start and stop of Azure environments (Dev, QA, Stage) using Azure Automation Runbooks and Schedules. The goal is to reduce Azure compute costs in lower environments by shutting down unused resources outside working hours and starting them automatically when needed.

## 🎯 Features

- **Automated Scheduling**: Weekly schedules for starting/stopping resources (configurable times and days)
- **Multi-Resource Support**: VMs, VMSS, Azure Firewalls, AKS clusters, Application Gateways, and SQL Database auto-pause
- **Managed Identity**: Secure authentication using Azure Automation Account's system-assigned identity
- **Flexible Configuration**: Boolean flags to enable/disable automation for different resource types
- **External Modules**: Built using WSO2 Azure Terraform modules for reliability and best practices
- **Cost Optimization**: Significant cost savings by stopping unused non-production resources
- **Production Safety**: Configurable to avoid accidentally affecting production environments

## Repository Structure

```
Azure-Environment-Start-Stop-Automation/
├── terraform/                        # Infrastructure as Code
│   ├── main.tf                       # Main Terraform configuration
│   ├── variables.tf                  # Input variable definitions
│   ├── locals.tf                     # Local value definitions
│   ├── versions.tf                   # Provider version constraints
│   ├── conf.auto.tfvars.example      # Example configuration file
│   ├── secrets.auto.tfvars.example   # Example secrets file
│   └── README.md                     # Terraform-specific documentation
├── scripts/                          # PowerShell automation scripts
│   ├── Start-Environment.ps1         # Start resources script
│   └── Stop-Environment.ps1          # Stop resources script  
├── docs/                             # Documentation
│   └── deployment-guide.md           # Step-by-step deployment guide
└── README.md                         # This file
```

## Quick Start

### Prerequisites

- Azure subscription with appropriate permissions
- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

### 1. Clone the Repository

```bash
git clone https://github.com/athiththan11/Azure-Environment-Start-Stop-Automation.git
cd Azure-Environment-Start-Stop-Automation
```

### 2. Configure Azure Authentication

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"
```

### 3. Configure Terraform Variables

Create or update configuration files from examples:

```bash
# Copy example configuration files
cp terraform/conf.auto.tfvars.example terraform/conf.auto.tfvars
cp terraform/secrets.auto.tfvars.example terraform/secrets.auto.tfvars

# Edit with your actual values
vim terraform/conf.auto.tfvars        # Project, environment, location settings
vim terraform/secrets.auto.tfvars     # Azure subscription and tenant IDs
```

### 4. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 5. Configure Resource Access

After deployment, configure role assignments for the Automation Account's Managed Identity to access your target resources. Uncomment and configure the RBAC modules in `terraform/main.tf` with your specific resource IDs.

## Deployed Architecture

The Terraform configuration creates:

- **Resource Group**: Contains all automation resources
- **Azure Automation Account**: Central service with system-assigned Managed Identity
- **Automation Runbooks**: PowerShell scripts for start/stop operations
- **Weekly Schedules**: Configurable start/stop times and days
- **Job Schedules**: Links runbooks to execution schedules
- **Automation Variables**: Runtime configuration and feature flags

## Configuration

### Required Configuration Files

#### `secrets.auto.tfvars`

```hcl
subscription_id = "your-azure-subscription-id"
tenant_id       = "your-azure-tenant-id"
```

#### `conf.auto.tfvars`

```hcl
project     = "envautomation"
environment = "dev"
location    = "eastus2"
padding     = "001"

# Resource type automation flags
start_stop_vm                = true
start_stop_vmss              = true
start_stop_firewall          = true
start_stop_aks               = true
start_stop_app_gateway       = true
enable_disable_db_auto_pause = true
```

### Default Schedule Configuration

- **Start Time**: Weekdays at 8:00 AM (Asia/Colombo timezone)
- **Stop Time**: Weekdays at 8:00 PM (Asia/Colombo timezone)  
- **Days**: Monday through Friday
- **Timezone**: Asia/Colombo (configurable in Terraform)

### Supported Resource Types

| Resource Type | Automation Variable | Description |
|---------------|-------------------|-------------|
| Virtual Machines | `start_stop_vm` | Start/Stop VMs |
| VM Scale Sets | `start_stop_vmss` | Start/Stop VMSS instances |
| Azure Firewalls | `start_stop_firewall` | Start/Stop firewall services |
| AKS Clusters | `start_stop_aks` | Start/Stop Kubernetes clusters |
| Application Gateway | `start_stop_app_gateway` | Start/Stop app gateways |
| SQL Databases | `enable_disable_db_auto_pause` | Enable/disable auto-pause |

## Cost Savings

Typical cost savings achieved:

- **Development Environments**: 60-75% reduction (16 hours/day savings)
- **QA Environments**: 50-65% reduction (12 hours/day + weekends)
- **Staging Environments**: 40-55% reduction (8 hours/day + weekends)

## Security

- **Managed Identity**: Uses Azure Automation Account's system-assigned managed identity
- **Role-Based Access Control (RBAC)**: Granular permissions for each resource type
- **No Hardcoded Credentials**: All authentication through Azure AD
- **Audit Logging**: All automation activities logged in Azure
- **Production Protection**: Configurable safeguards to avoid production environments

## Dependencies

This project uses external Terraform modules from:

- [WSO2 Azure Terraform Modules](https://github.com/wso2/azure-terraform-modules)

Required Azure provider versions:

- `azurerm` = "4.30.0"
- Terraform >= 1.10.3

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

⭐ If this project helps you save costs, please give it a star!
