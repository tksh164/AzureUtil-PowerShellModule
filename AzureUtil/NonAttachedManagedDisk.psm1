Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Internal.Common.psm1' -Resolve)

<#
.SYNOPSIS
Get the managed disks that non-attached to any virtual machines from the entire subscription.

.DESCRIPTION
Get the managed disks that non-attached to any virtual machines from the entire subscription.

.PARAMETER ExcludeResourceGroup
This cmdlet is ignore the resource groups that provided by this parameter. This parameter is optional.

.EXAMPLE
    Get-AzureUtilNonAttachedManagedDisk

---- Example Description ----
In this example, it is to get the all non-attached managed disk resources in the current subscription.

.EXAMPLE
    Get-AzureUtilNonAttachedManagedDisk -ExcludeResourceGroup 'Prod-RG','Test-RG'

---- Example Description ----
In this example, it is to get the all non-attached managed disk resources in the current subscription except the disk resources in the "Prod-RG" and "Test-RG" resource groups.

.EXAMPLE
    Get-AzureUtilNonAttachedManagedDisk | Remove-AzureRmDisk -Verbose

---- Example Description ----
In this example, it is to remove the all non-attached managed disk resources in the current subscription.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Get-AzureUtilNonAttachedUnmanagedDisk

.LINK
Get-AzureUtilEmptyResourceGroup
#>
function Get-AzureUtilNonAttachedManagedDisk
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Compute.Automation.Models.PSDiskList])]
    param (
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [string[]] $ExcludeResourceGroup
    )

    # Login check.
    PreventUnloggedExecution

    # List non-attached managed disks.
    (Get-AzureRmDisk).ToArray() |
        Where-Object -FilterScript {
            ($ExcludeResourceGroup -notcontains $_.ResourceGroupName) -and ($_.OwnerId -eq $null)
        }
}
