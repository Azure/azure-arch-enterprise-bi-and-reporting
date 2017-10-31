# Setting up the Deployment

Before you start the deployment, confirm that you have an Azure subscription with sufficient quota, and have implemented the prerequisites.

Start the deployment by clicking on the DEPLOY button on the main page - which is README.md in the GitHub, or the solutions page in the Cortana Gallery. Once you click on DEPLOY, the deployment platform takes you through a series of questions to set up the TRI. This section explains each parameter in detail. 

## Deployment name and subscription
### 1. Deployment Name
Provide a deployment name. This name will be assigned to the resource group that contains all the resources required for the TRI.

### 2. Subscription
Provide the name of the Azure subscription where you have set up the prerequisites such as VNET, domain controller etc. and where you want to deploy the reference implementation.

### 3. Location
Choose the Data Center location where you want to deploy the reference implementation. This is a key benefit of the TRI - it saves you the effort of putting together all the products for an enterprise BI and Reporting solution that will be available together in a given Data Center.

### 4. Description
Provide the description for this deployment.

Once you click on create, the resource group gets created in your subscription. This is so that Azure has some resource in the subscription to record all the subsequent parameters that you are about to provide next. After this CREATE step, if you want to abandon your deployment, follow the instructions to cleanly [delete your deployment](./18-Deleting%20a%20deployment).

## VNET and Certificates for component connectivity

### 5. VNET
The next screen accepts the VNET parameters. If you created the VNET and provisioned the domain controller using the steps outlined in [the prerequisites](./1-Prerequisite%20Steps%20Before%20Deployment.md), then input the values you provided for the parameters.
```PowerShell
-VNetName "ContosoVNet" -DomainName "contosodomain.ms" -DnsVmName "contosodns"
``` 

### 6. Certificates to manage security between components
In addition to the certificates generated/used for VNET connectivity, you will need to provide three more certificates to manage secure access between the different components in the TRI.
1. A .PFX file with the private key used by Azure VMs to authenticate with Azure Active Directory, with its corresponding password.
2. A .CER file with the public key of the certificate authority to allow SSL encryption from a non-public certificate.
3. Another .PFX file with the private key used to encrypt all of web server traffic over HTTPS, with its corresponding password.

These certificate files should to publicly available for your Azure subscription, and they must be secure. We recommend that you store the files in Azure Storage with [Shared Access Signature (SAS)](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-dotnet-shared-access-signature-part-2) support. This will enable you to provide the certificates as Blob files, and set the password.

Examples:
- Private key used by VMs to authenticate with Azure Active Directory: http://_contosoblob_.blob.core.windows.net/_certificates_/_contosoglobalcert.pfx_
- Public key of a certificate authority to allow SSL encryption from a non-public certificate: http://_contosoblob_.blob.core.windows.net/_certificates_/_contosoauthority.cer_
- Private key used to encrypt all web server traffic over HTTPS:
http://_contosoblob_.blob.core.windows.net/_certificates_/_contosoauthority.cer_

## Configure the topology
The parameters in this section are self-explanatory in the deployment configuration page.

## Configure the default account names and password
The parameters in this section are self-explanatory in the deployment configuration page.