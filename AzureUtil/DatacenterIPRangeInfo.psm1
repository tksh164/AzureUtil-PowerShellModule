function DownloadDatacenterIPRangeXml
{
    [CmdletBinding()]
    [OutputType([xml])]
    param ()

    #
    # Get the IP address range XML file URI.
    #

    Write-Verbose -Message 'Getting the URI of Azure datacenter IP ranges XML file.'

    $downloadCenterUri = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=41653'
    $confirmationPageContent = Invoke-WebRequest -Method Get -Uri $downloadCenterUri -UseBasicParsing

    $xmlLinkId = 'c50ef285-c6ea-c240-3cc4-6c9d27067d6c'
    $xmlLink = $confirmationPageContent.Links |
        Where-Object -Property 'id' -EQ -Value $xmlLinkId |
        Select-Object -First 1

    if ($xmlLink -eq $null)
    {
        throw 'Cannot get the link to XML file from the download center page.'
    }

    $xmlFileUri = $xmlLink.href

    if ($xmlFileUri -eq $null)
    {
        throw 'Cannot get the URI of XML file.'
    }

    Write-Verbose -Message ('XML file URI: {0}' -f $xmlFileUri)

    #
    # Get the IP address range XML document.
    #

    Write-Verbose -Message 'Getting the XML docuemnt of Azure datacenter IP ranges.'

    $contentBytes = Invoke-WebRequest -Method Get -Uri $xmlFileUri -UseBasicParsing
    $textContent = [System.Text.Encoding]::UTF8.GetString($contentBytes.Content)
    $xmlDoc = [xml] $textContent

    Write-Debug -Message $xmlDoc.OuterXml
    $xmlDoc
}

function ConvertIPv4AddressFromStringToUInt32
{
    [CmdletBinding()]
    [OutputType([uint32])]
    param (
        [Parameter(Mandatory = $true)][ValidatePattern('[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')]
        [string] $IPv4Address
    )

    # Get a IPv4 address as IPAddress object.
    try
    {
        $ipAddress = [System.Net.IPAddress]::Parse($IPv4Address)
    }
    catch
    {
        if ($_.FullyQualifiedErrorId -eq 'FormatException')
        {
            throw ('{0} It is "{1}".' -f $_.Exception.InnerException.Message, $IPv4Address)
        }
        else
        {
            throw $_
        }
    }

    # Get the octets of IPv4 address. 
    $octets = $ipAddress.GetAddressBytes()

    $octet1 = ([uint32] $octets[0]) -shl 24
    $octet2 = ([uint32] $octets[1]) -shl 16
    $octet3 = ([uint32] $octets[2]) -shl 8
    $octet4 = [uint32] $octets[3]

    # Return a IPv4 address as UInt32.
    [uint32] ($octet1 + $octet2 + $octet3 + $octet4)
}

function GetSubnetMaskAsUInt32
{
    [CmdletBinding()]
    [OutputType([uint32])]
    param (
        [Parameter(Mandatory = $true)][ValidateRange(0,32)]
        [int] $NetworkAddressLength
    )

    if ($NetworkAddressLength -eq 0) { return ([uint32] 0) }

    # Create the bits of network address part.
    $mask = [uint32] 1
    for ($i = 0; $i -lt $NetworkAddressLength; $i++)
    {
        $mask = ($mask -shl 1) + 1
    }

    # Shift the bits of host address part.
    $hostAddressLength = (32 - $NetworkAddressLength)
    $mask = $mask -shl $hostAddressLength

    # Return a subnet mask as UInt32.
    [uint32] $mask
}

<#
.SYNOPSIS
Get the Azure datacenter IP address range information of specified public IP address.

.DESCRIPTION
This cmdlet provides quick lookup the Azure datacenter IP address range information from the specified public IP address.

.PARAMETER IPAddress
Specify the public IP address you want to check.

.PARAMETER XmlFilePath
Specify the file path of Azure datacenter IP address range XML file. The latest XML file is can download from https://www.microsoft.com/en-us/download/details.aspx?id=41653. This parameter is optional.

.EXAMPLE
    PS > Get-AzureUtilDatacenterIPRangeInfo -IPAddress '13.73.24.96'

    IPAddress   RegionName IPRange
    ---------   ---------- -------
    13.73.24.96 japaneast  13.73.0.0/19

---- Example Description ----
In this example, get the region and IP address range information of the public IP address "13.73.24.96".

.EXAMPLE
    PS > '13.73.24.96','40.112.124.10','13.88.13.238' | Get-AzureUtilDatacenterIPRangeInfo

    IPAddress     RegionName IPRange
    ---------     ---------- -------
    13.73.24.96   japaneast  13.73.0.0/19
    40.112.124.10 europewest 40.112.124.0/24
    13.88.13.238  uswest     13.88.0.0/19

---- Example Description ----
In this example, get the region and IP address range information of the public IPs via piping.

.EXAMPLE
    PS > $xmlFilePath = 'C:\PublicIPs_20170616.xml'

    PS > '13.73.24.96' | Get-AzureUtilDatacenterIPRangeInfo -XmlFilePath $xmlFilePath

    IPAddress   RegionName IPRange
    ---------   ---------- -------
    13.73.24.96 japaneast  13.73.0.0/19

---- Example Description ----
In this example, get the region and IP address range information of the public IP address "13.73.24.96" using the local XML file. You can get the region and IP address range information on offline if use the local XML file.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Microsoft Azure Datacenter IP Ranges: https://www.microsoft.com/en-us/download/details.aspx?id=41653
#>
function Get-AzureUtilDatacenterIPRangeInfo
{
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]] $IPAddress,

        [Parameter(Mandatory = $false)]
        [string] $XmlFilePath
    )

    begin
    {
        # Get the XML document.
        if ($PSBoundParameters.ContainsKey('XmlFilePath'))
        {
            Write-Verbose -Message ('Reading the Azure datacenter IP ranges XML document from "{0}".' -f $XmlFilePath)
            $xmlDoc = [xml] (Get-Content -LiteralPath $XmlFilePath -Encoding UTF8 -ErrorAction Stop)
        }
        else
        {
            Write-Verbose -Message 'Downloading the Azure datacenter IP ranges XML document.'
            $xmlDoc = DownloadDatacenterIPRangeXml -ErrorAction Stop
        }

        # Get the IpRange nodes from the XML document.
        $ipRanges = $xmlDoc.SelectNodes('//IpRange')
    }

    process
    {
        foreach ($ipAddr in $IPAddress)
        {
            # Build the return value structure.
            $result = [pscustomobject] @{
                IPAddress  = $ipAddr
                RegionName = $null
                IPRange    = $null
            }

            # Get the target IP address as UInt32.
            $targetIpAddressUInt32 = ConvertIPv4AddressFromStringToUInt32 -IPv4Address $ipAddr -ErrorAction Stop

            Write-Verbose -Message ('Target IP: {0} = {1:x}' -f $ipAddr, $targetIpAddressUInt32)

            # Search the IP range that contains the target IP address.
            foreach ($ipRange in $ipRanges)
            {
                # Extract the IP address and subnet mask.
                ($dcIpAddress, [uint32] $dcMaskLength) = $ipRange.Subnet.Split('/', 2, [System.StringSplitOptions]::RemoveEmptyEntries)

                # Get the datacenter IP address and subnet mask as UInt32.
                $dcIpAddressUInt32 = ConvertIPv4AddressFromStringToUInt32 -IPv4Address $dcIpAddress -ErrorAction Stop
                $dcSubnetMaskUInt32 = GetSubnetMaskAsUInt32 -NetworkAddressLength $dcMaskLength -ErrorAction Stop

                Write-Debug -Message ('DC Subnet: {0} = {1:x}/{2:x}' -f $ipRange.Subnet, $dcIpAddressUInt32, $dcSubnetMaskUInt32)
                Write-Debug -Message ('Test Result: {0} & {1} = {2} <-> {3}' -f $targetIpAddressUInt32, $dcSubnetMaskUInt32, ($targetIpAddressUInt32 -band $dcSubnetMaskUInt32), $dcIpAddressUInt32)

                # Test whether the target IP address is included in the datacenter IP address range.
                if (($targetIpAddressUInt32 -band $dcSubnetMaskUInt32) -eq $dcIpAddressUInt32)
                {
                    Write-Verbose -Message ('Found DC Subnet: {0} = {1:x}/{2:x}' -f $ipRange.Subnet, $dcIpAddressUInt32, $dcSubnetMaskUInt32)

                    # Set the found datacenter IP address range information.
                    $result.RegionName = $ipRange.ParentNode.Name
                    $result.IPRange = $ipRange.Subnet
                    break
                }
            }

            $result
        }
    }

    end
    {}
}

<#
.SYNOPSIS
Test whether the specific public IP address that it is Azure public IP address.

.DESCRIPTION
This cmdlet provides quick test to see if the specified IP address is Azure's public IP address.

.PARAMETER IPAddress
Specify the public IP address you want to check.

.PARAMETER XmlFilePath
Specify the file path of Azure datacenter IP address range XML file. The latest XML file is can download from https://www.microsoft.com/en-us/download/details.aspx?id=41653. This parameter is optional.

.EXAMPLE
    PS > Test-AzureUtilDatacenterIPRange -IPAddress '13.73.24.96'
    True

---- Example Description ----
In this example, test the public IP address "13.73.24.96" then confirmed it is Azure's public IP address.

.EXAMPLE
    PS > $xmlFilePath = 'C:\PublicIPs_20170616.xml'

    PS > Test-AzureUtilDatacenterIPRange -IPAddress '40.112.124.10' -XmlFilePath $xmlFilePath 
    True

---- Example Description ----
In this example, test the public IP address "40.112.124.10" using the local XML file then confirmed it is Azure's public IP address.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Microsoft Azure Datacenter IP Ranges: https://www.microsoft.com/en-us/download/details.aspx?id=41653
#>
function Test-AzureUtilDatacenterIPRange
{
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true)][ValidatePattern('[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')]
        [string] $IPAddress,

        [Parameter(Mandatory = $false)]
        [string] $XmlFilePath
    )

    # Build the parameters.
    $params = @{
        IPAddress = $IPAddress
    }
    if ($PSBoundParameters.ContainsKey('XmlFilePath'))
    {
        $params.XmlFilePath = $XmlFilePath
    }

    # Finding the IP address range.
    $result = Get-AzureUtilDatacenterIPRangeInfo @params

    ($result.RegionName -ne $null) -and ($result.IPRange -ne $null)
}
