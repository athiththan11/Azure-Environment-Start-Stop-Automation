# Deployment Guide

This guide walks through deploying the Azure Environment Start & Stop Automation solution.

## Prerequisites

### Required Tools

- Azure CLI 2.30.0 or later
- Terraform 1.0 or later  
- Git

### Azure Requirements

- Azure subscription with appropriate permissions
- Resource Group creation permissions
- Azure Automation Account creation permissions
- Managed Identity assignment permissions

## Step 1: Azure Authentication

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set target subscription
az account set --subscription "your-subscription-id"

# Verify current subscription
az account show
```

## Step 2: Configure Environment Variables

Create environment-specific variable files:

```bash
# Copy example files
cp terraform/conf.auto.tfvars.example terraform/conf.auto.tfvars
cp terraform/secrets.auto.tfvars.example terraform/secrets.auto.tfvars
```

Edit each file with your environment-specific values.

## Step 4: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```
