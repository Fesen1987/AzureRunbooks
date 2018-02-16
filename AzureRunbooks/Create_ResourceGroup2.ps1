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
New-AzureRmResourceGroup -Name $ResourceGroupName -Location "West Europe" -Tag @{Name="Owner";Value=$TagOwner}

# Adding designated Tags
$r = Get-AzureRmResourceGroup -Name $ResourceGroupName
$r.tags += @{Name="CostCenter";Value=$TagCostCenter}
$r.tags += @{Name="Originator";Value="$TagOriginator"}
Set-AzureRmResourceGroup -Name $ResourceGroupName -Tag $r.tags

#Finding ADGroups and Azure Roles to assign 
$ContributorGroup = Get-AzureADGroup -SearchString $Contributors  | Where-Object {$_.SecurityEnabled -eq $true}
$ContributorRole = Get-AzureRmRoleDefinition Contributor | Select-Object Name, Description, IsCustom, Id
$NetworkContributorGroup = Get-AzureADGroup -SearchString $NetworkContributors | Where-Object {$_.SecurityEnabled -eq $true}
$NetworkContributorRole = Get-AzureRmRoleDefinition "Network Contributor" | Select-Object Name, Description, IsCustom, Id

Write-Output $ContributorGroup 
Write-Output $ContributorRole

#Assigning the Roles to ADGroups
New-AzureRmRoleAssignment -ObjectId $ContributorGroup.ObjectId -Scope "/subscriptions/dd91e39a-4a1b-4920-a56a-2da4dd382b11/resourcegroups/$ResourceGroupName" -RoleDefinitionId $ContributorRole.Id
#New-AzureRmRoleAssignment -ObjectId '9bb39332-6465-4133-82f6-e84dd217e84b' -Scope "/subscriptions/dd91e39a-4a1b-4920-a56a-2da4dd382b11/resourcegroups/BasicServices01-Exchange01" -RoleDefinitionId 'b24988ac-6180-42a0-ab88-20f7382dd24c'
