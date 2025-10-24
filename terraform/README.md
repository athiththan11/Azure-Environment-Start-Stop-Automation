# Terraform Configuration Files

This directory contains the Terraform infrastructure as code files for deploying Azure Automation resources to manage environment start/stop schedules.

## Core Configuration Files

- **`main.tf`** - Main Terraform configuration with all Azure resources
  - Azure Automation Account with Managed Identity
  - Automation Runbooks for start/stop operations  
  - Weekly schedules for automated execution
  - Automation variables for configuration
  - Role assignments for resource access (commented examples)

- **`variables.tf`** - Input variable definitions
  - Subscription and tenant configuration
  - Project and environment settings
  - Feature flags for different resource types
  - Optional resource-specific variables (commented)

- **`locals.tf`** - Local value definitions
  - Standardized tags for all resources
  - Common naming conventions

- **`versions.tf`** - Terraform and provider version constraints
  - Terraform version requirements
  - Azure RM provider configuration
  - Backend configuration for state management

## Configuration Files

- **`conf.auto.tfvars`** - Auto-loaded configuration variables (example template provided in `conf.auto.tfvars.example`)
- **`secrets.auto.tfvars`** - Auto-loaded sensitive variables (subscription/tenant IDs) (example template provided in `secrets.auto.tfvars.example`)

## Deployed Resources

This Terraform configuration deploys the following Azure resources:

### Core Infrastructure

- **Resource Group** - Contains all automation resources
- **Azure Automation Account** - Central automation service with Managed Identity

### Automation Runbooks

- **Environment Start Runbook** - PowerShell script to start resources
- **Environment Stop Runbook** - PowerShell script to stop resources

### Scheduling

- **Weekly Start Schedule** - Configurable start times (default: weekdays 8 AM)
- **Weekly Stop Schedule** - Configurable stop times (default: weekdays 8 PM)
- **Job Schedules** - Links runbooks to schedules

### Configuration Variables

- **String Variables** - Runtime configuration parameters
- **Boolean Variables** - Feature flags for different resource types:
  - `start-stop-vm` - Virtual Machine management
  - `start-stop-vmss` - Virtual Machine Scale Set management
  - `start-stop-firewall` - Azure Firewall management
  - `start-stop-aks` - AKS cluster management
  - `start-stop-app-gateway` - Application Gateway management
  - `enable-disable-db-auto-pause` - Database auto-pause management

### Role-Based Access Control (RBAC)

The configuration includes commented examples for role assignments to grant the Automation Account's Managed Identity access to:

- Virtual Machines (Contributor)
- Virtual Machine Scale Sets (Contributor)
- Azure Firewalls (Contributor)
- AKS Clusters (Contributor)
- SQL Servers (Contributor)
- Application Gateways (Contributor)
- Virtual Networks (Reader)

## Usage

### Basic Deployment

```bash
# Initialize Terraform (first time only)
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply configuration
terraform apply

# Destroy resources (when needed)
terraform destroy
```

### With Custom Variables

```bash
# Plan with specific variable values
terraform plan -var="project=myproject" -var="environment=dev"

# Apply with custom configuration
terraform apply -var="project=myproject" -var="environment=dev"
```

## Configuration

### Required Variables

Set these in your `secrets.auto.tfvars` file:

```hcl
subscription_id = "your-azure-subscription-id"
tenant_id       = "your-azure-tenant-id"
```

### Optional Variables

Configure in `conf.auto.tfvars`:

```hcl
project     = "envautomation"
environment = "dev"
location    = "eastus2"
padding     = "001"

# Feature flags
start_stop_vm                = true
start_stop_vmss              = true
start_stop_firewall          = true
start_stop_aks               = true
start_stop_app_gateway       = true
enable_disable_db_auto_pause = true
```

## Security & Permissions

The Automation Account uses a **System-assigned Managed Identity** for secure access to Azure resources. To enable the automation to manage your resources, uncomment and configure the role assignment modules in `main.tf` with your specific resource IDs.

## Dependencies

This configuration uses external Terraform modules from:

- [WSO2 Azure Terraform Modules](https://github.com/wso2/azure-terraform-modules)

## Troubleshooting

### Common Issues

1. **Module Source Errors**: Ensure you have access to the referenced Git repository
2. **Permission Errors**: Verify your Azure credentials have sufficient permissions
3. **Resource Conflicts**: Check for existing resources with the same names
4. **Schedule Timezone**: Verify timezone settings match your requirements

### Validation Commands

```bash
# Check Terraform formatting
terraform fmt -check

# Validate configuration syntax
terraform validate

# Plan with detailed output
terraform plan -detailed-exitcode
```
