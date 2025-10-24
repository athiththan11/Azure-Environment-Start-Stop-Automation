# Copilot Instructions for Azure Environment Start & Stop Automation

## Project Overview

This repository contains infrastructure as code (Terraform) and PowerShell automation scripts designed to automatically start and stop Azure environments (Dev, QA, Stage) to reduce costs in non-production environments.

## Architecture & Components

### Core Components

- **Terraform Infrastructure**: Uses WSO2 Azure Terraform modules for Azure Automation Account, Runbooks, and Weekly Schedules
- **PowerShell Scripts**: Contains the logic for starting/stopping Azure resources via Automation Runbooks
- **Azure Automation Account**: Central automation service with system-assigned Managed Identity
- **Weekly Schedules**: Configurable start/stop schedules (default: weekdays 8 AM-8 PM Asia/Colombo)
- **Automation Variables**: Runtime configuration with boolean flags for different resource types

### Resource Types Managed

- Virtual Machines (VMs) - controlled by `start_stop_vm` variable
- Virtual Machine Scale Sets (VMSS) - controlled by `start_stop_vmss` variable  
- Azure Firewalls - controlled by `start_stop_firewall` variable
- Azure Kubernetes Service (AKS) clusters - controlled by `start_stop_aks` variable
- Application Gateways - controlled by `start_stop_app_gateway` variable
- SQL Database Auto-pause - controlled by `enable_disable_db_auto_pause` variable

## Repository Structure

```txt
├── terraform/
│   ├── main.tf                     # Main Terraform configuration using WSO2 modules
│   ├── variables.tf                # Variable definitions
│   ├── locals.tf                   # Local value definitions
│   ├── versions.tf                 # Provider version constraints
│   ├── conf.auto.tfvars            # Auto-loaded configuration variables
│   ├── secrets.auto.tfvars         # Auto-loaded sensitive variables
│   ├── conf.auto.tfvars.example    # Example configuration file
│   ├── secrets.auto.tfvars.example # Example secrets file
│   └── README.md                   # Terraform-specific documentation
├── scripts/
│   ├── Start-Environment.ps1       # PowerShell script to start resources
│   └── Stop-Environment.ps1        # PowerShell script to stop resources
├── .github/
│   └── copilot-instructions.md     # This file - GitHub Copilot instructions
├── docs/
│   └── deployment-guide.md         # Step-by-step deployment guide
└── README.md                       # Main project documentation
```

## Development Guidelines

### When Working on Terraform Code

- Use consistent naming conventions: `{project}-{component}-{environment}` (e.g., `envautomation-env-start-stop-dev`)
- Always include appropriate tags using the `local.tags` configuration
- Use external WSO2 Azure Terraform modules for reliability and best practices
- Configuration stored in `.auto.tfvars` files (auto-loaded by Terraform)
- Validate configurations with `terraform validate` and `terraform plan`
- Follow Azure naming conventions and module requirements

### When Working on PowerShell Scripts

- Use PowerShell best practices and proper error handling
- Include comprehensive logging for troubleshooting
- Use Azure PowerShell modules (Az.*)
- Implement retry logic for API calls
- Add parameter validation and help documentation

### Resource Management

- Target resources using Azure tags (Environment, AutoStart, AutoStop)
- Implement safeguards to prevent accidental production resource modification
- Include dry-run capabilities for testing
- Log all actions for audit purposes

### Environment Configuration

- Use JSON configuration files for environment-specific settings
- Support multiple Azure subscriptions and resource groups
- Allow customizable schedules per environment
- Enable/disable automation per resource type

## Key Features Implemented

### Cost Optimization

- Automated resource shutdown during non-business hours (weekdays 8 PM - 8 AM)
- Configurable resource type automation via boolean variables
- Weekend resource shutdown (Saturday and Sunday)
- Different environments can have different automation accounts

### Monitoring & Alerting

- Azure Automation job logging and status tracking
- Audit trail through Azure Activity Log
- Job execution history available via Azure CLI/Portal
- Automation variable configuration for runtime control

### Security & Compliance

- System-assigned Managed Identity for secure authentication
- Role-based access control (RBAC) for resource access
- No hardcoded credentials in scripts or configuration
- Infrastructure as Code for consistent deployments

## Common Tasks & Commands

### Terraform Operations

```bash
# Initialize Terraform
terraform init

# Plan deployment (uses .auto.tfvars files automatically)
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Plan with detailed output for validation
terraform plan -detailed-exitcode
```

## Configuration Examples

### Terraform Configuration Example (conf.auto.tfvars)

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

### Schedule Configuration

The current implementation uses weekly schedules configured in Terraform:

- **Start Schedule**: Weekdays at 8:00 AM Asia/Colombo timezone
- **Stop Schedule**: Weekdays at 8:00 PM Asia/Colombo timezone
- **Days**: Monday through Friday
- **Configurable via**: Terraform module parameters in main.tf

## Testing & Validation

### Pre-deployment Checks

- Validate Terraform syntax and configuration
- Test PowerShell scripts with -WhatIf parameter
- Verify Azure permissions and access
- Check resource tagging compliance

### Post-deployment Verification

- Confirm automation account creation
- Verify runbook import and compilation
- Test schedule execution
- Monitor first automated start/stop cycle

## Troubleshooting Guidelines

### Common Issues

1. **Permission Errors**: Verify Managed Identity has required RBAC roles
2. **Resource Not Found**: Check resource tags and naming conventions
3. **Schedule Not Running**: Verify time zones and cron expressions
4. **Script Failures**: Check Azure PowerShell module versions

### Debugging Steps

1. Check Azure Automation job logs
2. Verify resource tags and configurations
3. Test scripts manually with verbose logging
4. Review Azure Activity Log for API calls

## Best Practices

- Always test in development environment first
- Use infrastructure as code for all deployments
- Implement proper monitoring and alerting
- Document any customizations or exceptions
- Regular review of cost savings and effectiveness
- Keep PowerShell modules and Terraform providers updated

## Contributing

When contributing to this project:

1. Follow the established coding standards
2. Add appropriate tests for new functionality
3. Update documentation for any changes
4. Test thoroughly in non-production environments
5. Include cost impact analysis for changes
