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

terraform {
  required_version = "= 1.10.3"

  # Uncomment to enable remote state storage
  # backend "azurerm" {
  # }

  required_providers {
    azurerm = "= 4.30.0"
  }
}
