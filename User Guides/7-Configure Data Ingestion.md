# Configuring Data Ingestion
This page provides the steps to configure data ingestion in the Enterprise Reporting and BI TRI.

Once the TRI is deployed, these are your two options to ingest your ETL-processed data into the system:
1. Modify the code provided in the TRI to ingest your data
2. Integrate your existing pipeline and store into the TRI

## Modify the Data Generator code

The TRI deploys a dedicated VM for data generation, with a Powershell script placed in the VM. This script gets called by the Job Manager at a regular cadence (that is configurable). You can modify this script as follows;

1. **Install the VPN client:** This has multiple steps:
- Confirm that your client machine has the two certificates installed for VPN connectivity to the VM (see [prerequisites](https://msdata.visualstudio.com/AlgorithmsAndDataScience/TRIEAD/_git/CIPatterns?_a=preview&path=%2Fdoc%2FPrerequisites.md)).
- Login to http://portal.azure.com, and find the Resource Group that corresponds to the VNet setup. Pick the **Virtual Network** resource, and then the **Virtual Network Gateway** in that resource.
- Click on **Point-to-site configuration**, and **Download the VPN client** to the client machine.
- Install the 64-bit (Amd64) or 32-bit (x86) version based on your Windows operating system. The  modal dialog that pops up after you launch the application may show up with a single **Don't run** button. Click on **More**, and choose **Run anyway**.
- Finally, choose the relevant VPN connection from **Network & Internet Settings**. This should set you up for the next step.

2. **Get the IP address for data generator VM:** From the portal, open the resource group in which the TRI is deployed (this will be different than the VNET resource group), and look for a VM with the string 'dg' in its name. 

 **TODO - The Filter input does not search for substrings - so the user will have to provide the exact prefix of the name or scroll through the VMs. Suggest that we make this easier with a 'DataGenerator' in the string.**

 Choose (i.e. click on) the VM, click on **Networking** tab for that specific VM, and find the private IP address that you can remote to.

3. **Connect to the VM**: Remote Desktop to the VM using the IP address with the admin account and password that you specified as part of the pre-deployment checklist.

**TODO - where can I find this information in the Azure Resource Group itself? This is relevant because the DevOps persona who deployed the TRI (using CIQS) may be different than the Developer who is trying to implement the data load (who knows nothing about CIQS).**

4. **Confirm that prerequisites are installed in the VM** - Install **AzCopy** - if it is not already present in the VM (see [here](https://azure.microsoft.com/en-us/blog/azcopy-5-1-release/)). Confirm that GenData.exe

5. **Modify the code as per your requirements and run it:** The PowerShell script ``GenerateAndUploadDataData.ps1`` is located in the VM at ``C:\EDW\datagen-artifacts``.

**TODO - Replace EDW\datagen-artifacts with C:\Enterprise_BI_and_Reporting_TRI\DataGenerator**

**TODO - Explain the OData configuration for any random client to use this.**

**TODO - Does the code below follow https://github.com/PoshCode/PowerShellPracticeAndStyle#table-of-contents It is not a P0 that it should, but customers would expect that from a Microsoft product.**

### TODO - CODE REVIEW COMMENTS BELOW
1. Parameters - we may want to unify the terminology with the pre-deployment questionnaire. There are like certificate thumbprint, AAD domain for control server authentication, AAD app uri etc. We need to use the same terminology for these paramaters that we use in the Pre-Deployment questionnaire - otherwise, the user will misconstrue these to be new prerequisites.
2. We have to agree to one term - 'Control Server' or Job Manager. Job Manager is plastered all over our architecture diagrams - so if that is what we want to call it, I will change the diagrams. Let us be consistent - **Tyler**, let me know.
2. $DATA_DIR - rename it to be something generic, as in 'DataFileLocation'
3. Is it GenData.exe or GetData.exe?
4. Rename $DATA_SLICE to $DATA_SLICE_IN_HOURS
5. Why do we truncate the timestamp in $OUT_DATE_FORMAT, why not have yyyy-mm-dd-HH:mm:ss.
6. $OUT_DIR to $OUTPUT_DIRECTORY
7. $OUT_DATE_FORMAT to $OUTPUT_DATE_FORMAT
8. $GEN_EXE to $DATAGEN_EXE
9. I moved some initialization code to AFTER the functions - if the functions break because of positional dependency, those initialization labels should ideally be parameterized.
10. Need some more clarity on the "Post processing workflow" section on the filename formats.

```Powershell

# ------------------------ Parameters ---------------------------------------------------------
Param(
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Control Server Uri, example: http://localhost:33009")]
    [string]$ControlServerUri,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Certificate thumbprint for control server authentication.")]
    [string]$CertThumbprint,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="AAD domain for control server authentication.")]
    [string]$AADTenantDomain,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="Control server AAD app uri for control server authentication.")]
    [string]$ControlServerIdentifierUris,
    [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, HelpMessage="AAD application to use for control server authentication.")]
    [string]$AADApplicationId
)

# ------------------------- Functions ----------------------------------------------------------
# Generate random data for AdventureWorks Data Warehouse

Function Generate-Data
{
    $DATA_DIR='Adventure Works 2014 Warehouse Data'   # Directory where data files are located
    $FILE_LIST='files.txt'                     # List of files to read to generate random data
    $GEN_EXE='bin\GetData.exe'                        # GenData.exe location
    $DATA_SLICE=3                                     # Data slice period in hours
    $DATE_FORMAT='yyyy-MM-dd H:mm:ss'                 # Date format to be used in data
    $OUT_DATE_FORMAT='yyyyMMddH'                      # Date format of the output directory
    $OUT_DIR='out'                                    # Name of the output directory

    echo "Running data generation" >> $LOG_FILE

    # Get the current date, round it as ADF slices accept and calculate slice dates
    $curDate = Get-Date
    $roundDiffHour = ([int]($curDate.Hour/$DATA_SLICE))*$DATA_SLICE
    if($roundDiffHour -ne 0)
    {
           $roundDiffHour = $curDate.Hour-$roundDiffHour
    }
    else
    {
           $roundDiffHour = $curDate.Hour
    }
    $curDate = $curDate.AddHours(-$roundDiffHour)
    $prevDate = $curDate.AddHours(-$DATA_SLICE)
    $curDateStr = Get-Date $curDate -format $DATE_FORMAT
    $prevDateStr = Get-Date $prevDate -format $DATE_FORMAT

    # Date to be used for output directory
    $curDateOutStr = Get-Date $curDate -format $OUT_DATE_FORMAT
    $prevDateOutStr = Get-Date $prevDate -format $OUT_DATE_FORMAT
    $outputDir="$OUT_DIR\$prevDateOutStr" + "_" + $curDateOutStr

    # Create output directory
    New-Item $outputDir -type directory | Out-Null
    echo "Created dir $outputDir" >> $LOG_FILE

    $jobHash = @{}

    # Read the files list
    $files = Import-Csv $DATA_DIR\$FILE_LIST
    $processes = @()
    foreach ($file in $files)
    {
        # For each listed file generate random data
        $fileName = $file.FileName
        $sizeRequired = $file.SizeRequiredinMB

        echo "Processing file $fileName" >> $LOG_FILE

        $stdOutLog = [System.IO.Path]::GetTempFileName()
        $process = (`
            Start-Process `
                -FilePath "$directorypath\$GEN_EXE" `
                -ArgumentList "`"$directorypath\$DATA_DIR\$fileName`" `"$directorypath\$outputDir\$fileName`" `"$prevDateStr`" $sizeRequired" `
                -PassThru `
                -RedirectStandardOutput $stdOutLog)

        $processes += @{Process=$process; LogFile=$stdOutLog}
    }
    # Aggregate the data into an output file
    foreach($process in $processes)
    {
        $process.Process.WaitForExit()
        Get-Content $process.LogFile | Out-File $LOG_FILE -Append
        Remove-Item $process.LogFile -ErrorAction Ignore
    }
}

Function Archive-File
(
    [Parameter(Mandatory=$true)]
    [string]$sourcefileToArchive,

    [Parameter(Mandatory=$true)]
    [string]$archivalTargetFile
)
{
    # Move the processed data from source to the archival folder
    try
    {
        $sourceFolder = [io.path]::GetDirectoryName($sourcefileToArchive)
        $archivalTargetFolder = [io.path]::GetDirectoryName($archivalTargetFile)
        If (Test-Path $sourceFolder)
        {
            If(!(Test-Path $archivalTargetFolder))
            {
                New-Item -ItemType directory -Path $archivalTargetFolder
            }

            Move-Item -Path $sourcefileToArchive -Destination $archivalTargetFile -Force
        }
    }
    catch
    {
        echo "Error moving $sourceFolder to archive file $archivalTargetFolder" >> $LOG_FILE
        echo $error >> $LOG_FILE
    }
}

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

# ----------------------- Initialization ------------------------------------------------------
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path

# Create logs folder if it does not already exist
New-Item -ItemType Directory -Force -Path "$directorypath\logs"

# Log file name
$LOG_FILE="logs\createdwtableavailabilityranges.$(get-date -Format yyyy-MM-ddTHH.mm.ss)-log.txt"

# Obtain bearer authentication header
$authenticationHeader = GetAccessTokenClientCertBased -certThumbprint $CertThumbprint `
                                                        -tenant $AADTenantDomain `
                                                        -resource $ControlServerIdentifierUris `
                                                        -clientId $AADApplicationId

# Set the working directory
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
Set-Location $directorypath

# On-prem data file location 
$source = "\\localhost\generated_data"

# On-prem source file archival location 
$archivalSource = "\\localhost\archive"

# The blob container to upload the datasets to
$currentStorageSASURI = ''

# AzCopy path. AzCopy must be installed. Update path if installed in non-default location
$azCopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"

# Control server URI to fetch the storage details for uploading
# Fetch only the current storage
$getCurrentStorageAccountURI = $ControlServerUri + '/odata/StorageAccounts?$filter=IsCurrent%20eq%20true'

# DWTableAvailabilityRanges endpoint
$dwTableAvailabilityRangesURI = $ControlServerUri + '/odata/DWTableAvailabilityRanges'

# Data contract for DWTableAvailabilityRanges' request body
$dwTableAvailabilityRangeContract = @{
    DWTableName=""
    StorageAccountName=""
    ColumnDelimiter="|"
    FileUri=""
    StartDate=""
    EndDate=""
}

# --------------------- Loading to Blob ------------------------------------------------------

# Generate random data for AdventureWorks DW
Generate-Data

# Invoke the Control Server to fetch the latest blob container to upload the files to
try
{
    $response = Invoke-RestMethod -Uri $getCurrentStorageAccountURI -Method Get -Headers $authenticationHeader
    if($response -and $response.value -and $response.value.SASToken){
        $currentStorageSASURI = $response.value.SASToken
        $storageAccountName = $response.value.Name
        echo "Current storage location - $currentStorageSASURI" >> $LOG_FILE            
    } else{
        $errMessage = "Could not find SAS token in the response from Control Server." + $response.ToString()        
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
# IMPORTANT: Creation of DWTableAvailabilityRanges entry depends on this step.
$azCopyLogFileName = [io.path]::combine($Env:TEMP,
    -join("AzCopy-", $((get-date).ToUniversalTime()).ToString("yyyyMMddThhmmssZ"), '.log')) 

If (Test-Path $azCopyLogFileName)
{
    Remove-Item $azCopyLogFileName
    echo "Deleted existing AzCopy log file $azCopyLogFileName" >> $LOG_FILE
} 

# Create empty log file in the same location
$azCopyLogFile = New-Item $azCopyLogFileName -ItemType file

# Execute AzCopy to upload files. 
echo "Begin uploading data files to storage location using azcopy log at $azCopyLogFile" >> $LOG_FILE

& "$azCopyPath" /source:""$source"" /Dest:""$currentStorageSASURI"" /S /Y /Z /V:""$azCopyLogFile""

echo "Completed uploading data files to storage location" >> $LOG_FILE

# ----------- Post-upload logic to set DWTableAvailabilityRanges -----------------------------
#
# Why do we need this: AzCopy outputs a log file. We have to read this log file to figure out
# if upload succeeded or not (regardless of whether this is for a single file or not).
# We let the upload to be optimized by simply giving AzCopy the root share
#
# Sample AzCopy log content shown below:
# 
#[2017/02/09 23:06:36.816+00:00][VERBOSE] Finished transfer: \\localhost\generated_data\2017020616_2017020619\FactCallCenter.csv => https://datadroptxjoynbi.blob.core.windows.net/data/2017020616_2017020619/FactCallCenter.csv
#[2017/02/09 23:06:37.438+00:00][VERBOSE] Start transfer: \\localhost\generated_data\201702097_2017020910\FactSalesQuota.csv => https://datadroptxjoynbi.blob.core.windows.net/data/201702097_2017020910/FactSalesQuota.csv
#[2017/02/09 23:06:43.623+00:00][VERBOSE] Finished transfer: \\localhost\generated_data\2017020613_2017020616\FactSalesQuota.csv => https://datadroptxjoynbi.blob.core.windows.net/data/2017020613_2017020616/FactSalesQuota.csv
#[2017/02/09 23:06:46.078+00:00][VERBOSE] Start transfer: \\localhost\generated_data\201702097_2017020910\FactSurveyResponse.csv => https://datadroptxjoynbi.blob.core.windows.net/data/201702097_2017020910/FactSurveyResponse.csv
#
# Post-processing workflow
# ------------------------
# 1. Inspect AzCopy log file to find all files that have finished transfer successfully,
#    from ('Finished transfer:') entries.
# 2. For each line in the file, extract the upload URI 
# 3. Construct all the required file segments for creating DWTableAvailabilityRanges
#    Last segment - File name of format - <dwTableName>.csv, 
#    Last but one segment - Folder name of format - <startdate>_<enddate>
# 4. Reformat/reconstruct the JSON body for the DWTableAvailabilityRanges using these values
# 5. Once DWTableAvailabilityRanges is created, move the files out to an archival share
#    (where they can be further processed or deleted)
# ---------------------------------------------------------------------------------------------
  
$transferredFiles = select-string -Path $azCopyLogFile -Pattern '\b.*Finished transfer:\s*([^\b]*)' -AllMatches | % { $_.Matches } | % { $_.Value }
foreach($file in $transferredFiles)
{
    echo "Begin publish to Control Server for - $file" >> $LOG_FILE

    # Extract url
    $successFileUri = $file | %{ [Regex]::Matches($_, "(http[s]?|[s]?ftp[s]?)(:\/\/)([^\s,]+)") } | %{ $_.Value }

    # URI of successfully uploaded blob
    $uri = New-Object -type System.Uri -argumentlist $successFileUri

    # Extract segments - filename
    $fileNameSegment = $uri.Segments[$uri.Segments.Length-1].ToString()
    $dwTableName = [io.path]::GetFileNameWithoutExtension($fileNameSegment)  # Assumes file name is table name.<format>

    # Extract segments - start & end date
    $startEndDateSegment = $uri.Segments[$uri.Segments.Length-2].ToString() -replace ".$"

    # **************************************************************************************
    #  Date fields need special formatting.
    #
    #  1. Folder name has date of format yyyyMMHH or yyyyMMH
    #  2. Convert string to a valid DateTime based on #1
    #  3. Reconvert to OData supported DateTimeOffset format string using the
    #     's' and 'zzz' formatter options
    # **************************************************************************************
    # Start date
    $startDateStr = $startEndDateSegment.Split('_')[0]
    [datetime]$startDate = New-Object DateTime
    if(![DateTime]::TryParseExact($startDateStr, "yyyyMMddHH", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$startDate))
    {
        [DateTime]::TryParseExact($startDateStr, "yyyyMMddH", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$startDate)
    }
    $startDateFormatted = $startDate.ToString("s") + $startDate.ToString("zzz")

    # End date
    $endDateStr = $startEndDateSegment.Split('_')[1]
    [datetime]$endDate = New-Object DateTime
    if(![DateTime]::TryParseExact($endDateStr, "yyyyMMddHH", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$endDate)){
        [DateTime]::TryParseExact($endDateStr, "yyyyMMddH", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$endDate)
    }    
    $endDateFormatted = $endDate.ToString("s") + $endDate.ToString("zzz")
    
    #Construct DWTableAvailabilityRange request body
    $dwTableAvailabilityRangeContract['DWTableName'] = $dwTableName
    $dwTableAvailabilityRangeContract['FileUri'] = $successFileUri.ToString()
    $dwTableAvailabilityRangeContract['StorageAccountName'] = $storageAccountName
    $dwTableAvailabilityRangeContract['StartDate'] = $startDateFormatted
    $dwTableAvailabilityRangeContract['EndDate'] = $endDateFormatted

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
        exit 1
    }

    $sourcefileToArchive = [io.path]::Combine($source, $startEndDateSegment, $fileNameSegment)
    $archivalTargetFolder = [io.path]::Combine($archivalSource, $startEndDateSegment)
    $archivalTargetFile = [io.path]::Combine($archivalTargetFolder, $fileNameSegment)
    Archive-File `
        -sourcefileToArchive $sourcefileToArchive `
        -archivalTargetFile $archivalTargetFile

    echo "Completed publish to Control Server for - $file" >> $LOG_FILE

}

echo "Completed publish to Control Server for all files" >> $LOG_FILE

# Cleanup: Remove any empty folders from the source share
Get-ChildItem -Path $source -Recurse `
    | Where { $($_.Attributes) -match "Directory" -and $_.GetFiles().Count -eq 0 } `
    | Foreach { Remove-Item $_.FullName -Recurse -Force }

# Cleanup: Delete the AzCopy log file if the processing went through successfully.
# IMPORTANT: Undeleted log files will therefore indicate an issue in post-processing,
# so they can be reprocessed if need be.
Remove-Item $azCopyLogFileName

exit 0
```

## Data file nomenclature
The data files that are generated in Azure BLOBs for loading into the SQL DW should have the following, recommended, file names.
Data File:		<startdatetime>-<enddatetime>-<schema>.<tablename>.data.orc
Audit file:		<startdatetime>-<enddatetime>-<schema>.<tablename>.data.audit.json

This helps provide sufficient information to determine the intent of the file should it appear outside of the expected system paths.  The purpose of the audit file is to contain the rowcount, start/end date, filesize and checksum.  Audit files must appear next to their data files in the same working directory always.  Orphaned data or audit files should not be loaded.

