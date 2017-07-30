# AzureUtil PowerShell モジュール
これは Azure 管理操作のためのユーティリティ コマンドレットを集めた PowerShell モジュールです。

## インストール
このモジュールは [PowerShell Gallery](https://www.powershellgallery.com/packages/AzureUtil/) にあります。Install-Module コマンドレットを使用してインストールすることができます。

```PowerShell
PS > Install-Module -Name AzureUtil
```

## コマンドレット

### リソース グループ管理
- [Get-AzureUtilEmptyResourceGroup コマンドレット](#get-azureutilemptyresourcegroup-コマンドレット)
    - このコマンドレットは、サブスクリプション内にある 1 個もリソースを含まなない空のリソース グループを取得します。

### ディスク ストレージ管理
- [Get-AzureUtilNonAttachedManagedDisk コマンドレット](#get-azureutilnonattachedmanageddisk-コマンドレット)
    - このコマンドレットは、サブスクリプション内にあるどの仮想マシンにも接続されていない管理ディスクを取得します。
- [Get-AzureUtilNonAttachedUnmanagedDisk コマンドレット](#get-azureutilnonattachedunmanageddisk-コマンドレット)
    - このコマンドレットは、サブスクリプション内にあるどの仮想マシンにも接続されていない非管理ディスク (VHD/Blob) を取得します。

### ARM テンプレート作成
- [Set-AzureUtilArmTemplateFile コマンドレット](#set-azureutilarmtemplatefile-コマンドレット)
    - このコマンドレットはローカル ファイルシステム上の ARM テンプレート ファイルを Azure ストレージの BLOB ストレージにアップロードすることで ARM テンプレート作成を支援します。このコマンドレットは、リンクされた ARM テンプレートを作成する場合に特に便利です。
- [Get-AzureUtilArmTemplateDeployUri コマンドレット](#get-azureutilarmtemplatedeployuri-コマンドレット)
    - このコマンドレットは Azure ポータル上のカスタム デプロイ ブレードにアクセスするための URL を作成します。その URL は ARM テンプレートを Azure ポータルからデプロイ可能にします。

### Azure REST API
- [Invoke-AzureUtilRestMethod コマンドレット](#invoke-azureutilrestmethod-コマンドレット)
    - このコマンドレットは、Azure AD へのアプリケーション登録無しで、Azure REST API サービス エンドポイントに HTTP や HTTPS のリクエストを送信します。Azure REST API を手早く試す際にとても便利です。

### その他
- [Out-AzureUtilRdcManRdgFile コマンドレット](#out-azureutilrdcmanrdgfile-コマンドレット)
    - このコマンドレットは、Azure 仮想マシンに接続するための ".rdg" ファイルを作成します。".rdg" ファイルは [Remote Desktop Connection Manager](https://www.microsoft.com/en-us/download/details.aspx?id=44989) で開くことができます。
- [Get-AzureUtilDatacenterIPRangeInfo コマンドレット](#get-azureutildatacenteriprangeinfo-コマンドレット)
    - このコマンドレットは、指定したパブリック IP アドレスから Azure データセンターの IP アドレス範囲情報を素早く見つけることができます。
- [Test-AzureUtilDatacenterIPRange コマンドレット](#test-azureutildatacenteriprange-コマンドレット)
    - このコマンドレットは、指定した IP アドレスが Azure のパブリック IP アドレスであるか素早くテストすることができます。

## Get-AzureUtilEmptyResourceGroup コマンドレット
このコマンドレットは、サブスクリプション内にある 1 個もリソースを含まなない空のリソース グループを取得します。

### パラメーター

| パラメーター名              | 説明                                       |
| -------------------- | ---------------------------------------- |
| ExcludeResourceGroup | このパラメーターで指定されたリソース グループをこのコマンドレットは無視します。このパラメーターは省略可能です。 |
| ExcludeLocation      | このパラメーターで指定された場所にあるリソース グループをこのコマンドレットは無視します。このパラメーターは省略可能です。 |

### 例

#### 例 1
この例は、現在のサブスクリプション内のすべての空リソース グループを取得しています。

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup
```

#### 例 2
この例は、現在のサブスクリプション内のすべての空リソース グループを取得しています。

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup | Format-Table -Property 'ResourceGroupName','Location'

ResourceGroupName Location 
----------------- -------- 
ProjectA-RG       westus
ProjectB-RG       eastus
Prod-RG           japaneast
Test-RG           japanwest
```

#### 例 3
この例では、現在のサブスクリプション内でリソース グループの場所が "japaneast" と "Japan West" であるリソース グループを除いたすべての空リソース グループを取得しています。

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeLocation 'japaneast','Japan West'
```

#### 例 4
この例では、現在のサブスクリプション内でリソース グループ "ProjectA-RG" と "ProjectB-RG" を除いたすべての空リソース グループを削除しています。それらのリソース グループは空であったとしても削除されません。

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'ProjectA-RG','ProjectB-RG' | Remove-AzureRmResourceGroup -Force
```

#### Example 5
この例では、現在のサブスクリプション内でリソース グループの名前が "Prod-RG"、または場所が "Japan West" であるリソース グループを除いたすべての空リソース グループを取得しています。

```PowerShell
PS > Get-AzureUtilEmptyResourceGroup -ExcludeResourceGroup 'Prod-RG' -ExcludeLocation 'Japan West'
```

## Get-AzureUtilNonAttachedManagedDisk コマンドレット
このコマンドレットは、サブスクリプション内にあるどの仮想マシンにも接続されていない管理ディスクを取得します。

### パラメーター

| パラメーター名              | 説明                                       |
| -------------------- | ---------------------------------------- |
| ExcludeResourceGroup | このパラメーターで指定されたリソース グループをこのコマンドレットは無視します。このパラメーターは省略可能です。 |

### 例

#### 例 1
この例では、現在のサブスクリプション内のすべての接続されていない管理ディスクを取得しています。

```PowerShell
PS > Get-AzureUtilNonAttachedManagedDisk
```

#### 例 2
この例では、現在のサブスクリプション内でリソース グループ "Prod-RG" と "Test-RG" 内にあるディスク リソースを除いたすべての接続されていない管理ディスクを取得しています。

```PowerShell
PS > Get-AzureUtilNonAttachedManagedDisk -ExcludeResourceGroup 'Prod-RG','Test-RG'
```

#### 例 3
この例では、現在のサブスクリプション内のすべての接続されていない管理ディスクを削除しています。

```PowerShell
PS > Get-AzureUtilNonAttachedManagedDisk | Remove-AzureRmDisk -Verbose
```

## Get-AzureUtilNonAttachedUnmanagedDisk コマンドレット
このコマンドレットは、サブスクリプション内にあるどの仮想マシンにも接続されていない非管理ディスク (VHD/Blob) を取得します。

### パラメーター

| パラメーター名              | 説明                                       |
| -------------------- | ---------------------------------------- |
| ExcludeResourceGroup | このパラメーターで指定されたリソース グループをこのコマンドレットは無視します。このパラメーターは省略可能です。 |

### 例

#### 例 1
この例では、現在のサブスクリプション内のすべての接続されていない非管理ディスク (VHD/Blob) を取得しています。

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -Verbose
```

#### 例 2
この例では、現在のサブスクリプション内でリソース グループ "TemplateStore-RG" と "securitydata" 内にあるストレージ アカウントを除いたすべての接続されていない非管理ディスク (VHD/Blob) を取得しています。

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'TemplateStore-RG','securitydata' -Verbose
```

#### 例 3
この例では、現在のサブスクリプション内でリソース グループ "securitydata" 内にあるストレージ アカウントを除いたすべての接続されていない非管理ディスク (VHD/Blob) を取得しています。この例では、取得した結果をテーブル形式にフォーマットしています。

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

#### 例 4
この例では、現在のサブスクリプション内でリソース グループ "securitydata" 内にあるストレージ アカウントを除いたすべての接続されていない非管理ディスク (VHD/Blob) を削除しています。

```PowerShell
PS > Get-AzureUtilNonAttachedUnmanagedDisk -ExcludeResourceGroup 'securitydata' -Verbose | Remove-AzureStorageBlob -Verbose
```

## Out-AzureUtilRdcManRdgFile コマンドレット
このコマンドレットは、Azure 仮想マシンに接続するための ".rdg" ファイルを作成します。".rdg" ファイルは [Remote Desktop Connection Manager](https://www.microsoft.com/en-us/download/details.aspx?id=44989) で開くことができます。

### パラメーター

| パラメーター名           | 説明                                       |
| ----------------- | ---------------------------------------- |
| ResourceGroupName | このコマンドレットはこのパラメーターで指定されたリソース グループ内に含まれる仮想マシンへの接続エントリを作成します。 |
| FilePath          | ".rdg" ファイル保存するパスです。このパラメーターは省略可能です。既定のパスは現在のフォルダー内の "AzureVMConnection.rdg" です。 |
| RootGroupName     | ".rdg" ファイルのルート ノードの表示名です。このパラメーターは省略可能です。既定の表示名は "AzureVMConnections" です。 |

### 例

#### 例 1
この例は現在のフォルダーに ".rdg" ファイルを作成します。その ".rdg" ファイルには、リソース グループ "Prod-RG" と "Dev-RG" 内の Azure Windows 仮想マシンの接続が含まれています。

```PowerShell
PS > Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG'
```

#### 例 2
この例は、"C:\NewProject.rdg" に ".rdg" ファイルを作成します。その ".rdg" ファイルには、リソース グループ "Prod-RG" と "Dev-RG" 内の Azure Windows 仮想マシンの接続が含まれています。接続のルート ノード名は "NewProjectVMs" です。

```PowerShell
PS > Out-AzureUtilRdcManRdgFile -ResourceGroupName 'Prod-RG','Dev-RG' -FilePath 'C:\NewProject.rdg' -RootGroupName 'NewProjectVMs'
```

## Invoke-AzureUtilRestMethod コマンドレット
このコマンドレットは、構造化データを返す Azure REST API サービス エンドポイントに HTTP や HTTPS のリクエストを送信します。

### パラメーター

| パラメーター名           | 説明                                       |
| ----------------- | ---------------------------------------- |
| Method            | Web リクエストに使用するメソッドを指定します。このパラメーターは省略可能です。既定の値は "Get" です。 |
| Uri               | Web リクエストを送信する Azure REST API の URI を指定します。 |
| AdditionalHeaders | Web リクエストの追加ヘッダーを指定します。このパラメーターは省略可能です。ハッシュテーブル、または dictionary を入力します。 |
| ContentType       | Web リクエストのコンテンツ タイプを指定します。このパラメーターは省略可能です。既定の値は "application/json" です。 |
| Body              | Web リクエストの本文です。本文は Web リクエストのコンテンツでヘッダーの後に続きます。このパラメーターは省略可能です。 |

### 例

#### 例 1
この例では、Azure REST API を使用して "Sample-RG" リソース グループの情報を取得しています。この REST API の詳細は [ここ](https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_Get) です。

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

#### 例 2
この例では、Azure REST API を使用して、"Sample-RG" リソース グループが存在するかどうかを確認しています。リソース グループが存在する場合、この REST API は HTTP ステータスとして 204 を返します。この REST API の詳細は [ここ](https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_CheckExistence) です。

```PowerShell
PS C:\> $result = Invoke-AzureUtilRestMethod -Method Head -Uri 'https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'

PS C:\> $result.StatusCode
204
```

#### 例 3
この例では、"Sample-RG" リソース グループのテンプレートを取得しています。この REST API の詳細は [ここ](https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_ExportTemplate) です。

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

#### 例 4
この例では、Azure REST API の省略した URI を使用して、"Sample-RG" リソース グループの情報を取得しています。Uri パラメーターが "/subscriptions/" で始まる場合、このコマンドレットは自動的に "https://management.azure.com" を先頭に追加します。

```PowerShell
PS C:\> Invoke-AzureUtilRestMethod -Uri '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'
```

## Get-AzureUtilDatacenterIPRangeInfo コマンドレット
このコマンドレットは、指定したパブリック IP アドレスから Azure データセンターの IP アドレス範囲情報を素早く見つけることができます。

### パラメーター

| パラメーター名     | 説明                                       |
| ----------- | ---------------------------------------- |
| IPAddress   | 確認したいパブリック IP アドレスを指定します。                |
| XmlFilePath | Azure データセンター IP アドレス範囲 XML ファイルのファイル パスを指定します。このパラメーターは省略可能です。最新の XML ファイルは [ここ](https://www.microsoft.com/en-us/download/details.aspx?id=41653) からダウンロードできます。 |

### 例

#### 例 1
この例では、パブリック IP アドレス "13.73.24.96" のリージョンと IP アドレス範囲情報を取得しています。

```PowerShell
PS > Get-AzureUtilDatacenterIPRangeInfo -IPAddress '13.73.24.96'

IPAddress   RegionName IPRange
---------   ---------- -------
13.73.24.96 japaneast  13.73.0.0/19
```

#### 例 2
この例では、パイプしたパブリック IP アドレスのリージョンと IP アドレス範囲情報を取得しています。

```PowerShell
PS > '13.73.24.96','40.112.124.10','13.88.13.238' | Get-AzureUtilDatacenterIPRangeInfo

IPAddress     RegionName IPRange
---------     ---------- -------
13.73.24.96   japaneast  13.73.0.0/19
40.112.124.10 europewest 40.112.124.0/24
13.88.13.238  uswest     13.88.0.0/19
```

#### 例 3
この例では、ローカルにある XML ファイルを使用して、パブリック IP アドレス "13.73.24.96" のリージョンと IP アドレス範囲情報を取得しています。ローカル XML ファイルを使用すれば、オフライン環境でもリージョンと IP アドレス範囲情報を取得できます。

```PowerShell
PS > $xmlFilePath = 'C:\PublicIPs_20170616.xml'

PS > '13.73.24.96' | Get-AzureUtilDatacenterIPRangeInfo -XmlFilePath $xmlFilePath

IPAddress   RegionName IPRange
---------   ---------- -------
13.73.24.96 japaneast  13.73.0.0/19
```

## Test-AzureUtilDatacenterIPRange コマンドレット
このコマンドレットは、指定した IP アドレスが Azure のパブリック IP アドレスであるか素早くテストすることができます。

### パラメーター

| パラメーター名     | 説明                                       |
| ----------- | ---------------------------------------- |
| IPAddress   | 確認したいパブリック IP アドレスを指定します。                |
| XmlFilePath | Azure データセンター IP アドレス範囲 XML ファイルのファイル パスを指定します。このパラメーターは省略可能です。最新の XML ファイルは [ここ](https://www.microsoft.com/en-us/download/details.aspx?id=41653) からダウンロードできます。 |

### 例

#### 例 1
この例では、パブリック IP アドレス "13.73.24.96" をテストし、それが Azure のパブリック IP アドレスであることを確認しています。

```PowerShell
PS > Test-AzureUtilDatacenterIPRange -IPAddress '13.73.24.96'
True
```

#### 例 2
この例では、ローカルにある XML ファイルを使用して、パブリック IP アドレス "40.112.124.10" をテストし、それが Azure のパブリック IP アドレスであることを確認しています。

```PowerShell
PS > $xmlFilePath = 'C:\PublicIPs_20170616.xml'

PS > Test-AzureUtilDatacenterIPRange -IPAddress '40.112.124.10' -XmlFilePath $xmlFilePath 
True
```

## Set-AzureUtilArmTemplateFile コマンドレット
このコマンドレットはローカル ファイルシステム上の ARM テンプレート ファイルを Azure ストレージの BLOB ストレージにアップロードすることで ARM テンプレート作成を支援します。このコマンドレットは、リンクされた ARM テンプレートを作成する場合に特に便利です。

### パラメーター

パラメーター名     | 説明
-------------------|-------------------
LocalBasePath      | ARM テンプレートが保存されているローカル ファイルシステム上のフォルダーのパスです。
StorageAccountName | ARM テンプレートをアップロードするストレージ アカウントの名前です。
ResourceGroupName  | StorageAccountName パラメーターで指定したストレージ アカウントが含まれているリソース グループの名前です。
StorageAccountKey  | StorageAccountName パラメーターで指定したストレージ アカウントのストレージ アカウント キーです。
ContainerName      | ARM テンプレートをアップロードするコンテナーの名前です。このパラメーターは省略可能です。既定のコンテナー名は 'armtemplate' です。
Force              | このスイッチ パラメーターは省略可能です。このスイッチ パラメーターを使用した場合、コンテナー内に既に存在する ARM テンプレートを上書きします。

### 例

#### 例 1
この例は、'C:\TemplateWork' フォルダー配下の ARM テンプレート ファイルを再帰的にアップロードします。この例では ResourceGroupName パラメーターを使用しているため、このコマンドレットを実行する前に Login-AzureRmAccount を実行しておく必要があります。

```PowerShell
PS > Set-AzureUtilArmTemplateFile -LocalBasePath 'C:\TemplateWork' -StorageAccountName 'abcd1234' -ResourceGroupName 'ArmTemplateDev-RG' -Force
```

#### 例 2
この例は、'C:\TemplateWork' フォルダー配下の ARM テンプレート ファイルを再帰的にアップロードします。

```PowerShell
PS > Set-AzureUtilArmTemplateFile -LocalBasePath 'C:\TemplateWork' -StorageAccountName 'abcd1234' -StorageAccountKey 'dWLe7OT3P0HevzLeKzRlk4j4eRws7jHStp0C4XJtQJhuH4p5EOP+vLcK1w8sZ3QscGLy50DnOzQoiUbpzXD9Jg==' -Force
```

## Get-AzureUtilArmTemplateDeployUri コマンドレット
このコマンドレットは Azure ポータル上のカスタム デプロイ ブレードにアクセスするための URL を作成します。その URL は ARM テンプレートを Azure ポータルからデプロイ可能にします。

### パラメーター

パラメーター名  | 説明
----------------|-------------------
TemplateUri     | ARM テンプレートの URI です。
ShowDeployBlade | このスイッチ パラメーターは省略可能です。このスイッチ パラメーターを使用した場合、このコマンドレットは URL をブラウザーで開きます。

### 例

#### 例 1
この例は、ARM テンプレート URI からカスタム デプロイ ブレードの URL を作成します。

```PowerShell
PS > Get-AzureUtilArmTemplateDeployUri -TemplateUri 'https://abcd1234.blob.core.windows.net/armtemplate/main.json'

Uri
---
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fabcd1234.blob.core.windows.net%2Farmtemplate%2Fmain.json
```

#### 例 2
この例は、ARM テンプレート URI からカスタム デプロイ ブレードの URL を作成し、その URL をブラウザーで開きます。

```PowerShell
PS > Get-AzureUtilArmTemplateDeployUri -TemplateUri 'https://abcd1234.blob.core.windows.net/armtemplate/main.json' -ShowDeployBlade
```

## リリース ノート

### [1.0.4](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.4)
- Invoke-AzureUtilRestMethod コマンドレットを追加。
- Get-AzureUtilDatacenterIPRangeInfo コマンドレットを追加。
- Test-AzureUtilDatacenterIPRange コマンドレットを追加。
- 必要となる Azure PowerShell モジュールのバージョンを更新。
- ログイン チェックを改善。
- ヘルプを更新。
- いくつかの修正。

### [1.0.3](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.3)
- いくつかの修正。

### [1.0.2](https://github.com/tksh164/AzureUtil-PowerShellModule/releases/tag/1.0.2)
- Out-AzureUtilRdcManRdgFile コマンドレットを追加。
- コマンドレット名を "Get-AzureUtilNonAttachedNonManagedDisk" から "Get-AzureUtilNonAttachedUnmanagedDisk" に変更。
- いくつかの新しいパラメーターを追加。
- モジュールの実装をリファクタリング。
- ヘルプを更新。

### 1.0.1
- いくつかの修正。

### 1.0.0
- 最初のリリース。


## License
このプロジェクトは [MIT](https://github.com/tksh164/AzureUtil-PowerShellModule/blob/master/LICENSE) ライセンスでライセンスされています。
