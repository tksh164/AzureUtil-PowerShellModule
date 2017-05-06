#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Compute'; ModuleVersion='2.7.0' }
#requires -Modules @{ ModuleName='Azure.Storage'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Storage'; ModuleVersion='2.6.0' }

<#
.SYNOPSIS
Get the unmanaged disks (VHDs/Blobs) that non-attached to any virtual machines from the entire subscription.

.DESCRIPTION
Get the unmanaged disks (VHDs/Blobs) that non-attached to any virtual machines from the entire subscription.

.PARAMETER ExcludeResourceGroup
This cmdlet is ignore the resource groups that provided by this parameter. This parameter is optional.

.EXAMPLE
    Get-AzureUtilNonAttachedUnmanagedDisk -Verbose

In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription.

.EXAMPLE
    Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'TemplateStore-RG','securitydata' -Verbose

In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the 'TemplateStore-RG' and 'securitydata' resource groups.

.EXAMPLE
    Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'securitydata' -Verbose | Remove-AzureStorageBlob -Verbose

In this example, it is to remove the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the 'securitydata' resource group.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Get-AzureUtilNonAttachedManagedDisk

.LINK
Get-AzureUtilEmptyResourceGroup
#>
function Get-AzureUtilNonAttachedUnmanagedDisk
{
    [CmdletBinding()]
    [OutputType([Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageBlob])]
    param (
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [string[]] $ExcludeResourceGroup
    )

    # Login check.
    try { [void] (Get-AzureRMContext -ErrorAction Stop) } catch { throw }

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
