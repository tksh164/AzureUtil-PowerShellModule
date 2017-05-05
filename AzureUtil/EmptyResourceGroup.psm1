#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Resources'; ModuleVersion='3.6.0' }

<#
.SYNOPSIS
Get the resource groups that not contains any resources from the entire subscription.

.DESCRIPTION
Get the resource groups that not contains any resources from the entire subscription.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup

This example is get the all empty resource groups in current subscription.

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
    param ()

    # Login check.
    try { [void] (Get-AzureRMContext -ErrorAction Stop) } catch { throw }

    # Create a array that contains non empty resource group names.
    $nonEmptyResourceGroupNmaes = @()
    Get-AzureRmResource |
        Group-Object -Property 'ResourceGroupName' -NoElement |
        ForEach-Object -Process { $nonEmptyResourceGroupNmaes += $_.Name }

    # Lookup the empty resource group name from all resource group name using non-empty resource group name array.
    Get-AzureRmResourceGroup |
        Where-Object -FilterScript { $nonEmptyResourceGroupNmaes -notcontains $_.ResourceGroupName }
}
