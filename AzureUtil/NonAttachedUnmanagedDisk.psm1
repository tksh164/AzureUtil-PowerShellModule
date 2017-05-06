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
    PS C:\>$disks = Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'securitydata'
    PS C:\>$disks | Format-Table -Property @{ Label = 'Resource Group'; Expression = { $_.ResourceGroupName } },
                                           @{ Label = 'Storage Account'; Expression = { $_.StorageAccountName } },
                                           @{ Label = 'Location'; Expression = { $_.Location } },
                                           @{ Label = 'SKU'; Alignment = 'Left'; Expression = { $_.Sku.Name } },
                                           @{ Label = 'Container'; Expression = { $_.ContainerName } },
                                           @{ Label = 'VHD/Blob'; Expression = { $_.Name } },
                                           @{ Label = 'Size (GB)'; Expression = { [int] ($_.Length / 1GB) } },
                                           'LastModified'

    Resource Group Storage Account Location  SKU         Container VHD/Blob      Size (GB) LastModified
    -------------- --------------- --------  ---         --------- --------      --------- ------------
    ProjectA-RG    vm1sa1055       japaneast StandardLRS vhd       datadisk1.vhd       127 5/6/2017 11:05:14 AM +00:00
    ProjectB-RG    vm2sa1310       japaneast StandardLRS vhd       osdisk.vhd          127 5/5/2017 2:22:10 PM +00:00
    Test-RG        premsa          japaneast PremiumLRS  vhd       osdisk.vhd          127 5/5/2017 3:52:45 PM +00:00

In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the 'securitydata' resource groups. The results is formatted as table style in this example.

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
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [string[]] $ExcludeResourceGroup
    )

    # Login check.
    try { [void] (Get-AzureRMContext -ErrorAction Stop) } catch { throw }

    # Get the all attached VHD URIs from the VM configurations.
    Write-Verbose -Message ('Get all attached VHD URI...')
    $attachedVhdUris = GetAttachedVhdUri -ExcludeResourceGroup $ExcludeResourceGroup
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
                $storageAccount = $_
                $resourceGroupName = $storageAccount.ResourceGroupName
                $storageAccountName = $storageAccount.StorageAccountName
                Write-Verbose -Message ('Scanning SA:{0} in RG:{1}' -f $storageAccountName,$resourceGroupName)

                $storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName).Value | Select-Object -First 1
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
                                    [PSCustomObject] @{
                                        ResourceGroupName  = $resourceGroupName
                                        StorageAccountName = $storageAccountName
                                        Location           = $storageAccount.Location
                                        Sku                = $storageAccount.Sku
                                        ContainerName      = $containerName
                                        Name               = $_.Name
                                        ICloudBlob         = $_.ICloudBlob
                                        BlobType           = $_.BlobType
                                        Length             = $_.Length
                                        ContentType        = $_.ContentType
                                        LastModified       = $_.LastModified
                                        SnapshotTime       = $_.SnapshotTime
                                        ContinuationToken  = $_.ContinuationToken
                                        Context            = $_.Context
                                        StorageAccount     = $storageAccount
                                    }

                                    $nonAttachedVhdCount++
                                }
                            }
                    }

                Write-Verbose -Message ('Found {0} the non-attached VHD in SA:{1} in RG:{2}' -f $nonAttachedVhdCount,$storageAccountName,$resourceGroupName)
            }
        }
}

function GetAttachedVhdUri
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)]
        [string[]] $ExcludeResourceGroup
    )

    Get-AzureRmVM |
        ForEach-Object -Process {

            # Exclude the non target resource groups.
            if ($ExcludeResourceGroup -notcontains $_.ResourceGroupName)
            {
                $storageProfile = $_.StorageProfile

                # Attached VHD URI as OS disk.
                if ($storageProfile.OsDisk.Vhd -ne $null) { $storageProfile.OsDisk.Vhd.Uri }

                # All attached VHD URIs as data disks.
                if ($storageProfile.DataDisks.Vhd -ne $null) { $storageProfile.DataDisks.Vhd.Uri }
            }
        }
}
