<#
.SYNOPSIS
Get non-attached managed disks.

.DESCRIPTION
Get non-attached managed disks.

.PARAMETER ExcludeResourceGroup
This cmdlet is ignore this resource groups. It is not included in the processing target.

.EXAMPLE
    Get-AzureUtilNonAttachedManagedDisk

This example is get the all non-attached managed disk resources in the current subscription.

.EXAMPLE
    Get-AzureUtilNonAttachedManagedDisk -ExcludeResourceGroup 'Prod-RG','Test-RG'

This example is get the all non-attached managed disk resources in the current subscription except the disk resources in the "Prod-RG" and "Test-RG" resource groups.

.EXAMPLE
    Get-AzureUtilNonAttachedManagedDisk | Remove-AzureRmDisk -Verbose

This example is remove the all non-attached managed disk resources in the current subscription.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule
#>
function Get-AzureUtilNonAttachedManagedDisk
{
    [OutputType([Microsoft.Azure.Commands.Compute.Automation.Models.PSDiskList])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $ExcludeResourceGroup
    )

    # Login check.
    try { [void](Get-AzureRMContext -ErrorAction Stop) } catch { throw }

    # List non-attached managed disks.
    (Get-AzureRmDisk).ToArray() |
        Where-Object -FilterScript {
            ($ExcludeResourceGroup -notcontains $_.ResourceGroupName) -and ($_.OwnerId -eq $null)
        }
}
