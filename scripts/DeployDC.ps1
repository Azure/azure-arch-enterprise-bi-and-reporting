#Requires -RunAsAdministrator
#Requires -Modules AzureRM.Network
#Requires -Modules AzureRM.profile

# This script deploys a Domain Controller on an existing VNET resource group and assigns the DNS address of VNET to the DC IP address

Param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionName,

    [Parameter(Mandatory=$true)]
    [string]$DnsVmName,

    [Parameter(Mandatory=$true)]
    [string]$Location,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$VNetName,

    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Domain name to create.")]
    [string]$DomainName,

    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Domain admin user name.")]
    [string]$DomainUserName,

    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Domain admin user password.")]
    [securestring]$DomainUserPassword
)

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath
Import-Module (Join-Path $scriptDir CommonNetworking.psm1) -Force

# Name of the subnet in which Domain Controller will be present
$SubnetName = "DCSubnet"

# Select subscription
Select-AzureRmSubscription -SubscriptionName $SubscriptionName
$subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName
$SubscriptionId = $subscription.Subscription.SubscriptionId

# Create a subnet for DC deployment
$virtualNetwork = Get-VirtualNetworkOrExit -ResourceGroupName $ResourceGroupName -VirtualNetworkName $VNetName
$subnetAddressPrefix = Get-AvailableSubnetOrExit -VirtualNetwork $virtualNetwork -SubnetName $SubnetName

$templateParameters = @{
    adminUsername=$DomainUserName
    adminPassword=$DomainUserPassword
    domainName=$DomainName
    existingVirtualNetworkName=$VNetName
    existingVirtualNetworkAddressRange=$virtualNetwork.AddressSpace.AddressPrefixes[0]
    dcSubnetName=$SubnetName
    existingSubnetAddressRange=$subnetAddressPrefix
    dcVmName=$DnsVmName
}

$templateFilePath = Join-Path (Join-Path (Split-Path -Parent $scriptDir) 'armTemplates') 'dc-deploy.json'
$out = New-AzureRmResourceGroupDeployment -Name DeployDC `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $templateFilePath `
    -TemplateParameterObject $templateParameters

# Update the DNS server address for VNET
$virtualNetwork.DhcpOptions.DnsServers = $out.Outputs.dcIp.Value
Set-AzureRmVirtualNetwork -VirtualNetwork $virtualNetwork