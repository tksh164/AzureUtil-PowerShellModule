#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Resources'; ModuleVersion='3.6.0' }

<#
.SYNOPSIS
Get the resource groups that not contains any resources from the entire subscription.

.DESCRIPTION
Get the resource groups that not contains any resources from the entire subscription.

.PARAMETER ExcludeResourceGroup
This cmdlet is ignore the resource groups that provided by this parameter. This parameter is optional.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup

This example is get the all empty resource groups in current subscription.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'ProjectA-RG','ProjectB-RG' | Remove-AzureRmResourceGroup -Force

In this example, it is to remove the all empty resource groups in the current subscription except the 'ProjectA-RG' and 'ProjectB-RG' resource groups. Those resource groups are not included to remove even if those were empty.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Get-AzureUtilNonAttachedManagedDisk

.LINK
Get-AzureUtilNonAttachedUnmanagedDisk
#>
function Get-AzureUtilEmptyResourceGroup
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup])]
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $ExcludeResourceGroup,

        [Parameter(Mandatory = $false)]
        [string[]] $ExcludeLocation
    )

    # Login check.
    try { [void] (Get-AzureRMContext -ErrorAction Stop) } catch { throw }

    # Normalize the exclude locations.
    if ($PSBoundParameters.ContainsKey('ExcludeLocation'))
    {
        $ExcludeLocation = GetNormalizedLocationName -ExcludeLocation $ExcludeLocation
    }

    # Create a array that contains non empty resource group names.
    $nonEmptyResourceGroupNmaes = @()
    Get-AzureRmResource |
        Group-Object -Property 'ResourceGroupName' -NoElement |
        ForEach-Object -Process { $nonEmptyResourceGroupNmaes += $_.Name }

    # Lookup the empty resource group name from all resource group name using non-empty resource group name array.
    Get-AzureRmResourceGroup |
        Where-Object -FilterScript {
            ($nonEmptyResourceGroupNmaes -notcontains $_.ResourceGroupName) -and
            ($ExcludeResourceGroup -notcontains $_.ResourceGroupName) -and
            ($ExcludeLocation -notcontains $_.Location)
        }
}

function GetNormalizedLocationName
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $ExcludeLocation
    )

    # Get the Azure locations.
    $azureLocations = Get-AzureRmLocation

    # Initialize normalized exclude locations.
    $normalizedExcludeLocations = @()

    # Normalize the exclude locations.
    $ExcludeLocation |
        ForEach-Object -Process {

            $unnormalizedLocation = $_

            # Get the Azure location by Location or DisplayName.
            $location = $azureLocations |
                Where-Object -FilterScript {
                    ($_.Location -eq $unnormalizedLocation) -or
                    ($_.DisplayName -eq $unnormalizedLocation)
                } |
                Select-Object -First 1

            if ($location -ne $null)
            {
                $normalizedExcludeLocations += $location.Location
            }
            else
            {
                throw ('The Azure location "{0}" is not recognized.' -f $unnormalizedLocation)
            }
        }

    $normalizedExcludeLocations
}
