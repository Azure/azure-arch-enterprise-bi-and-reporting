# This module contains network related common functions

# To get virtual network. If not possible to get virtual network, exit as it is a critical requirement
Function Get-VirtualNetworkOrExit(
    [Parameter(Mandatory=$true)]
    [string] $ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string] $VirtualNetworkName
)
{
    try {
        $virtualNetwork = Get-AzureRmVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName

        if (-not $virtualNetwork) {
            Write-Host -ForegroundColor DarkRed "Unable to get virtual network $($VirtualNetworkName). Exiting..."
            Display-VnetErrorMessage

            exit 3
        }

        return $virtualNetwork
    } catch {
        Write-Host -ForegroundColor DarkRed "Unable to get virtual network $($VirtualNetworkName). Exiting..."
        Write-Host $Error[0]
        Display-VnetErrorMessage

        exit 3
    }
}

# Get uint32 value for given IPv4 network address
Function Get-NetworkValue(
    [Parameter(Mandatory=$true)]
    [string] $NetworkPrefix
)
{
    $strArray = $NetworkPrefix.Split(".")
    [uint32] $value = 0
    for($i=0; $i -lt 4; $i++) {
        $value = ($value -shl 8) + [convert]::ToInt16($strArray[$i])
    }

    return $value
}

# Get Ipv4 network address for given uint32
Function Get-NetworkAddress(
    [Parameter(Mandatory=$true)]
    [uint32] $NetworkValue
)
{
    [uint32] $mask = (1 -shl 8) - 1
    [string] $networkAddress = ""
    for($i=0; $i -lt 3; $i++) {
        [uint32] $value = $NetworkValue -band $mask
        $NetworkValue = $NetworkValue -shr 8
        $networkAddress = "." + $value + $networkAddress
    }

    $networkAddress = "$($NetworkValue)$($networkAddress)"
    return $networkAddress
}

# Get free subnet or existing given subnet under given virtual network or exit
# If free subnet is found then it is created under VNET for this deployment to use
Function Get-AvailableSubnetOrExit(
    [Parameter(Mandatory=$true)]
    [object] $VirtualNetwork,

    [Parameter(Mandatory=$true)]
    [string] $SubnetName
)
{
    $GatewaySubnetName = "GatewaySubnet"
    $TotalBits = 32

    try {
        $vnetAddressPrefix = $VirtualNetwork.AddressSpace.AddressPrefixes[0]
        $addressPrefixArray = $vnetAddressPrefix.Split("/")
        $networkAddress = $addressPrefixArray[0]
        [int]$networkNumBits = $TotalBits - ([convert]::ToInt32($addressPrefixArray[1], 10))

        $gatewaySubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $GatewaySubnetName -VirtualNetwork $VirtualNetwork
        if (-not $gatewaySubnet) {
            Write-Host -ForegroundColor DarkRed "Unable to get subnet for deployment. Exiting..."
            Display-VnetErrorMessage

            exit 4
        }

        # Using GatewaySubnet range size for all subnets to keep things simple
        $addressPrefixArray = $gatewaySubnet.AddressPrefix.Split("/")
        $gwNetworkAddress = $addressPrefixArray[0]
        $gwNetworkAddressSuffix = $addressPrefixArray[1]
        [int]$gwNetworkNumBits = $TotalBits - ([convert]::ToInt16($gwNetworkAddressSuffix, 10))

        # Track use subnets
        $usedSubnets = New-Object 'System.Collections.Generic.HashSet[int]'
        for($i=0; $i -lt $VirtualNetwork.Subnets.Count; $i++) {
            $subnet = $VirtualNetwork.Subnets[$i]
            if ($subnet.Name.Equals($SubnetName)) {
                # Found an existing given subnet, return it
                return $subnet.AddressPrefix
            }

            [uint32]$value = Get-NetworkValue ($subnet.AddressPrefix.Split("/"))[0]
            $value = $value -shr $gwNetworkNumBits
            $mask = (1 -shl ($networkNumBits - $gwNetworkNumBits)) - 1
            $value = $value -band $mask

            $usedSubnets.Add($value) | Out-Null
        }

        # Find a free subnet
        $numSubnets = 1 -shl ($networkNumBits - $gwNetworkNumBits)
        for([uint32]$i=1; $i -lt $numSubnets; $i++) {
            if (-not $usedSubnets.Contains($i)) {
                # Found a free subnet

                [uint32]$value = Get-NetworkValue $networkAddress
                $value = $value -bor ($i -shl $gwNetworkNumBits)

                $newSubnetAddress = Get-NetworkAddress $value
                $newSubnetPrefix = "$($newSubnetAddress)/$($gwNetworkAddressSuffix)"

                # Create the new subnet
                New-Subnet -VirtualNetwork $VirtualNetwork `
                                -SubnetName $SubnetName `
                                -SubnetPrefix $newSubnetPrefix | Out-Null

                return $newSubnetPrefix
            }
        }

        Write-Host -ForegroundColor DarkRed "Unable to find free subnet for deployment. Exiting..."
        Display-VnetErrorMessage

        exit 4
    } catch {
        Write-Host -ForegroundColor DarkRed "Unable to get subnet for deployment. Exiting..."
        Display-VnetErrorMessage

        Write-Host $Error[0]

        exit 4
    }
}

# Creates a subnet under given VNET
Function New-Subnet(
    [Parameter(Mandatory=$true)]
    [object] $VirtualNetwork,

    [Parameter(Mandatory=$true)]
    [string] $SubnetName,

    [Parameter(Mandatory=$true)]
    [string] $SubnetPrefix
)
{
    Add-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VirtualNetwork -AddressPrefix $SubnetPrefix
    Set-AzureRmVirtualNetwork -VirtualNetwork $VirtualNetwork
}

Function Display-VnetErrorMessage()
{
    Write-Host -ForegroundColor DarkRed "Unable to determine VNET or subnet used for this deployment."
    Write-Host -ForegroundColor DarkRed "If your setup uses point-to-site VPN configuration, please run DeployVPN.ps1 script before running this script."
}
