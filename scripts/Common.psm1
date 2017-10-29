function New-ResourceGroupIfNotExists ($resourceGroupName, $location) {
    $resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if(-not $resourceGroup) {
        New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
        Write-Output ("Created Resource Group $resourceGroupName in $location.");
        return;
    }
    
    $isSameLocation = $resourceGroup.Location -eq $location
    if(-not $isSameLocation) {
        throw "Resource Group $resourceGroup exists in a different location $resourceGroup.Location .. Delete the existing resource group or choose another name." ;
    }
    
    Write-Output ("Resource Group $resourceGroupName already exists. Skipping creation.");
}

function New-Session () {
    $Error.Clear()
    $ErrorActionPreference = "SilentlyContinue"
    Get-AzureRmContext -ErrorAction Continue;
    foreach ($eacherror in $Error) {
        if ($eacherror.Exception.ToString() -like "*Run Login-AzureRmAccount to login.*") {
            Add-AzureAccount
        }
    }
    $Error.Clear();
    $ErrorActionPreference = "Stop"
}

function Load-Module($name)
{ 
    if(-not(Get-Module -name $name)) 
    { 
        if(Get-Module -ListAvailable | 
            Where-Object { $_.name -eq $name }) 
        { 
            Import-Module -Name $name 
            Write-Host "Module $name imported successfully"
        } #end if module available then import 

        else 
        { 
            Write-Host "Module $name does not exist. Installing.."  
            Install-Module -Name $name -AllowClobber -Force
            Write-Host "Module $name installed successfully"  
        } #module not available 

    } # end if not module 

    else 
    { 
        Write-Host "Module $name exists and is already loaded"  
    } #module already loaded 
}
