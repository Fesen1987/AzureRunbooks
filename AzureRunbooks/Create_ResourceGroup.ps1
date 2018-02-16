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
    $TagOriginator,

    [Parameter(Mandatory=$false)]
    [string]
    $Contributors,
    
    [Parameter(Mandatory=$false)]
    [string]
    $NetworkContributors
)

#Get connection
$ServicePrincipalConnection = Get-AutomationConnection -Name "AzureRunAsConnection"

# Authenticate to Azure
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Write-Verbose

# Authenticate to AzureAD
Connect-AzureAD `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 

# Creating resource group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location "West Europe"

# Adding designated Tags
Set-AzureRmResourceGroup -Name $ResourceGroupName -Tag @{ Owner="$TagOwner"; CostCenter="$TagCostCenter"; Originator="$TagOriginator" }

#Finding ADGroups and Azure Roles to assign 
$ContributorGroup = Get-AzureADGroup -SearchString $Contributors  | Where-Object {$_.SecurityEnabled -eq $true}
$ContributorRole = Get-AzureRmRoleDefinition Contributor | Select-Object Name, Description, IsCustom, Id
$NetworkContributorGroup = Get-AzureADGroup -SearchString $NetworkContributors | Where-Object {$_.SecurityEnabled -eq $true}
$NetworkContributorRole = Get-AzureRmRoleDefinition "Network Contributor" | Select-Object Name, Description, IsCustom, Id

#Assigning the Roles to ADGroups
New-AzureRmRoleAssignment -ObjectId $ContributorGroup.ObjectId -Scope "/subscriptions/dd91e39a-4a1b-4920-a56a-2da4dd382b11/resourcegroups/$ResourceGroupName" -RoleDefinitionId $ContributorRole.Id
New-AzureRmRoleAssignment -ObjectId $NetworkContributorGroup.ObjectId -Scope "/subscriptions/dd91e39a-4a1b-4920-a56a-2da4dd382b11/resourcegroups/$ResourceGroupName" -RoleDefinitionId $NetworkContributorRole.Id