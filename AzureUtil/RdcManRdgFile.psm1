#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Resources'; ModuleVersion='3.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Compute'; ModuleVersion='2.7.0' }
#requires -Modules @{ ModuleName='AzureRM.Network'; ModuleVersion='3.5.0' }

<#
.SYNOPSIS
Create a ".rdg" file for Azure Windows virtual machine connection.

.DESCRIPTION
Create a ".rdg" file for Azure Windows virtual machine connection. The ".rdg" file is can open by Remote Desktop Connection Manager.

.PARAMETER ResourceGroupName
This cmdlet creates connection entries to the virtual machines contained in the resource groups specified by this parameter.

.PARAMETER FilePath
File path of the ".rdg" file to save. This parameter is optional. The default file path is "AzureVMConnection.rdg" under the current folder.

.PARAMETER RootGroupName
Display name for the root node of the ".rdg" file. This parameter is optional. The default display name is "AzureVMConnections".

.EXAMPLE
    Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG'

This example is creates ".rdg" file in current folder. The ".rdg" file contains connections for Azure Windows virtual machine in resource group "Prod-RG" and "Dev-RG".

.EXAMPLE
    Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG' -FilePath 'C:\NewProject.rdg' -RootGroupName 'NewProjectVMs'

This example is creates ".rdg" file as "C:\NewProject.rdg". The ".rdg" file contains connections for Azure Windows virtual machine in resource group "Prod-RG" and "Dev-RG". The root node name of connections is "NewProjectVMs".

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Remote Desktop Connection Manager: https://www.microsoft.com/en-us/download/details.aspx?id=44989
#>
function Out-AzureUtilRdcManRdgFile
{
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string[]] $ResourceGroupName,

        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [string] $FilePath = (Join-Path -Path (Get-Location).Path -ChildPath 'AzureVMConnection.rdg'),

        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [string] $RootGroupName = 'AzureVMConnections'
    )

    # Login check.
    try { [void] (Get-AzureRMContext -ErrorAction Stop) } catch { throw }

    # Create a new XML document.
    $xmlDoc = CreateRdgFileXmlDoc -RootGroupName $RootGroupName

    # Retrieve the RDP connection informations and build the XML elements.
    GetRdpConnectionInfo -ResourceGroupName $ResourceGroupName |
        Group-Object -Property 'ResourceGroupName' |
        ForEach-Object -Process {

            $group = $_

            # Create a new group element as child of the file element.
            $groupElm = CreateGroupElement -XmlDoc $xmlDoc -GroupName $group.Name
            [void] $xmlDoc.RDCMan.file.AppendChild($groupElm)

            $group |
                ForEach-Object -Process {

                    $connectionInfo = $_.Group

                    # Create a new server element as child of the group element.
                    $param = @{
                        XmlDoc      = $xmlDoc
                        Name        = if ($connectionInfo.Fqdn -ne $null) { $connectionInfo.Fqdn } else { $connectionInfo.IpAddress }
                        DisplayName = $connectionInfo.VmName
                        UserName    = $connectionInfo.AdminUsername
                    }
                    $serverElm = CreateServerElement @param
                    [void] $groupElm.AppendChild($serverElm)
                }
        }

    # Save the XML document.
    $xmlDoc.Save($FilePath)
    Write-Verbose -Message ('Saved the file to "{0}"' -f $FilePath)
}

function CreateRdgFileXmlDoc
{
    [CmdletBinding()]
    [OutputType([xml])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $RootGroupName
    )

    # Create a new XML document.
    $xmlDoc = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<RDCMan programVersion="2.7" schemaVersion="3">
<file>
    <credentialsProfiles />
    <properties>
        <expanded>True</expanded>
        <name>Template</name>
    </properties>
</file>
<connected />
<favorites />
<recentlyUsed />
</RDCMan>
'@

    # Set the root group name in .rdg file.
    $xmlDoc.RDCMan.file.properties.name = $RootGroupName

    $xmlDoc
}

function CreateGroupElement
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNull()]
        [xml] $XmlDoc,

        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $GroupName
    )

    # Create a new group element.
    $groupElm = $xmlDoc.CreateElement('group')

    # Create a new properties element as child of the group element.
    $propertiesElm = $xmlDoc.CreateElement('properties')
    [void] $groupElm.AppendChild($propertiesElm)

    # Create a new expanded element as child of the properties element.
    $expandedElm = $xmlDoc.CreateElement('expanded')
    $expandedElm.InnerText = 'True'
    [void] $propertiesElm.AppendChild($expandedElm)

    # Create a new name element as child of the properties element.
    $nameElm = $xmlDoc.CreateElement('name')
    $nameElm.InnerText = $GroupName
    [void] $propertiesElm.AppendChild($nameElm)

    $groupElm
}

function CreateServerElement
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNull()]
        [xml] $XmlDoc,

        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $DisplayName,

        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $UserName
    )

    # Create a new server element.
    $serverElm = $xmlDoc.CreateElement('server')

    # Create a new properties element as child of the server element.
    $propertiesElm = $xmlDoc.CreateElement('properties')
    [void] $serverElm.AppendChild($propertiesElm)

    # Create a new displayName element as child of the properties element.
    $displayNameElm = $xmlDoc.CreateElement('displayName')
    $displayNameElm.InnerText = $DisplayName
    [void] $propertiesElm.AppendChild($displayNameElm)

    # Create a new name element as child of the properties element.
    $nameElm = $xmlDoc.CreateElement('name')
    $nameElm.InnerText = $Name
    [void] $propertiesElm.AppendChild($nameElm)

    # Create a new logonCredentials element as child of the server element.
    $logonCredentialsElm = $xmlDoc.CreateElement('logonCredentials')
    $logonCredentialsElm.SetAttribute('inherit', 'None')
    [void] $serverElm.AppendChild($logonCredentialsElm)

    # Create a new profileName element as child of the logonCredentials element.
    $profileNameElm = $xmlDoc.CreateElement('profileName')
    $profileNameElm.SetAttribute('scope', 'Local')
    $profileNameElm.InnerText = 'Custom'
    [void] $logonCredentialsElm.AppendChild($profileNameElm)

    # Create a new userName element as child of the logonCredentials element.
    $userNameElm = $xmlDoc.CreateElement('userName')
    $userNameElm.InnerText = $UserName
    [void] $logonCredentialsElm.AppendChild($userNameElm)

    # Create a new password element as child of the logonCredentials element.
    $passwordElm = $xmlDoc.CreateElement('password')
    [void] $logonCredentialsElm.AppendChild($passwordElm)

    # Create a new domain element as child of the logonCredentials element.
    $domainElm = $xmlDoc.CreateElement('domain')
    $domainElm.InnerText = '.'
    [void] $logonCredentialsElm.AppendChild($domainElm)

    $serverElm
}

function GetRdpConnectionInfo
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string[]] $ResourceGroupName
    )

    $ResourceGroupName |
        ForEach-Object -Process {
            Get-AzureRmVM -ResourceGroupName $_ |
                Where-Object -FilterScript { $_.OSProfile.WindowsConfiguration -ne $null } |
                ForEach-Object -Process {

                    $vm = $_

                    # The values container.
                    $connectionInfo = [PSCustomObject] @{
                        ResourceGroupName = $vm.ResourceGroupName
                        VmName            = $vm.Name
                        AdminUsername     = $vm.OSProfile.AdminUsername
                        IpAddress         = $null
                        Fqdn              = $null
                    }

                    # Get the primary network interface.
                    $primaryNetworkInterface = GetPrimaryNetworkInterface -VM $vm

                    # Get the primary IP configuration.
                    $primaryIpConfiguration = $primaryNetworkInterface.IpConfigurations |
                        Where-Object -Property 'Primary' -EQ -Value $true

                    if ($primaryIpConfiguration.PublicIpAddress -ne $null)
                    {
                        $publicIpAddress = GetPublicIpAddress -PublicIpAddress $primaryIpConfiguration.PublicIpAddress

                        $connectionInfo.IpAddress = $publicIpAddress.IpAddress
                        if ($publicIpAddress.DnsSettings -ne $null)
                        {
                            $connectionInfo.Fqdn = $publicIpAddress.DnsSettings.Fqdn
                        }

                        $connectionInfo
                    }
                    else
                    {
                        Write-Verbose -Message ('The {0} in {1} is not assigned public IP address.' -f $vm.Name,$vm.ResourceGroupName)
                    }
                }
        }
}

function GetPrimaryNetworkInterface
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Network.Models.PSNetworkInterface])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNull()]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM
    )

    $primaryNetworkInterfaceId = GetPrimaryNetworkInterfaceId -VM $vm
    $primaryNetworkInterfaceResource = Get-AzureRmResource -ResourceId $primaryNetworkInterfaceId
    $primaryNetworkInterface = Get-AzureRmNetworkInterface -ResourceGroupName $primaryNetworkInterfaceResource.ResourceGroupName -Name $primaryNetworkInterfaceResource.Name

    $primaryNetworkInterface
}

function GetPrimaryNetworkInterfaceId
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNull()]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM
    )

    # Find the primary network interface.
    $primaryNetworkInterface = if ($VM.NetworkProfile.NetworkInterfaces.Count -eq 1)
    {
        $VM.NetworkProfile.NetworkInterfaces |
            Select-Object -First 1
    }
    else
    {
        $VM.NetworkProfile.NetworkInterfaces |
            Where-Object -Property 'Primary' -EQ -Value $true |
            Select-Object -First 1
    }

    $primaryNetworkInterface.Id
}

function GetPublicIpAddress
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNull()]
        [Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress] $PublicIpAddress
    )

    $publicIpAddressResource = Get-AzureRmResource -ResourceId $PublicIpAddress.Id
    $publicIpAddress = Get-AzureRmPublicIpAddress -ResourceGroupName $publicIpAddressResource.ResourceGroupName -Name $publicIpAddressResource.Name

    $publicIpAddress
}
