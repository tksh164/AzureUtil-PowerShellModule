#requires -Version 5

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Internal.Common.psm1' -Resolve)

function PreventTokenExpire
{
    # Prevent the token expire by the dummy request.
    Get-AzureRmResource -ResourceType 'Microsoft.Compute' -Top 1 -TenantLevel:$false
}

<#
.SYNOPSIS
Sends an HTTP or HTTPS request as Azure REST API.

.DESCRIPTION
The Invoke-AzureUtilRestMethod cmdlet sends HTTP and HTTPS requests to Azure REST API service endpoints that returns structured data.

.PARAMETER Method
Specifies the method used for the web request. This parameter is optional. The default value is "Get".

.PARAMETER Uri
Specifies the URI of the Azure REST API to which the web request is sent.

.PARAMETER AdditionalHeaders
Specifies the additional headers of the web request. Enter a hash table or dictionary. This parameter is optional.

.PARAMETER ContentType
Specifies the content type of the web request. This parameter is optional. The default value is "application/json".

.PARAMETER Body
Specifies the body of the web request. The body is the content of the web request that follows the headers. This parameter is optional.

.EXAMPLE
    PS C:\>$result = Invoke-AzureUtilRestMethod -Uri 'https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'

    PS C:\>$result.Content
    {"id":"/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/Sample-RG","name":"Sample-RG","location":"japaneast","properties":{"provisioningState":"Succeeded"}}

    PS C:\>ConvertFrom-Json $result.Content | Format-Custom
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

---- Example Description ----
In this example, get the "Sample-RG" resource group information using Azure REST API. You can find this REST API details at https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_Get.

.EXAMPLE
    PS C:\>$result = Invoke-AzureUtilRestMethod -Method Head -Uri 'https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'

    PS C:\>$result.StatusCode
    204

---- Example Description ----
In this example, checks whether the "Sample-RG" resource group exists using Azure REST API. This REST API is return the 204 as HTTP status code if that resource group is exists. You can find this REST API details at https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_CheckExistence.

.EXAMPLE
    PS C:\>$body = @'
    {
        "resources": [ "*" ],
        "options": "IncludeParameterDefaultValue, IncludeComments"
    }
    '@

    PS C:\>$result = Invoke-AzureUtilRestMethod -Method Post -Uri 'https://management.azure.com/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG/exportTemplate?api-version=2017-05-10' -Body $body

    PS C:\>$result.Content
    {"template":{"$schema":"https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#","contentVersion":"1.0.0.0","parameters":{"storageAccounts_abcd1234_name":{"defaultValue":"abcd1234","type":"String"}},"variables":{},"resources":[{"comments":"Generalized from resource: '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/sample-rg/providers/Microsoft.Storage/storageAccounts/abcd1234'.","type":"Microsoft.Storage/storageAccounts","sku":{"name":"Standard_LRS","tier":"Standard"},"kind":"Storage","name":"[parameters('storageAccounts_abcd1234_name')]","apiVersion":"2016-01-01","location":"japaneast","tags":{},"scale":null,"properties":{},"dependsOn":[]}]}}

---- Example Description ----
In this example, capture the "Sample-RG" resource group as a template. You can find this REST API details at https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups#ResourceGroups_ExportTemplate.

.EXAMPLE
    PS C:\>Invoke-AzureUtilRestMethod -Uri '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourcegroups/Sample-RG?api-version=2017-05-10'

---- Example Description ----
In this example, get the "Sample-RG" resource group information using Azure REST API with abbreviated URI. This cmdlet is automaticaly prepend "https://management.azure.com" to URI if Uri parameter starts with "/subscriptions/".

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Azure REST API Reference: https://docs.microsoft.com/en-us/rest/api/
#>
function Invoke-AzureUtilRestMethod
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        [Parameter(Mandatory = $true)]
        [uri] $Uri,

        [Parameter(Mandatory = $false)]
        [System.Collections.IDictionary] $AdditionalHeaders,

        [Parameter(Mandatory = $false)]
        [string] $ContentType = 'application/json',

        [Parameter(Mandatory = $false)]
        [System.Object] $Body
    )

    # Login check.
    PreventUnloggedExecution

    # Prevent the token expire.
    PreventTokenExpire

    # Get the tenant ID and cache data.
    $context = Get-AzureRmContext
    $tenantId = $context.Tenant.Id
    $cacheData = $context.TokenCache.CacheData

    #
    # Retrieve a token cache item.
    #

    $tokenCache = New-Object -TypeName 'Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache' -ArgumentList (,$cacheData)
    $tokenCacheItem = $tokenCache.ReadItems() |
        Where-Object -Property 'TenantId' -EQ -Value $tenantId |
        Select-Object -First 1

    if ($tokenCacheItem -eq $null)
    {
        throw 'Please re-login by run Login-AzureRmAccount.'
    }

    # Build the full URI if it is abbreviated.
    if ($Uri.OriginalString.StartsWith('/subscriptions/'))
    {
        $Uri = [uri] ('https://management.azure.com' + $Uri.OriginalString)
    }

    #
    # Build the headers.
    #

    $headers = @{
        'Authorization' = 'Bearer ' + $tokenCacheItem.AccessToken
    }

    if ($PSBoundParameters.ContainsKey('AdditionalHeaders'))
    {
        $AdditionalHeaders.GetEnumerator() |
            ForEach-Object -Process { $headers.Add($_.Key, $_.Value) }
    }

    #
    # Invoke the REST method.
    #

    $params = @{
        Method      = $Method
        Uri         = $Uri
        Headers     = $headers
        ContentType = $ContentType
    }

    if ($PSBoundParameters.ContainsKey('Body'))
    {
        $params.Body = $Body
    }

    Invoke-WebRequest @params
}
