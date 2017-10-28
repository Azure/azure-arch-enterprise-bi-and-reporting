# Summary
This page summarizes prerequisites for EDW Reporting TRA deployment. 

# VNET

Most of the resources provisioned will be placed in a pre-existing Azure VNET. Therefore, we require an Azure VNET resource and a domain controller to be deployed in the subscription where the EDW Reporting TRA will be deployed. Customers who already have a functioning Azure VNET can skip this section. For customers new to Azure, the guide below will show how to easily deploy prerequisites in their subscription.

## Provisioning Azure VNet resource

First, we will create new Azure VNET and VPN Gateway resources. Navigate to <source root>\edw\deployment directory and run the command below. Note that it might take up to 45 minutes to complete.

```PowerShell
Login-AzureRmAccount

.\DeployVPN.ps1 -SubscriptionName "My Subscription" -Location "westus" -EDWAddressPrefix "10.254.0.0/16" -EDWGatewaySubnetPrefix "10.254.1.0/24" -OnpremiseVPNClientSubnetPrefix "192.168.200.0/24" -ResourceGroupName "ContosoVNetGroup" -VNetName "ContosoVNet" -VNetGatewayName "ContosoGateway" -RootCertificateName "ContosoRootCertificate" -ChildCertificateName "ContosoChildCertificate"
```

In addition to provisioning Azure VNET and VPN Gateway resources, the script above will also create a self-signed root certificate and a client certificate for the VPN gateway. The root certificate is used for generating and signing client certificates on the client side, and for validating those client certificates on the VPN gateway side.

To enable people in your organization to connect to the newly provisioned VNET via the VPN gateway, you will need to export the two certificates. You can use the commands below to generate the PFX files. The two files can then be shared and installed on the machines of users who need VPN access.

```PowerShell
$rootCert = Get-ChildItem -Path cert:\CurrentUser\My | ?{ $_.Subject -eq "CN=ContosoRootCertificate" }
$childCert = Get-ChildItem -Path cert:\CurrentUser\My | ?{ $_.Subject -eq "CN=ContosoChildCertificate" }

$type = [System.Security.Cryptography.X509Certificates.X509Certificate]::pfx
$securePassword = ConvertTo-SecureString -String "Welcome1234!" -Force –AsPlainText

Export-PfxCertificate -Cert $rootCert -FilePath "ContosoRootCertificate.pfx" -Password $securePassword -Verbose
Export-PfxCertificate -Cert $childCert -FilePath "ContosoChildCertificate.pfx" -Password $securePassword -Verbose
```

## Provisioning the Domain Controller

The next step is to deploy a Domain Controller VM and set up a new domain. All VMs provisioned during the EDW TRA deployment will join the domain managed by the domain controller. To do that, run the PowerShell script below.

```PowerShell
.\DeployDC.ps1 -SubscriptionName "My Subscription" -Location "westus" -ExistingVNETResourceGroupName "ContosoVNetGroup" -ExistingVNETName "ContosoVNet" -DomainName "contosodomain.ms" -DomainUserName "edwadmin" -DomainUserPassword "Welcome1234!"
```

The script above will provision an Azure VM and promote it to serve as the domain controller for the VNET. In addition, it will reconfigure the VNET to use the newly provisioned VM as its DNS server.