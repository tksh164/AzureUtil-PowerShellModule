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
function Get-AzureUtilNonAttachedUnmanagedDisk
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
