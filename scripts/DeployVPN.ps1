#Requires -RunAsAdministrator
#Requires -Modules AzureRM.Network
#Requires -Modules AzureRM.profile

# This script deploys a Azure Virtual Network, subnet and VPN gateway
# Use this script when connectivity from onpremises to Azure VNET is using point-to-site VPN connection
Param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionName,
    
    # Under this resource group common resources like VPN gateway, Virtual network will be deployed.
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    # The name of Azure VNet resource.
    [Parameter(Mandatory=$true)]
    [string]$VNetName,
  
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    # The name of the Azure VNet Gateway resource.
    [Parameter(Mandatory=$true)]
    [string]$VNetGatewayName,
    
    [Parameter(Mandatory=$false)]
    [string]$AddressPrefix = "10.254.0.0/16",
    
    [Parameter(Mandatory=$false)]
    [string]$GatewaySubnetPrefix = "10.254.1.0/24",
    
    [Parameter(Mandatory=$false)]
    [string]$OnpremiseVPNClientSubnetPrefix = "192.168.200.0/24",
    
    [Parameter(Mandatory=$false)]
    [string]$RootCertificateName = "VPN-RootCert-$($VNetName)",
    
    [Parameter(Mandatory=$false)]
    [string]$ChildCertificateName = "VPN-ChildCert-$($VNetName)"
)

# Import the common functions
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath
Import-Module (Join-Path $scriptDir Common.psm1) -Force

# Select subscription
Select-AzureRmSubscription -SubscriptionName $SubscriptionName
$subscription = Get-AzureRmSubscription -SubscriptionName $SubscriptionName
$SubscriptionId = $subscription.Subscription.SubscriptionId

# Create the resource group if needed
New-ResourceGroupIfNotExists $ResourceGroupName -Location $Location

# Deploy VNET, Gateway Subnet and VPN gateway
$templateParamsVpnGateway = @{
    gatewayName=$VNetGatewayName
    virtualNetworkName=$VNetName
    edwAzureVNetAddressPrefix=$AddressPrefix
    vpnGatewaySubnetPrefix=$GatewaySubnetPrefix
}

Write-Host -ForegroundColor Yellow "VPN Gateway deployment could take upto 45 minutes"

$templateFilePath = Join-Path (Join-Path (Split-Path -Parent $scriptDir) 'armTemplates') 'vpn-gateway.json'
$vpnGwDeployment = New-AzureRmResourceGroupDeployment -Name VpnGateway `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile $templateFilePath `
    -TemplateParameterObject $templateParamsVpnGateway `
    -Verbose

Write-Host "Generating certificates for VPN gateway"

# Generate a self signed root certificate
$vpnRootCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
    -Subject "CN=$($RootCertificateName)" -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

# Add the self signed root certificate to the trusted root certificates store
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
    [System.Security.Cryptography.X509Certificates.StoreName]::Root,
    "currentuser"
)
$store.open("MaxAllowed") 
$store.add($vpnRootCert) 
$store.close()

# Generate a client certificate
New-SelfSignedCertificate -Type Custom -KeySpec Signature `
    -Subject "CN=$($ChildCertificateName)" -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -Signer $vpnRootCert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

# Get root certificate public key data to be used by VPN gateway
$certBase64 = [system.convert]::ToBase64String($vpnRootCert.RawData)
$rootCert = New-AzureRmVpnClientRootCertificate -Name $RootCertificateName -PublicCertData $certBase64

$gateway = Get-AzureRmVirtualNetworkGateway -Name $VNetGatewayName -ResourceGroupName $ResourceGroupName

Write-Host "Updating VPN gateway with certificates"

Set-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $gateway `
    -VpnClientAddressPool $OnpremiseVPNClientSubnetPrefix `
    -VpnClientRootCertificates $rootCert
