#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }

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
    $confirmationPageContent = Invoke-WebRequest -Method Get -Uri $downloadCenterUri

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

    $contentBytes = Invoke-WebRequest -Method Get -Uri $xmlFileUri
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
