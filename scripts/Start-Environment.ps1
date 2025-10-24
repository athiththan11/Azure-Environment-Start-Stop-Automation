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
    $FirewallName      = Get-AutomationVariable -Name "av-firewall-name"
    $VNetName          = Get-AutomationVariable -Name "av-vnet-name"
    $FirewallPublicIps = Get-AutomationVariable -Name "av-firewall-public-ips"
    $PublicIps         = $FirewallPublicIps.Split(",")
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
    $DbServerName = Get-AutomationVariable -Name "av-db-server-name"
    $DbNameList   = Get-AutomationVariable -Name "av-db-name-array"
    $DbNames      = $DbNameList.Split(",")
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
Starts the Azure Firewall.

.DESCRIPTION
This function starts the Azure Firewall by allocating the firewall to the virtual network and public IPs.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Start-AzFirewall
#>
function Start-AzFirewall {
    Write-OutputLog "Starting Azure Firewall: $FirewallName"
    $Firewall = Get-AzFirewall -Name $FirewallName -ResourceGroupName $ResourceGroupName
    $VNet     = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName

    $PublicIpArray = @()
    foreach ($PIP in $PublicIps) {
        $PublicIp       = Get-AzPublicIpAddress -Name $PIP -ResourceGroupName $ResourceGroupName
        $PublicIpArray += $PublicIp
    }

    $Firewall.Allocate($VNet, $PublicIpArray)
    $Firewall | Set-AzFirewall
}

<#
.SYNOPSIS
Gets the Azure Firewall status.

.DESCRIPTION
This function gets the Azure Firewall status by checking if the firewall has been allocated successfully.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Get-AzFirewallStatus
#>
function Get-AzFirewallStatus {
    Write-OutputLog "Checking Firewall allocation status."
    $RetryCount = 0

    do {
        $Firewall = Get-AzFirewall -Name $FirewallName -ResourceGroupName $ResourceGroupName
        
        Write-OutputLog "Sleep for 5 seconds before the next status check."
        Start-Sleep -s 5

        $RetryCount++
    } until (($Firewall.IpConfigurations.count -eq $PublicIps.count) -or ($RetryCount -gt 24))

    if ($Firewall.IpConfigurations.count -eq $PublicIps.count) {
        Write-OutputLog "Firewall has been allocated successfully."
    }
    
    if ($RetryCount -gt 24) {
        Write-ErrorLog "Firewall allocation failed. Exiting..."
        Exit
    }
}

#endregion AzFirewall
#region AzAks

<#
.SYNOPSIS
Starts the AKS cluster.

.DESCRIPTION
This function starts the AKS cluster.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Start-AzAks
#>
function Start-AzAks {
    Write-OutputLog "Starting AKS cluster: $AksClusterName"
    Start-AzAksCluster -Name $AksClusterName -ResourceGroupName $ResourceGroupName
}

<#
.SYNOPSIS
Gets the AKS status.

.DESCRIPTION
This function gets the AKS status by checking if the AKS cluster has been provisioned successfully.

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
        Write-ErrorLog "Starting AKS failed. Please check the AKS status manually. Exiting..."
        Exit
    }
}

#endregion AzAks
#region AzAppGateway

<#
.SYNOPSIS
Starts the Azure Application Gateway.

.DESCRIPTION
This function starts the Azure Application Gateway.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Start-AzAppGateway
#>
function Start-AzAppGateway {
    Write-OutputLog "Starting Azure Application Gateway: $AppGwName"
    $AppGw = Get-AzApplicationGateway -Name $AppGwName -ResourceGroupName $ResourceGroupName
    Start-AzApplicationGateway -ApplicationGateway $AppGw
}

<#
.SYNOPSIS
Gets the Azure Application Gateway status.

.DESCRIPTION
This function gets the Azure Application Gateway status by checking if the application gateway has been provisioned successfully.

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
        Write-ErrorLog "Starting Application Gateway failed. Please check the Application Gateway status manually. Exiting..."
        Exit
    }
}

#endregion AzAppGateway
#region DbAutoPause

<#
.SYNOPSIS
Disables auto-pause for the database.

.DESCRIPTION
This function disables auto-pause for the database.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Disable-DbAutoPause
#>
function Disable-DbAutoPause {
    Write-OutputLog "Disabling auto-pause for the database."
    foreach ($Db in $DbNames) {
        Write-OutputLog "Disabling auto-pause for the database: $Db"
        Set-AzSqlDatabase -DatabaseName $Db -ServerName $DbServerName -ResourceGroupName $ResourceGroupName -AutoPauseDelayInMinutes -1
    }
}

<#
.SYNOPSIS
Gets the auto-pause status for the database.

.DESCRIPTION
This function gets the auto-pause status for the database.

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
        Write-OutputLog "Auto-pause status for the database $Db : $CurrentStatus"
        Write-OutputLog ""

        if ($CurrentStatus -ne -1) {
            Write-ErrorLog "Auto-pause is not disabled for the database $Db. Exiting..."
            Exit
        }
    }
}

#endregion DbAutoPause
#region AzVirtualMachine

<#
.SYNOPSIS
Starts the Azure Virtual Machine.

.DESCRIPTION
This function starts the Azure Virtual Machine.

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Start-AzVirtualMachine
#>
function Start-AzVirtualMachine {
    Write-OutputLog "Starting Azure Virtual Machine(s)."
    foreach ($Vm in $VmNames) {
        Write-OutputLog "Starting Azure Virtual Machine: $Vm"
        Start-AzVM -Name $Vm -ResourceGroupName $ResourceGroupName
    }
}

#endregion AzVirtualMachine
#region AzVmss

<#
.SYNOPSIS
Starts the Azure Virtual Machine Scale Sets (VMSS).

.DESCRIPTION
This function starts the Azure Virtual Machine Scale Sets (VMSS).

.PARAMETER None

.INPUTS
None

.OUTPUTS
None

.EXAMPLE
Start-AzVirtualMachineScaleSet
#>
function Start-AzVirtualMachineScaleSet {
    Write-OutputLog "Starting Azure Virtual Machine Scale Sets (VMSS)."
    foreach ($Vmss in $VmssNames) {
        Write-OutputLog "Starting Azure Virtual Machine Scale Set: $Vmss"
        Start-AzVmss -ResourceGroupName $ResourceGroupName -VMScaleSetName $Vmss -Force
    }
}

#endregion AzVmss

Connect-ToAzure
if ($StartStopFirewall) {
    Start-AzFirewall
    Get-AzFirewallStatus
}
if ($EnableDisableDbAutoPause) {
    Disable-DbAutoPause
    Get-DbAutoPauseStatus
}
if ($StartStopAppGateway) {
    Start-AzAppGateway
    Get-AzAppGatewayStatus
}
if ($StartStopAks) {
    if ($DisableDbAutoPause) {
        Write-OutputLog "Sleep for 30 seconds before starting AKS cluster after disabling auto-pause."
        Start-Sleep -s 30
    }

    Start-AzAks
    Get-AzAksStatus
}
if ($StartStopVmss) {
    Start-AzVirtualMachineScaleSet
}
if ($StartStopVm) {
    Start-AzVirtualMachine
}
