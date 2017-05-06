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

.PARAMETER ExcludeLocation
This cmdlet is ignore the resource groups that has location provided by this parameter. This parameter is optional.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup

This example is get the all empty resource groups in current subscription.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup | Format-Table -Property 'ResourceGroupName','Location'

    ResourceGroupName Location 
    ----------------- -------- 
    ProjectA-RG       westus
    ProjectB-RG       eastus
    Prod-RG           japaneast
    Test-RG           japanwest

This example is get the all empty resource groups in current subscription.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup -ExcludeLocation 'japaneast','Japan West'

In this example, it is to get the all empty resource groups in the current subscription except the resource group's location is 'japaneast' or 'Japan West'.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'ProjectA-RG','ProjectB-RG' | Remove-AzureRmResourceGroup -Force

In this example, it is to remove the all empty resource groups in the current subscription except the 'ProjectA-RG' and 'ProjectB-RG' resource groups. Those resource groups are not included to remove even if those were empty.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'Prod-RG' -ExcludeLocation 'Japan West'

In this example, it is to get the all empty resource groups in the current subscription except the resource group that is name is 'Prod-RG' or location is 'Japan West'.

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
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [string[]] $ExcludeResourceGroup,

        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
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
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string[]] $ExcludeLocation
    )

    # Get the Azure locations.
    $azureLocations = Get-AzureRmLocation

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
                $location.Location
            }
            else
            {
                throw ('The Azure location "{0}" is not recognized.' -f $unnormalizedLocation)
            }
        }
}
