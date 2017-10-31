# Prerequisites before deploying Technical Reference Implementation for Enterprise BI and Reporting

# VNET

Most of the resources provisioned will be placed in an Azure VNET that should be configured in the subscription where you will want the TRI to be deployed. Customers who already have a functioning Azure VNET and domain controller can skip this section. If not, an Azure VNET resource and a domain controller must be deployed in the subscription, following the steps provided in this guide.

## Provisioning Azure VNet resource and creating root and client certificates

First, create a new Azure VNET and VPN Gateway resource. Navigate to the <source root>\scripts directory and run the command below, altering the parameter values to ones that apply to your environment. Note that it might take up to 45 minutes to complete.

```PowerShell
Login-AzureRmAccount

.\DeployVPN.ps1 -SubscriptionName "My Subscription" -ResourceGroupName "ContosoVNetGroup" -Location "eastus" -VNetName "ContosoVNet" -VNetGatewayName "ContosoGateway" -AddressPrefix "10.254.0.0/16" -GatewaySubnetPrefix "10.254.1.0/24" -OnpremiseVPNClientSubnetPrefix "192.168.200.0/24" -RootCertificateName "ContosoRootCertificate" -ChildCertificateName "ContosoChildCertificate"
```

The above script will provision the Azure VNET and VPN Gateway resources. In addition, it will create a self-signed root certificate (identified by ```ContosoRootCertificate``` in the above example), and a client certificate for the VPN gateway (identified by ```ContosoChildCertificate```). The root certificate is used for generating and signing client certificates on the client side, and for validating those client certificates on the VPN gateway side.

## Export the certificates

To enable users in your organization to connect to the newly provisioned VNET via the VPN gateway, you will need to export the two certificates to generate PFX files that they can import to their devices.

From the same PowerShell console that you used above, run the commands shown below to generate the PFX files in the same directory (```ContosoRootCertificate.pfx``` and ```ContosoChildCertificate.pfx``` in the example)

```PowerShell
$rootCert = Get-ChildItem -Path cert:\CurrentUser\My | ?{ $_.Subject -eq "CN=ContosoRootCertificate" }
$childCert = Get-ChildItem -Path cert:\CurrentUser\My | ?{ $_.Subject -eq "CN=ContosoChildCertificate" }

$type = [System.Security.Cryptography.X509Certificates.X509Certificate]::pfx
$securePassword = ConvertTo-SecureString -String "MyPassword" -Force –AsPlainText

Export-PfxCertificate -Cert $rootCert -FilePath "ContosoRootCertificate.pfx" -Password $securePassword -Verbose
Export-PfxCertificate -Cert $childCert -FilePath "ContosoChildCertificate.pfx" -Password $securePassword -Verbose
```
Share these two files with the users who need VPN access, instructing them to install these files in their client machines (using Certmgr or other tools).

## Provisioning the Domain Controller

The next step is to deploy a Domain Controller VM and set up a new domain. All VMs provisioned during the solution's deployment will join the domain managed by the domain controller.

To do that, run the PowerShell script below.

```PowerShell
$securePassword = ConvertTo-SecureString -String "MyPassword" -Force –AsPlainText

.\DeployDC.ps1 -SubscriptionName "My Subscription" -Location "eastus" -ResourceGroupName "ContosoVNetGroup" -VNetName "ContosoVNet" -DomainName "contosodomain.ms" -DnsVmName "contosodns" -DomainUserName "MyUser" -DomainUserPassword $securePassword
```

The script above will provision an Azure VM and promote it to serve as the domain controller for the VNET. In addition, it will reconfigure the VNET to use the newly provisioned VM as its DNS server.