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

locals {
  tags = {
    project     = var.project
    environment = var.environment
    terraform   = "true"
  }
}
