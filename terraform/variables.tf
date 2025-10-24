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

variable "subscription_id" {
  description = "The Azure Subscription ID."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "The Azure Tenant ID."
  type        = string
  sensitive   = true
}

variable "project" {
  description = "The name of the project."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, qa, stage, prod)."
  type        = string
}

variable "location" {
  description = "The Azure region for resource deployment."
  type        = string
  default     = "eastus2"
}

variable "padding" {
  description = "Padding value for resource naming to ensure uniqueness."
  type        = string
  default     = "001"
}

variable "start_stop_vm" {
  description = "Flag to enable or disable VM start/stop automation."
  type        = bool
  default     = true
}

variable "start_stop_vmss" {
  description = "Flag to enable or disable VMSS start/stop automation."
  type        = bool
  default     = true
}

variable "start_stop_firewall" {
  description = "Flag to enable or disable Firewall start/stop automation."
  type        = bool
  default     = true
}

variable "start_stop_aks" {
  description = "Flag to enable or disable AKS start/stop automation."
  type        = bool
  default     = true
}

variable "start_stop_app_gateway" {
  description = "Flag to enable or disable Application Gateway start/stop automation."
  type        = bool
  default     = true
}

variable "enable_disable_db_auto_pause" {
  description = "Flag to enable or disable database auto-pause automation."
  type        = bool
  default     = true
}

# Uncomment to use variable
# variable "resource_group_name" {
#   description = "The name of the resource group to manage."
#   type        = string
# }

# variable "db_server_name" {
#   description = "The name of the database server for auto-pause management."
#   type        = string
# }

# variable "database_name_01" {
#   description = "The name of the first database to manage auto-pause."
#   type        = string
# }

# variable "database_name_02" {
#   description = "The name of the second database to manage auto-pause."
#   type        = string
# }

# variable "application_gateway_name" {
#   description = "The name of the Application Gateway to manage."
#   type        = string
# }

# variable "virtual_machine_name_01" {
#   description = "The name of the first virtual machine to manage."
#   type        = string
# }

# variable "virtual_machine_name_02" {
#   description = "The name of the second virtual machine to manage."
#   type        = string
# }

# variable "firewall_public_ip_address_01" {
#   description = "The name of the first Firewall public IP address to manage."
#   type        = string
# }

# variable "firewall_public_ip_address_02" {
#   description = "The name of the second Firewall public IP address to manage."
#   type        = string
# }

# variable "virtual_machine_scale_set_name_01" {
#   description = "The name of the first virtual machine scale set to manage."
#   type        = string
# }

# variable "virtual_machine_scale_set_name_02" {
#   description = "The name of the second virtual machine scale set to manage."
#   type        = string
# }

# variable "virtual_network_name" {
#   description = "The name of the virtual network."
#   type        = string
# }

# variable "firewall_name" {
#   description = "The name of the Firewall to manage."
#   type        = string
# }

# variable "aks_cluster_name" {
#   description = "The name of the AKS cluster to manage."
#   type        = string
# }

# variable "firewall_id" {
#   description = "The ID of the Firewall to manage."
#   type        = string
# }

# variable "firewall_public_ip_address_01_id" {
#   description = "The ID of the first Firewall public IP address to manage."
#   type        = string
# }

# variable "aks_cluster_id" {
#   description = "The ID of the AKS cluster to manage."
#   type        = string
# }

# variable "mssql_server_id" {
#   description = "The ID of the MSSQL server for auto-pause management."
#   type        = string
# }

# variable "virtual_network_id" {
#   description = "The ID of the virtual network."
#   type        = string
# }

# variable "virtual_machine_01_id" {
#   description = "The ID of the first virtual machine to manage."
#   type        = string
# }

# variable "virtual_machine_scale_set_name_01_id" {
#   description = "The ID of the first virtual machine scale set to manage."
#   type        = string
# }

# variable "application_gateway_id" {
#   description = "The ID of the Application Gateway to manage."
#   type        = string
# }
