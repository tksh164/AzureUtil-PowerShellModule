#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Resources'; ModuleVersion='3.6.0' }

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Internal.Common.psm1' -Resolve)

function PreventTokenExpire
{
    # Prevent the token expire by the dummy request.
    Get-AzureRmResource -ResourceType 'Microsoft.Compute' -Top 1 -TenantLevel:$false
}

<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER Method
    .PARAMETER Uri
    .PARAMETER Body

    .EXAMPLE

    .EXAMPLE

    .EXAMPLE

    .LINK
    PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

    .LINK
    GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

    .LINK

    .LINK
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
