#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Management'; ModuleVersion='3.1.0.0' }

<#
.SYNOPSIS
Build the URL of custom deployment blade for your ARM template.

.DESCRIPTION
This cmdlet building the URL that is access to custom deployment blade on Azure Portal. The URL allows deployment of your ARM template via Azure Portal.

.PARAMETER TemplateUri
The URI of your ARM template.

.PARAMETER ShowDeployBlade
This switch parameter is optional. If you use this switch, this cmdlet open the URL by your browser.

.EXAMPLE
    Get-AzureUtilArmTemplateDeployUri -TemplateUri 'https://abcd1234.blob.core.windows.net/armtemplate/main.json'

    Uri
    ---
    https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fabcd1234.blob.core.windows.net%2Farmtemplate%2Fmain.json

---- Example Description ----
This example is build the URL of custom deployment blade from your ARM template URL.

.EXAMPLE
    Get-AzureUtilArmTemplateDeployUri -TemplateUri 'https://abcd1234.blob.core.windows.net/armtemplate/main.json' -ShowDeployBlade

---- Example Description ----
This example is build the URL of custom deployment blade from your ARM template URL and open that URL by your browser.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Set-AzureUtilArmTemplateFile
#>
function Get-AzureUtilArmTemplateDeployUri
{
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)][ValidateNotNullOrEmpty()]
        [string] $TemplateUri,

        [Parameter(Mandatory = $false)]
        [switch] $ShowDeployBlade = $false
    )

    $createUri = 'https://portal.azure.com/#create/Microsoft.Template/uri/'
    $encodedTemplateUri = $TemplateUri.Replace(':', '%3A').Replace('/', '%2F')

    $uri = $createUri + $encodedTemplateUri

    if ($ShowDeployBlade)
    {
        # Open the template deploy blade.
        Start-Process -FilePath $uri
    }

    [pscustomobject] @{
        Uri = $uri
    }
}
