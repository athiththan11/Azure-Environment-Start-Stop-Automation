# -------------------------------------------------------------------------
# 
# Copyright (c) 2025 Athiththan Kathirgamasegaran
# Licensed under the MIT License. See LICENSE file in the project root for
# full license information.
#
# Azure Environment Start & Stop Automation
# Terraform configuration for automated environment management
# 
# -------------------------------------------------------------------------

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {}
}

# Resource Group for Automation Account
module "automation-account-resource-group" {
  source              = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Resource-Group?ref=v0.46.0"
  resource_group_name = join("-", [var.project, "automation", var.environment, var.location, var.padding])
  location            = var.location
  tags                = local.tags
}

# Automation Account for Environment Start & Stop
module "automation-account-environment-start-stop" {
  source                  = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Account-Managed-Identity?ref=v0.46.0"
  automation_account_name = join("-", [var.project, "env-start-stop", var.environment])
  resource_group_name     = module.automation-account-resource-group.resource_group_name
  location                = var.location
  tags                    = local.tags
}

# Automation Runbooks for Environment Start & Stop
module "automation-runbook-environment-start" {
  source                  = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Runbook?ref=v0.46.0"
  automation_runbook_name = join("-", [var.project, var.environment, "env-start"])
  resource_group_name     = module.automation-account-resource-group.resource_group_name
  location                = var.location
  automation_account_name = module.automation-account-environment-start-stop.automation_account_name
  # This is a dummy URL. Adding this link is a bug. Please refer https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook
  uri      = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  filepath = "${path.module}/../scripts/Start-Environment.ps1"
  tags     = local.tags
}

module "automation-runbook-environment-stop" {
  source                  = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Runbook?ref=v0.46.0"
  automation_runbook_name = join("-", [var.project, var.environment, "env-stop"])
  resource_group_name     = module.automation-account-resource-group.resource_group_name
  location                = var.location
  automation_account_name = module.automation-account-environment-start-stop.automation_account_name
  # This is a dummy URL. Adding this link is a bug. Please refer https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook
  uri      = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/c4935ffb69246a6058eb24f54640f53f69d3ac9f/101-automation-runbook-getvms/Runbooks/Get-AzureVMTutorial.ps1"
  filepath = "${path.module}/../scripts/Start-Environment.ps1"
  tags     = local.tags
}

## Automation Schedule and Job Schedule for Environment Start & Stop
module "automation-runbook-environment-start-schedule" {
  source                                 = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Weekly-Schedule?ref=v0.46.0"
  automation_weekly_schedule_name        = "env-start-schedule"
  resource_group_name                    = module.automation-account-resource-group.resource_group_name
  automation_account_name                = module.automation-account-environment-start-stop.automation_account_name
  automation_weekly_schedule_week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  automation_weekly_schedule_intervel    = "1"
  automation_weekly_schedule_timezone    = "Asia/Colombo"
  automation_weekly_schedule_start_time  = "2025-10-25T08:00:00+05:30"
  automation_weekly_schedule_description = "Environment start schedule"
}

module "automation-runbook-environment-start-job-schedule" {
  source                        = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Job-Schedule?ref=v0.46.0"
  automation_schedule_name      = module.automation-runbook-environment-start-schedule.automation_weekly_schedule_name
  resource_group_name           = module.automation-account-resource-group.resource_group_name
  automation_account_name       = module.automation-account-environment-start-stop.automation_account_name
  automation_runbook_name       = module.automation-runbook-environment-start.automation_runbook_name
  worker_group_run_on           = null
  automation_runbook_parameters = {}
}

module "automation-runbook-environment-stop-schedule" {
  source                                 = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Weekly-Schedule?ref=v0.46.0"
  automation_weekly_schedule_name        = "env-stop-schedule"
  resource_group_name                    = module.automation-account-resource-group.resource_group_name
  automation_account_name                = module.automation-account-environment-start-stop.automation_account_name
  automation_weekly_schedule_week_days   = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  automation_weekly_schedule_intervel    = "1"
  automation_weekly_schedule_timezone    = "Asia/Colombo"
  automation_weekly_schedule_start_time  = "2025-10-24T20:00:00+05:30"
  automation_weekly_schedule_description = "Environment stop schedule"
}

module "automation-runbook-environment-stop-job-schedule" {
  source                        = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Job-Schedule?ref=v0.46.0"
  automation_schedule_name      = module.automation-runbook-environment-stop-schedule.automation_weekly_schedule_name
  resource_group_name           = module.automation-account-resource-group.resource_group_name
  automation_account_name       = module.automation-account-environment-start-stop.automation_account_name
  automation_runbook_name       = module.automation-runbook-environment-stop.automation_runbook_name
  worker_group_run_on           = null
  automation_runbook_parameters = {}
}

# Automation Account variables
module "automation-account-environment-start-stop-variables" {
  source                  = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Variable-String?ref=v2.11.1"
  automation_account_name = module.automation-account-environment-start-stop.automation_account_name
  resource_group_name     = module.automation-account-resource-group.resource_group_name
  automation_variables = {
    "runbook-resource-group-name" = {
      variable_name  = "runbook-resource-group-name"
      variable_value = module.automation-account-resource-group.resource_group_name
    },
    "automation-account-name" = {
      variable_name  = "automation-account-name"
      variable_value = module.automation-account-environment-start-stop.automation_account_name
    },
    "auto-pause-disable-delay" = {
      variable_name  = "auto-pause-disable-delay"
      variable_value = "-1"
    },
    "auto-pause-enable-delay" = {
      variable_name  = "auto-pause-enable-delay"
      variable_value = "60"
    },

    # The following variables are commented out for future use
    # Uncomment and set values as needed
    # "resource-group-name" = {
    #   variable_name  = "resource-group-name"
    #   variable_value = var.resource_group_name
    # },
    # "db-server-name" = {
    #   variable_name  = "db-server-name"
    #   variable_value = var.db_server_name
    # },
    # "db-name-array" = {
    #   variable_name  = "db-name-array"
    #   variable_value = join(",", [var.database_name_01, var.database_name_02])
    # },
    # "app-gateway-name" = {
    #   variable_name  = "app-gateway-name"
    #   variable_value = var.application_gateway_name
    # },
    # "vm-name-array" = {
    #   variable_name = "vm-name-array"
    #   variable_value = join(",", var.virtual_machine_name_01, var.virtual_machine_name_02)
    # },
    # "firewall-public-ips" = {
    #   variable_name  = "firewall-public-ips"
    #   variable_value = join(",", var.firewall_public_ip_address_01, var.firewall_public_ip_address_02)
    # },
    # "vmss-name-array" = {
    #   variable_name  = "vmss-name-array"
    #   variable_value = join(",", [var.virtual_machine_scale_set_name_01, var.virtual_machine_scale_set_name_02])
    # }
    # "vnet-name" = {
    #   variable_name  = "vnet-name"
    #   variable_value = var.virtual_network_name
    # },
    # "firewall-name" = {
    #   variable_name  = "firewall-name"
    #   variable_value = var.firewall_name
    # },
    # "aks-cluster-name" = {
    #   variable_name  = "aks-cluster-name"
    #   variable_value = var.aks_cluster_name
    # }
  }
}

module "automation-account-environment-start-stop-boolean-variables" {
  source                  = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Automation-Variable-Boolean?ref=v0.46.0"
  resource_group_name     = module.automation-account-resource-group.resource_group_name
  automation_account_name = module.automation-account-environment-start-stop.automation_account_name
  automation_variables = {
    "start-stop-vm" = {
      variable_name  = "start-stop-vm"
      variable_value = var.start_stop_vm
    },
    "start-stop-vmss" = {
      variable_name  = "start-stop-vmss"
      variable_value = var.start_stop_vmss
    },
    "start-stop-firewall" = {
      variable_name  = "start-stop-firewall"
      variable_value = var.start_stop_firewall
    },
    "start-stop-aks" = {
      variable_name  = "start-stop-aks"
      variable_value = var.start_stop_aks
    },
    "start-stop-app-gateway" = {
      variable_name  = "start-stop-app-gateway"
      variable_value = var.start_stop_app_gateway
    },
    "enable-disable-db-auto-pause" = {
      variable_name  = "enable-disable-db-auto-pause"
      variable_value = var.enable_disable_db_auto_pause
    }
  }
}

# Automation Account Role Assignments
# Uncomment and set resource IDs as needed
# module "automation-account-environment-start-stop-firewall-contributor-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v2.1.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.firewall_id
# }

# module "automation-account-environment-start-stop-firewall-public-ip-01-reader-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v2.1.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.firewall_public_ip_address_01_id
#   role_definition_name = "Reader"
# }

# module "automation-account-environment-start-stop-aks-contributor-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v2.1.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.aks_cluster_id
#   role_definition_name = "Contributor"
# }

# module "automation-account-environment-start-stop-mssql-server-contributor-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v2.1.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.mssql_server_id
#   role_definition_name = "Contributor"
# }

# module "automation-account-environment-start-stop-vnet-reader-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v2.1.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.virtual_network_id
#   role_definition_name = "Reader"
# }

# module "automation-account-environment-start-stop-virtual-machine-01-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v2.1.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.virtual_machine_01_id
#   role_definition_name = "Contributor"
# }

# module "automation-account-environment-start-stop-virtual-machine-scale-set-01-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v2.1.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.virtual_machine_scale_set_name_01_id
#   role_definition_name = "Contributor"
# }

# module "automation-account-environment-start-stop-application-gateway-contributor-rbac" {
#   source               = "git::https://github.com/wso2/azure-terraform-modules.git//modules/azurerm/Role-Assignment?ref=v0.46.0"
#   principal_id         = module.automation-account-environment-start-stop.automation_account_managed_identity_id
#   resource_id          = var.application_gateway_id
#   role_definition_name = "Contributor"
# }
