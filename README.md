# AzureUtil PowerShell Module
Utility cmdlets for Azure management operations.

# AzureArmTemplateHelper PowerShell Module
This is a PowerShell module that is collection of utility cmdlets for Azure management operations.

- [Get-AzureUtilEmptyResourceGroup cmdlet](#get-azureutilemptyresourcegroup-cmdlet)
- [Get-AzureUtilNonAttachedManagedDisk cmdlet](#get-azureutilnonattachedmanageddisk-cmdlet)
- [Get-AzureUtilNonAttachedUnmanagedDisk cmdlet](#get-azureutilnonattachedunmanageddisk-cmdlet)
- [Out-AzureUtilRdcManRdgFile cmdlet](#out-azureutilrdcmanrdgfile-cmdlet)

## Install
This module available on the [PowerShell Gallery](https://www.powershellgallery.com/packages/AzureUtil/) page. You can install use the Install-Module cmdlet.

```PowerShell
PS > Install-Module -Name AzureUtil
```

## Get-AzureUtilEmptyResourceGroup cmdlet
This cmdlet is get the resource groups that not contains any resources from the entire subscription.

### Parameters

Parameter Name       | Description
---------------------|-------------------
ExcludeResourceGroup | This cmdlet is ignore the resource groups that provided by this parameter. This parameter is optional.
ExcludeLocation      | This cmdlet is ignore the resource groups that has location provided by this parameter. This parameter is optional.

### Examples

#### Example 1
This example is get the all empty resource groups in current subscription.

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup
```

#### Example 2
This example is get the all empty resource groups in current subscription.

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup | Format-Table -Property 'ResourceGroupName','Location'

ResourceGroupName Location 
----------------- -------- 
ProjectA-RG       westus
ProjectB-RG       eastus
Prod-RG           japaneast
Test-RG           japanwest
```

#### Example 3
In this example, it is to get the all empty resource groups in the current subscription except the resource group's location is 'japaneast' or 'Japan West'.

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeLocation 'japaneast','Japan West'
```

#### Example 4
In this example, it is to remove the all empty resource groups in the current subscription except the 'ProjectA-RG' and 'ProjectB-RG' resource groups. Those resource groups are not included to remove even if those were empty.

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'ProjectA-RG','ProjectB-RG' | Remove-AzureRmResourceGroup -Force
```

#### Example 5
In this example, it is to get the all empty resource groups in the current subscription except the resource group that is name is 'Prod-RG' or location is 'Japan West'.

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'Prod-RG' -ExcludeLocation 'Japan West'
```

## Get-AzureUtilNonAttachedManagedDisk cmdlet
Get the managed disks that non-attached to any virtual machines from the entire subscription.

### Parameters

Parameter Name       | Description
---------------------|-------------------
ExcludeResourceGroup | This cmdlet is ignore the resource groups that provided by this parameter. This parameter is optional.

### Examples

#### Example 1
In this example, it is to get the all non-attached managed disk resources in the current subscription.

```PowerShell
PS > Get-AzureUtilNonAttachedManagedDisk
```

#### Example 2
In this example, it is to get the all non-attached managed disk resources in the current subscription except the disk resources in the 'Prod-RG' and 'Test-RG' resource groups.

```PowerShell
PS > Get-AzureUtilNonAttachedManagedDisk -ExcludeResourceGroup 'Prod-RG','Test-RG'
```

#### Example 3
In this example, it is to remove the all non-attached managed disk resources in the current subscription.

```PowerShell
PS > Get-AzureUtilNonAttachedManagedDisk | Remove-AzureRmDisk -Verbose
```

## Get-AzureUtilNonAttachedUnmanagedDisk cmdlet
Get the unmanaged disks (VHDs/Blobs) that non-attached to any virtual machines from the entire subscription.

### Parameters

Parameter Name       | Description
---------------------|-------------------
ExcludeResourceGroup | This cmdlet is ignore the resource groups that provided by this parameter. This parameter is optional.

### Examples

#### Example 1
In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription.

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -Verbose
```

#### Example 2
In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the 'TemplateStore-RG' and 'securitydata' resource groups.

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'TemplateStore-RG','securitydata' -Verbose
```

#### Example 3
In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the 'securitydata' resource groups. The results is formatted as table style in this example.

```PowerShell
PS > $disks = Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'securitydata'
PS > $disks | Format-Table -Property @{ Label = 'Resource Group'; Expression = { $_.ResourceGroupName } },
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
```

#### Example 4
In this example, it is to remove the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the 'securitydata' resource group.

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'securitydata' -Verbose | Remove-AzureStorageBlob -Verbose
```

## Out-AzureUtilRdcManRdgFile cmdlet
Create a .rdg file for Azure Windows virtual machine connection. The .rdg file is can open by [Remote Desktop Connection Manager](https://www.microsoft.com/en-us/download/details.aspx?id=44989).

### Parameters

Parameter Name    | Description
------------------|-------------------
ResourceGroupName | This cmdlet creates connection entries to the virtual machines contained in the resource groups specified by this parameter.
FilePath          | File path of the .rdg file to save. This parameter is optional. The default file path is 'AzureVMConnection.rdg' under the current folder.
RootGroupName     | Display name for the root node of the .rdg file. This parameter is optional. The default display name is 'AzureVMConnections'.

### Examples

#### Example 1
This example is creates .rdg file in current folder. The .rdg file contains connections for Azure Windows virtual machine in resource group Prod-RG and Dev-RG.

```PowerShell
PS > Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG'
```

#### Example 2
This example is creates .rdg file as 'C:\NewProject.rdg'. The .rdg file contains connections for Azure Windows virtual machine in resource group Prod-RG and Dev-RG. The root node name of connections is 'NewProjectVMs'.

```PowerShell
PS > Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG' -FilePath 'C:\NewProject.rdg' -RootGroupName 'NewProjectVMs'
```

## Release Notes

### [1.0.2](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.2)
- Initial release.
