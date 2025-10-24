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

#region Variables

$AutomationAccountName    = Get-AutomationVariable -Name "av-automation-account-name"
$RunbookResourceGroupName = Get-AutomationVariable -Name "av-runbook-resource-group-name"
$ResourceGroupName        = Get-AutomationVariable -Name "av-resource-group-name"

$StartStopFirewall = Get-AutomationVariable -Name "av-start-stop-firewall"
if ($null -eq $StartStopFirewall) {
    $StartStopFirewall = $false
}

if ($StartStopFirewall) {
    $FirewallName = Get-AutomationVariable -Name "av-firewall-name"
}

$StartStopAks = Get-AutomationVariable -Name "av-start-stop-aks"
if ($null -eq $StartStopAks) {
    $StartStopAks = $false
}

if ($StartStopAks) {
    $AksClusterName = Get-AutomationVariable -Name "av-aks-cluster-name"
}

$StartStopAppGateway = Get-AutomationVariable -Name "av-start-stop-app-gateway"
if ($null -eq $StartStopAppGateway) {
    $StartStopAppGateway = $false
}

if ($StartStopAppGateway) {
    $AppGwName = Get-AutomationVariable -Name "av-app-gateway-name"
}

$EnableDisableDbAutoPause = Get-AutomationVariable -Name "av-enable-disable-db-auto-pause"
if ($null -eq $EnableDisableDbAutoPause) {
    $EnableDisableDbAutoPause = $false
}

if ($EnableDisableDbAutoPause) {
    $DbServerName   = Get-AutomationVariable -Name "av-db-server-name"
    $DbNameList     = Get-AutomationVariable -Name "av-db-name-array"
    $DbNames        = $DbNameList.Split(",")
    $AutoPauseDelay = Get-AutomationVariable -Name "av-auto-pause-enable-delay"
}

$StartStopVm = Get-AutomationVariable -Name "av-start-stop-vm"
if ($null -eq $StartStopVm) {
    $StartStopVm = $false
}

if ($StartStopVm) {
    $VmNameList = Get-AutomationVariable -Name "av-vm-name-array"
    $VmNames    = $VmNameList.Split(",")
}

$StartStopVmss = Get-AutomationVariable -Name "av-start-stop-vmss"
if ($null -eq $StartStopVmss) {
    $StartStopVmss = $false
}

if ($StartStopVmss) {
    $VmssNameList = Get-AutomationVariable -Name "av-vmss-name-array"
    $VmssNames    = $VmssNameList.Split(",")
}
#endregion Variables

<#
.SYNOPSIS
Writes the output to the log.

.DESCRIPTION
This function writes the output to the log with a timestamp.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Write-OutputLog "Stopping Firewall: $FirewallName"
#>
function Write-OutputLog {
    Write-Output "$('[{0:MM/dd/yy} {0:HH:mm:ss}]' -f (Get-Date)) $args"
}

<#
.SYNOPSIS
Writes the error to the log.

.DESCRIPTION
This function writes the error to the log with a timestamp.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Write-ErrorLog "There is no system-assigned user identity. Aborting!"
#>
function Write-ErrorLog {
    Write-Error "$('[{0:MM/dd/yy} {0:HH:mm:ss}]' -f (Get-Date)) $args"
}

<#
.SYNOPSIS
Connects to Azure and checks if a runbook is already running.

.DESCRIPTION
This function connects to Azure using a Managed Service Identity and checks if a runbook is already running. 
It disables inheriting an AzContext in the runbook and sets the context to the default profile. It retrieves 
the current automation job and runbook name. Then, it retrieves all jobs for the runbook and checks if any of 
them are already running. If the runbook is already running, it throws an error and exits.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Connect-ToAzure
#>
function Connect-ToAzure {
    # Disable inheriting an AzContext in runbook.
    Disable-AzContextAutosave -Scope Process | Out-Null

    # Connect using a Managed Service Identity.
    try {
        $AzureContext = (Connect-AzAccount -Identity).context
    }
    catch {
        Write-ErrorLog "There is no system-assigned user identity. Aborting!"
        exit
    }

    # Set and store context.
    $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

    $AutomationJobId = $PSPrivateMetadata.JobId.Guid
    $AutomationJob   = Get-AzAutomationJob -ResourceGroupName $RunbookResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Id $AutomationJobId `
        -DefaultProfile $AzureContext
    $RunBookName = $AutomationJob.RunbookName

    $Jobs = Get-AzAutomationJob -ResourceGroupName $RunbookResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -RunbookName $RunBookName `
        -DefaultProfile $AzureContext

    # Check to see if it is already running
    $RunningCount = ($Jobs.Where( { $_.Status -eq "Running" })).count

    if (($Jobs.Status -contains "Running" -and $RunningCount -gt 1 ) -or ($Jobs.Status -eq "New")) {
        $ErrorActionPreference = "Stop"
        Write-ErrorLog "Runbook $RunBookName is already running."
        exit 1
    }
}

#region AzFirewall

<#
.SYNOPSIS
Stops the Azure Firewall.

.DESCRIPTION
This function stops the Azure Firewall by deallocating it.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Stop-AzFirewall
#>
function Stop-AzFirewall {
    Write-OutputLog "Stopping Firewall: $FirewallName"
    $Firewall = Get-AzFirewall -Name $FirewallName -ResourceGroupName $ResourceGroupName
    $Firewall.Deallocate();
    $Firewall | Set-AzFirewall
}

<#
.SYNOPSIS
Checks the deallocation status of the Azure Firewall.

.DESCRIPTION
This function checks the deallocation status of the Azure Firewall. It retrieves the Azure Firewall and checks
if the number of IP configurations is zero. If the number of IP configurations is zero, it means the firewall
has been deallocated successfully. If the number of IP configurations is not zero after 2 minutes, it means
the deallocation has failed.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Get-AzFirewallStatus
#>
function Get-AzFirewallStatus {
    Write-OutputLog "Checking Firewall deallocation status."
    $RetryCount = 0

    do {
        $Firewall = Get-AzFirewall -Name $FirewallName -ResourceGroupName $ResourceGroupName
        
        Write-OutputLog "Sleep for 5 seconds before the next status check."
        Start-Sleep -s 5

        $RetryCount++
    } until (($Firewall.IpConfigurations.count -eq 0) -or ($RetryCount -gt 24))

    if ($Firewall.IpConfigurations.count -eq 0) {
        Write-OutputLog "Firewall deallocated successfully."
    }

    if ($RetryCount -gt 24) {
        Write-ErrorLog "Firewall deallocation failed. Please check the firewall status manually. Exiting..."
        Exit
    }
}

#endregion AzFirewall
#region AzAks

<#
.SYNOPSIS
Stops the Azure Kubernetes Service (AKS) cluster.

.DESCRIPTION
This function stops the Azure Kubernetes Service (AKS) cluster by deallocating it.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Stop-AzAks
#>
function Stop-AzAks {
    Write-OutputLog "Stopping AKS: $AksClusterName"
    Stop-AzAksCluster -Name $AksClusterName -ResourceGroupName $ResourceGroupName
}

<#
.SYNOPSIS
Checks the deallocation status of the Azure Kubernetes Service (AKS) cluster.

.DESCRIPTION
This function checks the deallocation status of the Azure Kubernetes Service (AKS) cluster. It retrieves the AKS
cluster and checks if the provisioning state is "Succeeded". If the provisioning state is "Succeeded", it means the
AKS cluster has been deallocated successfully. If the provisioning state is not "Succeeded" after 2 minutes, it means
the deallocation has failed.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Get-AzAksStatus
#>
function Get-AzAksStatus {
    $RetryCount = 0

    do {
        $Aks       = Get-AzAksCluster -Name $AksClusterName -ResourceGroupName $ResourceGroupName
        $AksStatus = $Aks.ProvisioningState

        Write-OutputLog "Checking AKS status..."
        Write-OutputLog "AKS Status: $AksStatus"

        Write-OutputLog "Sleep for 5 seconds before the next status check."
        Write-OutputLog ""
        Start-Sleep -s 5

        $RetryCount++
    } until (($AksStatus.ToString() -eq "Succeeded") -or ($RetryCount -gt 24))

    Write-OutputLog "AKS Status: $AksStatus"

    if ($RetryCount -gt 24) {
        Write-ErrorLog "Stopping AKS failed. Please check the AKS status manually. Exiting..."
        Exit
    }
}

#endregion AzAks
#region AzAppGateway

<#
.SYNOPSIS
Stops the Application Gateway.

.DESCRIPTION
This function stops the Application Gateway by deallocating it.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Stop-AzAppGateway
#>
function Stop-AzAppGateway {
    Write-OutputLog "Stopping Application Gateway: $AppGwName"
    $AppGw = Get-AzApplicationGateway -Name $AppGwName -ResourceGroupName $ResourceGroupName
    Stop-AzApplicationGateway -ApplicationGateway $AppGw
}

<#
.SYNOPSIS
Checks the deallocation status of the Application Gateway.

.DESCRIPTION
This function checks the deallocation status of the Application Gateway. It retrieves the Application Gateway and checks
if the provisioning state is "Succeeded". If the provisioning state is "Succeeded", it means the Application Gateway has
been deallocated successfully. If the provisioning state is not "Succeeded" after 2 minutes, it means the deallocation has
failed.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Get-AzAppGatewayStatus
#>
function Get-AzAppGatewayStatus {
    $RetryCount = 0

    do {
        $AppGw       = Get-AzApplicationGateway -Name $AppGwName -ResourceGroupName $ResourceGroupName
        $AppGwStatus = $AppGw.ProvisioningState
        Write-OutputLog "Checking Application Gateway status..."
        Write-OutputLog "Application Gateway Status: $AppGwStatus"

        Write-OutputLog "Sleep for 5 seconds before the next status check."
        Write-OutputLog ""
        Start-Sleep -s 5

        $RetryCount++
    } until (($AppGwStatus.ToString() -eq "Succeeded") -or ($RetryCount -gt 24))

    Write-OutputLog "Application Gateway Status: $AppGwStatus"

    if ($RetryCount -gt 24) {
        Write-ErrorLog "Stopping Application Gateway failed. Please check the Application Gateway status manually. Exiting..."
        Exit
    }
}

#endregion AzAppGateway
#region DbAutoPause

<#
.SYNOPSIS
Stops the Azure SQL Database.

.DESCRIPTION
This function stops the Azure SQL Database by setting the auto-pause delay in minute.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Stop-DbAutoPause
#>
function Enable-DbAutoPause {
    Write-OutputLog "Enabling auto-pause for the database."
    foreach ($Db in $DbNames) {
        Write-OutputLog "Enabling auto-pause for the database: $Db"
        Set-AzSqlDatabase -DatabaseName $Db -ServerName $DbServerName -ResourceGroupName $ResourceGroupName -AutoPauseDelayInMinutes $AutoPauseDelay
    }
}

<#
.SYNOPSIS
Checks the auto-pause delay in the databases.

.DESCRIPTION
This function checks the auto-pause delay in the databases. It retrieves the auto-pause delay in minutes for each database.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Get-DbAutoPauseStatus
#>
function Get-DbAutoPauseStatus {
    Write-OutputLog "Checking auto-pause status for the database."
    foreach ($Db in $DbNames) {
        $DbStatus      = Get-AzSqlDatabase -DatabaseName $Db -ServerName $DbServerName -ResourceGroupName $ResourceGroupName
        $CurrentStatus = $DbStatus.AutoPauseDelayInMinutes
        Write-OutputLog "Auto-pause delay in minutes for the database $Db : $CurrentStatus"
        Write-OutputLog ""
    }
}

#endregion DbAutoPause
#region AzVirtualMachine

<#
.SYNOPSIS
Stops the Azure Virtual Machine.

.DESCRIPTION
This function stops the Azure Virtual Machine by deallocating it.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Stop-AzVirtualMachine
#>
function Stop-AzVirtualMachine {
    Write-OutputLog "Stopping Azure Virtual Machine(s)."
    foreach ($Vm in $VmNames) {
        Write-OutputLog "Stopping Azure Virtual Machine: $Vm"
        Stop-AzVM -Name $Vm -ResourceGroupName $ResourceGroupName -Force
    }
}

#endregion AzVirtualMachine
#region AzVmss

<#
.SYNOPSIS
Stops the Azure Virtual Machine Scale Sets (VMSS).

.DESCRIPTION
This function stops the Azure Virtual Machine Scale Sets (VMSS) by deallocating them.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Stop-AzVirtualMachineScaleSet
#>
function Stop-AzVirtualMachineScaleSet {
    Write-OutputLog "Stopping Azure Virtual Machine Scale Sets (VMSS)."
    foreach ($Vmss in $VmssNames) {
        Write-OutputLog "Stopping Azure Virtual Machine Scale Set: $Vmss"
        Stop-AzVmss -ResourceGroupName $ResourceGroupName -VMScaleSetName $Vmss -Force
    }
}

#endregion AzVmss

Connect-ToAzure
if ($StartStopAks) {
    Stop-AzAks
    Get-AzAksStatus
}
if ($StartStopAppGateway) {
    Stop-AzAppGateway
    Get-AzAppGatewayStatus
}
if ($EnableDisableDbAutoPause) {
    Enable-DbAutoPause
    Get-DbAutoPauseStatus
}
if ($StartStopVmss) {
    Stop-AzVirtualMachineScaleSet
}
if ($StartStopFirewall) {
    Stop-AzFirewall
    Get-AzFirewallStatus
}
if ($StartStopVm) {
    Stop-AzVirtualMachine
}
