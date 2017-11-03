# Configuring Data Ingestion

# Summary
This page provides the steps to configure data ingestion in the Enterprise Reporting and BI TRI.

Once the TRI is deployed, these are your two options to ingest your ETL-processed data into the system:
1. Modify the code provided in the TRI to ingest your data
2. Integrate your existing pipeline and store into the TRI


## 1. Modify the code provided in the TRI to ingest your data


The TRI deploys a dedicated VM for data generation, with a PowerShell script placed in the VM. This script gets called by the Job Manager at a regular cadence (that is configurable). You can modify this script as follows;

Confirm that prerequisites are installed in the VM - Install **AzCopy** - if it is not already present in the VM (see [here](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy)). 

Modify the code as per your requirements and run it: The PowerShell script `GenerateAndUploadDataData.ps1` is located in the VM at `C:\EDW\datagen-artifacts`. Please note that this script generates and uploads data.

 See below for an example script which only uploads a file and registers with the job manager.

The following information needs to be retrieved from your resource group. Log into Azure Portal and open the resource group where the solution was deployed.
Go to the Automation account in the resource group and open the automation Account variables. Following are the variables which are needed in the script below or for your own script.

| Name | Variable |
| ---- | -------- |
| ControlServerUri | `controlServerUri` |
| CertThumbprint | `internalDaemonPfxCertThumbprint` |
| AADTenantDomain | `adTenantDomain` |
| ControlServerIdentifierUris | `adAppControlServerIdentifierUri` |
| AADApplicationId | `adAppControlServerId` |

Please adapt the below script as per your needs.


```Powershell
# ---------------------------------------------------------------------------------------------------------------------------------------------
# Name:upload_file_prod.ps1
# Description: This script is use to upload a file to Blob and indicate to job manager that the file has been uploaded
#              The script accepts 3 parameters. TableName, FileName and the Rundate. Here assumption is that a file is sent for a 24hr period.
# Steps:
#       1. Authenticate
#       2. Contact job manager to get the blob.
#       3. Upload the file to the blob.
#       4. Update job manager that upload has finished
# 
# Sample Command line: .\upload_file_prod.ps1 -Tablename 'dbo.customer' -FileName 'customer.tbl.1' -RunDate '20171002'
#-----------------------------------------------------------------------------------------------------------------------------------------------


Param(
      [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Enter Table Name to populate")]
      [string]$Tablename,
      [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Enter filename to upload")]
      [string]$FileName,
      [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Enter the Rundate/dataset date in YYYYMMDD format.")]
      [string]$RunDate
)


Function GetAccessTokenClientCertBased([string] $certThumbprint, [string] $tenant, [string] $resource, [string] $clientId)
{
    [System.Reflection.Assembly]::LoadFile("$PSScriptRoot\Microsoft.IdentityModel.Clients.ActiveDirectory.dll") | Out-Null # adal    
    [System.Reflection.Assembly]::LoadFile("$PSScriptRoot\Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll") | Out-Null # adal    
    $cert = Get-childitem Cert:\LocalMachine\My | where {$_.Thumbprint -eq $certThumbprint}
    $authContext = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext("https://login.windows.net/$tenant") 
    $assertioncert = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($clientId, $cert)
    $result = $authContext.AcquireToken($resource, $assertioncert) 
    $authHeader = @{
        'Content-Type' = 'application\json'
        'Authorization' = $result.CreateAuthorizationHeader()
    }

    return $authHeader
}



Echo "Starting the Program"

# Set the below variables as per your environment. 
# To get this values, login into Azure Portal and open the resource group where the solution was deployed.
# Go to the Automation account in the resource group and open the automationAccount variables 
#   1. ControlServerUri : Variable Name- controlServerUri
#   2. CertThumbprint: Variable Name - internalDaemonPfxCertThumbprint
#   3. AADTenantDomain: Variable Name - adTenantDomain
#   4. ControlServerIdentifierUris : Variable Name - adAppControlServerIdentifierUri
#   5. AADApplicationId: Variable Name - adAppControlServerId


$ControlServerUri = 'https://navigt115t8457.adminui.ciqsedw.ms:8081'
$CertThumbprint = 'xxxxxxx'
$AADTenantDomain = 'xxxxxx'
$ControlServerIdentifierUris = 'http://microsoft.onmicrosoft.com/navigt115t8457ADAppControlServer'
$AADApplicationId = 'xxxxxxx'



# Obtain bearer authentication header
$authenticationHeader = GetAccessTokenClientCertBased -certThumbprint $CertThumbprint `
-tenant $AADTenantDomain `
-resource $ControlServerIdentifierUris `
-clientId $AADApplicationId

# Set the working directory
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
Set-Location $directorypath

# Log file name
$LOG_FILE='dataupload-log.txt'


# Control server URI to fetch the storage details for uploading
# Fetch only the current storage
$getCurrentStorageAccountURI = $ControlServerUri + '/odata/StorageAccounts?$filter=IsCurrent%20eq%20true'

# DWTableAvailabilityRanges endpoint
$dwTableAvailabilityRangesURI = $ControlServerUri + '/odata/DWTableAvailabilityRanges'

# The blob container to upload the datasets to
$currentStorageSASURI = ''

# set Path for On-prem data file location 
$source = "E:\projects\tri\tri1_testing"

# AzCopy path. AzCopy must be installed. Update path if installed in non-default location
$azCopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"


# Data contract for DWTableAvailabilityRanges' request body

$dwTableAvailabilityRangeContract = @{
    DWTableName=""
    StorageAccountName=""
    ColumnDelimiter=""
    FileUri=""
    StartDate=""
    EndDate=""
    FileType=""
}


$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
echo $directorypath > $LOG_FILE

# Invoke the Job Manager to fetch the latest blob container to upload the blobs to
try
{
    $response = Invoke-RestMethod -Uri $getCurrentStorageAccountURI -Method Get -Headers $authenticationHeader
    if($response -and $response.value -and $response.value.SASToken){
        $currentStorageSASURI = $response.value.SASToken
        $storageAccountName = $response.value.Name
        echo "Current storage location - $currentStorageSASURI" >> $LOG_FILE            
    } else{
        $errMessage = "Could not find SAS token in the response fron Control Server." + $response.ToString()        
        echo $errMessage >> $LOG_FILE
        exit 1
    }
}
catch
{
    echo "Error fetching current storage account from Control Server" >> $LOG_FILE
    echo $error >> $LOG_FILE
    exit 2
}


# Create a custom AzCopy log file stamped with current timestamp

$azCopyLogFileName = [io.path]::combine($Env:TEMP, -join("AzCopy-", $((get-date).ToUniversalTime()).ToString("yyyyMMddThhmmssZ"), '.log')) 
If (Test-Path $azCopyLogFileName){

    Remove-Item $azCopyLogFileName
    echo "Deleted existing AzCopy log file $azCopyLogFileName" >> $LOG_FILE
} 

# Create empty log file in the same location
$azCopyLogFile = New-Item $azCopyLogFileName -ItemType file

# Execute AzCopy to upload files. 
echo "Begin uploading data files to storage location " >> $LOG_FILE
& "$azCopyPath" /source:""$source"" /Dest:""$currentStorageSASURI""  /Y /V:""$azCopyLogFile"" /Pattern:$FileName 
echo "Completed uploading data file $srcFileName to storage location" >> $LOG_FILE


echo "Begin post process for - $FileName"
$dwTableName = $Tablename

# **************************************************************************************
#  Date fields need special formatting.
#
#  1. Reconvert to OData supported DateTimeOffset format string using the
#     's' and 'zzz' formatter options
# **************************************************************************************
# Start date
$startDateStr = $RunDate

[datetime]$startDate = New-Object DateTime
if(![DateTime]::TryParseExact($startDateStr, "yyyyMMddHH", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$startDate)){
    [DateTime]::TryParseExact($startDateStr, "yyyyMMdd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$startDate)
}
$startDateFormatted = $startDate.ToString("s") + $startDate.ToString("zzz")

# End date is set to 24 hours . We are assuming the file is sent once per 24 hours.
$endDate = $startDate.AddHours(24)

$endDateFormatted = $endDate.ToString("s") + $endDate.ToString("zzz")

$successFileUri = $currentStorageSASURI.Split("?")
$successFileUri = -join($successFileUri[0],"/",$FileName)
    

#Construct DWTableAvailabilityRange request body
$dwTableAvailabilityRangeContract['DWTableName'] = $dwTableName
$dwTableAvailabilityRangeContract['FileUri'] = $successFileUri
$dwTableAvailabilityRangeContract['StorageAccountName'] = $storageAccountName
$dwTableAvailabilityRangeContract['StartDate'] = $startDateFormatted
$dwTableAvailabilityRangeContract['EndDate'] = $endDateFormatted
$dwTableAvailabilityRangeContract['ColumnDelimiter'] = "|"
$dwTableAvailabilityRangeContract['FileType'] = 'Csv'
 
$dwTableAvailabilityRangeJSONBody = $dwTableAvailabilityRangeContract | ConvertTo-Json

# Create DWTableAvailabilityRanges entry for the current file
    try
    {
        echo "Begin DWTableAvailabilityRanges creation for file -  $fileNameSegment with body $dwTableAvailabilityRangeJSONBody" >> $LOG_FILE
        $response = Invoke-RestMethod $dwTableAvailabilityRangesURI -Method Post -Body $dwTableAvailabilityRangeJSONBody -ContentType 'application/json' -Headers $authenticationHeader
        echo "DWTableAvailabilityRanges creation successful" >> $LOG_FILE
    }
    catch 
    {
        echo "Error creating DWTableAvailabilityRanges on Control Server" >> $LOG_FILE
        echo $error >> $LOG_FILE
    }

exit 0

```


## 2. Integrate your existing pipeline and store into the TRI

In cases where you already have an ETL pipeline setup, you will need to do the following.

1. Use the above script as an example to get the blob account to upload.
2. Upload the File to the storage account using your pipeline
3. Inform the job manager that a file has been uploaded.
