日本語の README は[こちら](README.ja-jp.md)です.

# AzureUtil PowerShell Module

[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/AzureUtil?color=0072c6&label=PowerShell%20Gallery&logo=PowerShell)](https://www.powershellgallery.com/packages/AzureUtil/)

This is a PowerShell module that is collection of utility cmdlets for Azure management operations.

## Install

This module available on the [PowerShell Gallery](https://www.powershellgallery.com/packages/AzureUtil/) page. You can install use the Install-Module cmdlet.

```PowerShell
PS > Install-Module -Name AzureUtil
```

## Cmdlets

### Resource Group Management

- [Get-AzureUtilEmptyResourceGroup cmdlet](#get-azureutilemptyresourcegroup-cmdlet)
    - This cmdlet is get the resource groups that not contains any resources from the entire subscription.

### Disk Storage Management

- [Get-AzureUtilNonAttachedManagedDisk cmdlet](#get-azureutilnonattachedmanageddisk-cmdlet)
    - This cmdlet gets the managed disks that non-attached to any virtual machines from the entire subscription.
- [Get-AzureUtilNonAttachedUnmanagedDisk cmdlet](#get-azureutilnonattachedunmanageddisk-cmdlet)
    - This cmdlet gets the unmanaged disks (VHDs/Blobs) that non-attached to any virtual machines from the entire subscription.

### ARM Template Creation

- [Set-AzureUtilArmTemplateFile cmdlet](#set-azureutilarmtemplatefile-cmdlet)
    - This cmdlet helping to ARM template making by upload the ARM template files on local filesystem to blob storage of Azure storage. When you making linked ARM template, this cmdlet is especially helpful.
- [Get-AzureUtilArmTemplateDeployUri cmdlet](#get-azureutilarmtemplatedeployuri-cmdlet)
    - This cmdlet building the URL that is access to custom deployment blade on Azure Portal. The URL allows deployment of your ARM template via Azure Portal.

### Azure REST API

- [Invoke-AzureUtilRestMethod cmdlet](#invoke-azureutilrestmethod-cmdlet)
    - This cmdlet sends HTTP and HTTPS requests to Azure REST API service endpoints without application registration on Azure AD. This cmdlet is very handy for Azure REST API quick testing.

### Others

- [Out-AzureUtilRdcManRdgFile cmdlet](#out-azureutilrdcmanrdgfile-cmdlet)
    - This cmdlet creates a ".rdg" file for Azure Windows virtual machine connection. The ".rdg" file is can open by [Remote Desktop Connection Manager](https://www.microsoft.com/en-us/download/details.aspx?id=44989).
- [Get-AzureUtilDatacenterIPRangeInfo cmdlet](#get-azureutildatacenteriprangeinfo-cmdlet)
    - This cmdlet provides quick lookup the Azure datacenter IP address range information from the specified public IP address.
- [Test-AzureUtilDatacenterIPRange cmdlet](#test-azureutildatacenteriprange-cmdlet)
    - This cmdlet provides quick test to see if the specified IP address is Azure's public IP address.

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

In this example, it is to get the all empty resource groups in the current subscription except the resource group's location is "japaneast" or "Japan West".

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeLocation 'japaneast','Japan West'
```

#### Example 4

In this example, it is to remove the all empty resource groups in the current subscription except the "ProjectA-RG" and "ProjectB-RG" resource groups. Those resource groups are not included to remove even if those were empty.

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'ProjectA-RG','ProjectB-RG' | Remove-AzureRmResourceGroup -Force
```

#### Example 5

In this example, it is to get the all empty resource groups in the current subscription except the resource group that is name is "Prod-RG" or location is "Japan West".

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

In this example, it is to get the all non-attached managed disk resources in the current subscription except the disk resources in the "Prod-RG" and "Test-RG" resource groups.

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

In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the "TemplateStore-RG" and "securitydata" resource groups.

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'TemplateStore-RG','securitydata' -Verbose
```

#### Example 3

In this example, it is to get the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the "securitydata" resource group. The results is formatted as table style in this example.

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
In this example, it is to remove the all non-attached unmanaged disks (VHDs/Blobs) in the current subscription except the storage accounts in the "securitydata" resource group.

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'securitydata' -Verbose | Remove-AzureStorageBlob -Verbose
```

## Out-AzureUtilRdcManRdgFile cmdlet
Create a ".rdg" file for Azure Windows virtual machine connection. The ".rdg" file is can open by [Remote Desktop Connection Manager](https://www.microsoft.com/en-us/download/details.aspx?id=44989).

### Parameters

Parameter Name    | Description
------------------|-------------------
ResourceGroupName | This cmdlet creates connection entries to the virtual machines contained in the resource groups specified by this parameter.
FilePath          | File path of the ".rdg" file to save. This parameter is optional. The default file path is "AzureVMConnection.rdg" under the current folder.
RootGroupName     | Display name for the root node of the ".rdg" file. This parameter is optional. The default display name is "AzureVMConnections".

### Examples

#### Example 1
This example is creates ".rdg" file in current folder. The ".rdg" file contains connections for Azure Windows virtual machine in resource group "Prod-RG" and "Dev-RG".

```PowerShell
PS > Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG'
```

#### Example 2
This example is creates ".rdg" file as "C:\NewProject.rdg". The .rdg file contains connections for Azure Windows virtual machine in resource group "Prod-RG" and "Dev-RG". The root node name of connections is "NewProjectVMs".

```PowerShell
PS > Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG' -FilePath 'C:\NewProject.rdg' -RootGroupName 'NewProjectVMs'
```

## Invoke-AzureUtilRestMethod cmdlet
This cmdlet sends HTTP and HTTPS requests to Azure REST API service endpoints without application registration on Azure AD. This cmdlet is very handy for Azure REST API quick testing.

### Parameters

Parameter Name    | Description
------------------|-------------------
Method            | Specifies the method used for the web request. This parameter is optional. The default value is "Get".
Uri               | Specifies the URI of the Azure REST API to which the web request is sent.
AdditionalHeaders | Specifies the additional headers of the web request. Enter a hash table or dictionary. This parameter is optional.
ContentType       | Specifies the content type of the web request. This parameter is optional. The default value is "application/json".
Body              | Specifies the body of the web request. The body is the content of the web request that follows the headers. This parameter is optional.

### Examples

#### Example 1
In this example, get the "Sample-RG" resource group information using Azure REST API. You can find this REST API details at [here](https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_Get).

```PowerShell
PS C:\> $result = Invoke-AzureUtilRestMethod -Uri 'https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'

PS C:\> $result.Content
{"id":"/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/Sample-RG","name":"Sample-RG","location":"japaneast","properties":{"provisioningState":"Succeeded"}}

PS C:\> ConvertFrom-Json $result.Content | Format-Custom
class PSCustomObject
{
    id = /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/Sample-RG
    name = Sample-RG
    location = japaneast
    properties = 
    class PSCustomObject
    {
        provisioningState = Succeeded
    }
}
```

#### Example 2
In this example, checks whether the "Sample-RG" resource group exists using Azure REST API. This REST API is return the 204 as HTTP status code if that resource group is exists. You can find this REST API details at [here](https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_CheckExistence).

```PowerShell
PS C:\> $result = Invoke-AzureUtilRestMethod -Method Head -Uri 'https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'

PS C:\> $result.StatusCode
204
```

#### Example 3
In this example, capture the "Sample-RG" resource group as a template. You can find this REST API details at [here](https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_ExportTemplate).

```PowerShell
PS C:\> $body = @'
{
    "resources": [ "*" ],
    "options": "IncludeParameterDefaultValue, IncludeComments"
}
'@

PS C:\> $result = Invoke-AzureUtilRestMethod -Method Post -Uri 'https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG/exportTemplate?api-version=2017-05-10' -Body $body

PS C:\> $result.Content
{"template":{"$schema":"https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#","contentVersion":"1.0.0.0","parameters":{"storageAccounts_abcd1234_name":{"defaultValue":"abcd1234","type":"String"}},"variables":{},"resources":[{"comments":"Generalized from resource: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/sample-rg/providers/Microsoft.Storage/storageAccounts/abcd1234'.","type":"Microsoft.Storage/storageAccounts","sku":{"name":"Standard_LRS","tier":"Standard"},"kind":"Storage","name":"[parameters('storageAccounts_abcd1234_name')]","apiVersion":"2016-01-01","location":"japaneast","tags":{},"scale":null,"properties":{},"dependsOn":[]}]}}
```

#### Example 4
In this example, get the "Sample-RG" resource group information using Azure REST API with abbreviated URI. This cmdlet is automaticaly prepend "https://management.azure.com" to URI if Uri parameter starts with "/subscriptions/".

```PowerShell
PS C:\> Invoke-AzureUtilRestMethod -Uri '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'
```

## Get-AzureUtilDatacenterIPRangeInfo cmdlet
This cmdlet provides quick lookup the Azure datacenter IP address range information from the specified public IP address.

### Parameters

Parameter Name | Description
---------------|-------------------
IPAddress      | Specify the public IP address you want to check.
XmlFilePath    | Specify the file path of Azure datacenter IP address range XML file. This parameter is optional. The latest XML file is can download from [here](https://www.microsoft.com/en-us/download/details.aspx?id=41653).
IgnoreCache    | If you specify this switch parameter, the cached IP range data will not be used and the latest IP range XML will always be downloaded. By default, this cmdlet is cache the downloaded IP range XML. This parameter is ignored if this parameter and the XmlFilePath parameter are specified at the same time.

### Examples

#### Example 1
In this example, get the region and IP address range information of the public IP address "13.73.24.96".

```PowerShell
PS > Get-AzureUtilDatacenterIPRangeInfo -IPAddress '13.73.24.96'

IPAddress   RegionName IPRange
---------   ---------- -------
13.73.24.96 japaneast  13.73.0.0/19
```

#### Example 2
In this example, get the region and IP address range information of the public IPs via piping.

```PowerShell
PS > '13.73.24.96','40.112.124.10','13.88.13.238' | Get-AzureUtilDatacenterIPRangeInfo

IPAddress     RegionName IPRange
---------     ---------- -------
13.73.24.96   japaneast  13.73.0.0/19
40.112.124.10 europewest 40.112.124.0/24
13.88.13.238  uswest     13.88.0.0/19
```

#### Example 3
In this example, get the region and IP address range information of the public IP address "13.73.24.96" using the local XML file. You can get the region and IP address range information on offline if use the local XML file.

```PowerShell
PS > $xmlFilePath = 'C:\PublicIPs_20170616.xml'

PS > '13.73.24.96' | Get-AzureUtilDatacenterIPRangeInfo -XmlFilePath $xmlFilePath

IPAddress   RegionName IPRange
---------   ---------- -------
13.73.24.96 japaneast  13.73.0.0/19
```

## Test-AzureUtilDatacenterIPRange cmdlet
This cmdlet provides quick test to see if the specified IP address is Azure's public IP address.

### Parameters

Parameter Name | Description
---------------|-------------------
IPAddress      | Specify the public IP address you want to check.
XmlFilePath    | Specify the file path of Azure datacenter IP address range XML file. This parameter is optional. The latest XML file is can download from [here](https://www.microsoft.com/en-us/download/details.aspx?id=41653).
IgnoreCache    | If you specify this switch parameter, the cached IP range data will not be used and the latest IP range XML will always be downloaded. By default, this cmdlet is cache the downloaded IP range XML. This parameter is ignored if this parameter and the XmlFilePath parameter are specified at the same time.

### Examples

#### Example 1
In this example, test the public IP address "13.73.24.96" then confirmed it is Azure's public IP address.

```PowerShell
PS > Test-AzureUtilDatacenterIPRange -IPAddress '13.73.24.96'
True
```

#### Example 2
In this example, test the public IP address "40.112.124.10" using the local XML file then confirmed it is Azure's public IP address.

```PowerShell
PS > $xmlFilePath = 'C:\PublicIPs_20170616.xml'

PS > Test-AzureUtilDatacenterIPRange -IPAddress '40.112.124.10' -XmlFilePath $xmlFilePath 
True
```

## Set-AzureUtilArmTemplateFile cmdlet
This cmdlet helping to ARM template making by upload the ARM template files on local filesystem to blob storage of Azure storage. When you making linked ARM template, this cmdlet is especially helpful.

### Parameters

Parameter Name     | Description
-------------------|-------------------
LocalBasePath      | The path of the folder on local filesystem that contains the ARM templates.
StorageAccountName | The storage account name to upload the ARM templates.
ResourceGroupName  | The resource group name that it contains the storage account of StorageAccountName parameter.
StorageAccountKey  | The storage account key for storage account of StorageAccountName parameter.
ContainerName      | The container name to upload the ARM templates. This parameter is optional. Default container name is 'armtemplate'.
Force              | This switch parameter is optional. If you use this switch, overwrite the existing ARM templates in the container.

### Examples

#### Example 1
This example is upload the ARM template files from under 'C:\TemplateWork' folder with recursive. You need execute Login-AzureRmAccount cmdlet before execute this cmdlet because this example use ResourceGroupName parameter.

```PowerShell
PS > Set-AzureUtilArmTemplateFile -LocalBasePath 'C:\TemplateWork' -StorageAccountName 'abcd1234' -ResourceGroupName 'ArmTemplateDev-RG' -Force
```

#### Example 2
This example is upload the ARM template files from under 'C:\TemplateWork' folder with recursive.

```PowerShell
PS > Set-AzureUtilArmTemplateFile -LocalBasePath 'C:\TemplateWork' -StorageAccountName 'abcd1234' -StorageAccountKey 'dWLe7OT3P0HevzLeKzRlk4j4eRws7jHStp0C4XJtQJhuH4p5EOP+vLcK1w8sZ3QscGLy50DnOzQoiUbpzXD9Jg==' -Force
```

## Get-AzureUtilArmTemplateDeployUri cmdlet
This cmdlet building the URL that is access to custom deployment blade on Azure Portal. The URL allows deployment of your ARM template via Azure Portal.

### Parameters

Parameter Name  | Description
----------------|-------------------
TemplateUri     | The URI of your ARM template.
ShowDeployBlade | This switch parameter is optional. If you use this switch, this cmdlet open the URL by your browser.

### Examples

#### Example 1
This example is build the URL of custom deployment blade from your ARM template URL.

```PowerShell
PS > Get-AzureUtilArmTemplateDeployUri -TemplateUri 'https://abcd1234.blob.core.windows.net/armtemplate/main.json'

Uri
---
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fabcd1234.blob.core.windows.net%2Farmtemplate%2Fmain.json
```

#### Example 2
This example is build the URL of custom deployment blade from your ARM template URL and open that URL by your browser.

```PowerShell
PS > Get-AzureUtilArmTemplateDeployUri -TemplateUri 'https://abcd1234.blob.core.windows.net/armtemplate/main.json' -ShowDeployBlade
```

## Release Notes

### [1.0.6](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.6)
- Fixed multi VM handling issue of Out-AzureUtilRdcManRdgFile cmdlet.
- Improved the Get-AzureUtilDatacenterIPRangeInfo cmdlet and Test-AzureUtilDatacenterIPRange cmdlet.

### [1.0.5](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.5)
- Marged [AzureArmTemplateHelper Module](https://github.com/tksh164/AzureArmTemplateHelper-PowerShellModule) version 1.0.3
- Fixed the exception in Get-AzureUtilNonAttachedManagedDisk cmdlet.
- Fixed the cookie popup in Get-AzureUtilDatacenterIPRangeInfo cmdlet and Test-AzureUtilDatacenterIPRange cmdlet.
- Updated help.
- Updated README.
- Added Japanese README.

### [1.0.4](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.4)
- Added Invoke-AzureUtilRestMethod cmdlet.
- Added Get-AzureUtilDatacenterIPRangeInfo cmdlet.
- Added Test-AzureUtilDatacenterIPRange cmdlet.
- Updated required version of Azure PowerShell modules.
- Improved login check.
- Updated help.
- Some fixes.

### [1.0.3](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.3)
- Some fixes.

### [1.0.2](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.2)
- Added Out-AzureUtilRdcManRdgFile cmdlet.
- Changed cmdlet name from "Get-AzureUtilNonAttachedNonManagedDisk" to "Get-AzureUtilNonAttachedUnmanagedDisk".
- Added some new parameters.
- Refactored the module implementation.
- Updated help.

### 1.0.1
- Some fixes.

### 1.0.0
- Initial release.


## License
This project is licensed under the [MIT](https://github.com/tksh164/AzureUtil-PowerShellModule/blob/master/LICENSE) license.
