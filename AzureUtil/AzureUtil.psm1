#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='AzureRM.Resources'; ModuleVersion='3.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Compute'; ModuleVersion='2.7.0' }
#requires -Modules @{ ModuleName='AzureRM.Storage'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='Azure.Storage'; ModuleVersion='2.6.0' }


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
    [OutputType([Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup])]
    [CmdletBinding()]
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


<#
.SYNOPSIS
Get non-attached non-managed disks (Blob).

.DESCRIPTION
Get non-attached non-managed disks (Blob).

.PARAMETER ExcludeResourceGroup
This cmdlet is ignore this resource groups. It is not included in the processing target.
 
.EXAMPLE
    Get-AzureUtilNonAttachedNonManagedDisk -Verbose

This example is get the all non-attached non-managed disks (blobs) in the current subscription.

.EXAMPLE
    Get-AzureUtilNonAttachedNonManagedDisk -ExcludeResourceGroup 'securitydata' -Verbose

This example is get the all non-attached non-managed disks (blobs) in the current subscription except the storage accounts in the "securitydata" resource group.

.EXAMPLE
    Get-AzureUtilNonAttachedNonManagedDisk -ExcludeResourceGroup 'securitydata' -Verbose | Remove-AzureStorageBlob -Verbose

This example is remove the all non-attached non-managed disks (blobs) in the current subscription except the storage accounts in the "securitydata" resource group.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule
#>
function Get-AzureUtilNonAttachedNonManagedDisk
{
    [OutputType([Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $ExcludeResourceGroup
    )

    # Login check.
    try { [void](Get-AzureRMContext -ErrorAction Stop) } catch { throw }

    # 
    # Get the all attached VHD URIs from the VM configurations.
    #

    Write-Verbose -Message ('Get all attached VHD URI...')

    $attachedVhdUris = Get-AzureRmVM |
        ForEach-Object -Process {

            # Exclude the non target resource groups.
            if ($ExcludeResourceGroup -notcontains $_.ResourceGroupName)
            {
                $storageProfile = $_.StorageProfile
                if ($storageProfile.OsDisk.Vhd -ne $null) { $storageProfile.OsDisk.Vhd.Uri }
                if ($storageProfile.DataDisks.Vhd -ne $null) { $storageProfile.DataDisks.Vhd.Uri }
            }
        }

    Write-Verbose -Message ('Found the {0} attached VHD in the current subscription.' -f $attachedVhdUris.Count)

    #
    # Enumerate the VHD blobs by scanning of all storage accounts.
    #

    Write-Verbose -Message ('Scanning all storage accounts.')

    Get-AzureRmStorageAccount |
        ForEach-Object -Process {

            # Exclude the non target resource groups.
            if ($ExcludeResourceGroup -notcontains $_.ResourceGroupName)
            {
                $resourceGroupName = $_.ResourceGroupName
                $storageAccountName = $_.StorageAccountName
                Write-Verbose -Message ('Scanning SA:{0} in RG:{1}' -f $storageAccountName,$resourceGroupName)

                $storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value[0]
                $context = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
                $nonAttachedVhdCount = 0

                # Get all containers in the storage account.
                Get-AzureStorageContainer -Context $context |
                    ForEach-Object -Process {
        
                        $containerName = $_.Name

                        # Get all blobs in the container.
                        Get-AzureStorageBlob -Context $context -Container $containerName |
                            ForEach-Object -Process {

                                $blobUri = $_.ICloudBlob.Uri.AbsoluteUri

                                # Verify that it is a non-attached VHD.
                                if ($blobUri.EndsWith('.vhd') -and ($attachedVhdUris -notcontains $blobUri))
                                {
                                    $_
                                    $nonAttachedVhdCount++
                                }
                            }
                    }

                Write-Verbose -Message ('Found {0} the non-attached VHD in SA:{1} in RG:{2}' -f $nonAttachedVhdCount,$storageAccountName,$resourceGroupName)
            }
        }
}
