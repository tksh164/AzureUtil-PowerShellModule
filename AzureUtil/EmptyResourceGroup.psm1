<#
.SYNOPSIS
Get the resource groups that not contains any resources.

.DESCRIPTION
Get the resource groups that not contains any resources.

.EXAMPLE
    Get-AzureUtilEmptyResourceGroup

This example is get the all empty resource groups.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule
#>
function Get-AzureUtilEmptyResourceGroup
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup])]
    param ()

    # Login check.
    try { [void](Get-AzureRMContext -ErrorAction Stop) } catch { throw }

    # Create a array that contains non empty resource group names.
    $nonEmptyResourceGroupNmaes = @()
    Get-AzureRmResource |
        Group-Object -Property 'ResourceGroupName' -NoElement |
        ForEach-Object -Process { $nonEmptyResourceGroupNmaes += $_.Name }

    # Lookup the empty resource group name from all resource group name using non-empty resource group name array.
    Get-AzureRmResourceGroup |
        Where-Object -FilterScript { $nonEmptyResourceGroupNmaes -notcontains $_.ResourceGroupName }
}
