#Defining the Parameters to be provided by user
param (
    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]
    $TagOwner,

    [Parameter(Mandatory=$true)]
    [string]
    $TagCostCenter,

    [Parameter(Mandatory=$true)]
    [string]
    $TagOriginator
)

# Authenticate to Azure if running from Azure Automation
$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

# Creating resource group initially
New-AzureRmResourceGroup -Name $ResourceGroupName -Location "West Europe" -Tag @{Name="Owner";Value=$TagOwner}

# Adding designated Tags
$r = Get-AzureRmResourceGroup -Name $ResourceGroupName
$r.tags += @{Name="CostCenter";Value=$TagCostCenter}
$r.tags += @{Name="Originator";Value="$TagOriginator"}
Set-AzureRmResourceGroup -Name $ResourceGroupName -Tag $r.tags