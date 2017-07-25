#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Management'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='Azure.Storage'; ModuleVersion='3.1.0' }

function CreateNewAzureStorageContainer
{
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext] $Context,

        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $ContainerName,

        [Parameter(Mandatory = $false)]
        [int] $SleepSeconds = 3
    )

    $elapsedSeconds = 0

    while ($true)
    {
        try
        {
            [void] (New-AzureStorageContainer -Context $Context -Name $ContainerName -Permission Blob -ErrorAction Stop)
            break
        }
        catch
        {
            # The remote server returned an error: (409) Conflict. HTTP Status Code: 409 - HTTP Error Message: The specified container is being deleted. Try operation later.
            if (($_.FullyQualifiedErrorId -eq 'StorageException,Microsoft.WindowsAzure.Commands.Storage.Blob.Cmdlet.NewAzureStorageContainerCommand') -and
                ($_.Exception.InnerException -ne $null) -and ($_.Exception.InnerException.RequestInformation.HttpStatusCode -eq 409))
            {
                # Waiting for Azure.
                Write-Verbose -Message $_.Exception.Message
                Write-Verbose -Message ('Waiting {0} seconds.' -f $SleepSeconds)
                Write-Progress -Activity ('Waiting for Azure... (Least {0} seconds elapsed)' -f $elapsedSeconds) -Status ('Reason: {0}' -f $_.Exception.Message)
                Start-Sleep -Seconds $SleepSeconds
                $elapsedSeconds += $SleepSeconds
            }
            else
            {
                throw $_
            }
        }
    }

    Write-Progress -Activity 'Completed waiting.' -Completed
}

<#
.SYNOPSIS
Upload the ARM template files on local filesystem to blob storage of Azure storage.

.DESCRIPTION
This cmdlet helping to ARM template making by upload the ARM template files on local filesystem to blob storage of Azure storage. When you making linked ARM template, this cmdlet is especially helpful.

.PARAMETER LocalBasePath
The path of the folder on local filesystem that contains the ARM templates.

.PARAMETER StorageAccountName
The storage account name to upload the ARM templates.

.PARAMETER ResourceGroupName
The resource group name that it contains the storage account of StorageAccountName parameter.

.PARAMETER StorageAccountKey
The storage account key for storage account of StorageAccountName parameter.

.PARAMETER ContainerName
The container name to upload the ARM templates. This parameter is optional. Default container name is 'armtemplate'.

.PARAMETER Force
This switch parameter is optional. If you use this switch, overwrite the existing ARM templates in the container.

.EXAMPLE
    Set-AzureUtilArmTemplateFile -LocalBasePath 'C:\TemplateWork' -StorageAccountName 'abcd1234' -ResourceGroupName 'ArmTemplateDev-RG' -Force

---- Example Description ----
This example is upload the ARM template files from under 'C:\TemplateWork' folder with recursive. You need execute Login-AzureRmAccount cmdlet before execute this cmdlet because this example use ResourceGroupName parameter.

.EXAMPLE
    Set-AzureUtilArmTemplateFile -LocalBasePath 'C:\TemplateWork' -StorageAccountName 'abcd1234' -StorageAccountKey 'dWLe7OT3P0HevzLeKzRlk4j4eRws7jHStp0C4XJtQJhuH4p5EOP+vLcK1w8sZ3QscGLy50DnOzQoiUbpzXD9Jg==' -Force

---- Example Description ----
This example is upload the ARM template files from under 'C:\TemplateWork' folder with recursive.

.LINK
PowerShell Gallery: https://www.powershellgallery.com/packages/AzureUtil/

.LINK
GitHub: https://github.com/tksh164/AzureUtil-PowerShellModule

.LINK
Get-AzureUtilArmTemplateDeployUri
#>
function Set-AzureUtilArmTemplateFile
{
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param (
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][ValidateScript({ Test-Path -PathType Container -LiteralPath $_ })]
        [string] $LocalBasePath,

        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $StorageAccountName,

        [Parameter(ParameterSetName='ResourceGroupName', Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $ResourceGroupName,

        [Parameter(ParameterSetName='StorageAccountKey', Mandatory = $true)][ValidateNotNullOrEmpty()]
        [string] $StorageAccountKey,

        [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]
        [string] $ContainerName = 'armtemplate',

        [Parameter(Mandatory = $false)]
        [switch] $Force = $false
    )

    if ($PSCmdlet.ParameterSetName -eq 'ResourceGroupName')
    {
        # Login check.
        try { [void](Get-AzureRMContext -ErrorAction Stop) } catch { throw }

        # Get the storage account key.
        $StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName).Value | Select-Object -First 1
        Write-Verbose -Message 'Got the storage account key.'
    }

    # Standardize the path.
    if (-not $LocalBasePath.EndsWith('\'))
    {
        $LocalBasePath += '\'
    }

    # Get a storage context.
    $context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    Write-Verbose -Message ('Got the storage context of ''{0}'' account.' -f $context.StorageAccountName)

    # Create a container if it not exist.
    $container = Get-AzureStorageContainer -Context $context -Name $ContainerName -ErrorAction SilentlyContinue
    if ($container -eq $null)
    {
        Write-Verbose -Message ('Create a new container, because the ''{0}'' container is does not exist in ''{1}'' account.' -f $ContainerName,$context.StorageAccountName)
        CreateNewAzureStorageContainer -Context $context -ContainerName $ContainerName
    }
    else
    {
        Write-Verbose -Message ('The ''{0}'' container is exist in ''{1}'' account.' -f $ContainerName,$context.StorageAccountName)
    }

    # Upload the files.
    Get-ChildItem -LiteralPath $LocalBasePath -File -Recurse |
        ForEach-Object -Process {
    
            $localFilePath = $_.FullName

            # Create blob name from local file path.
            $blobName = $localFilePath.Replace($localBasePath,'').Replace('\', '/')

            # Upload a file.
            Write-Verbose -Message ('Uploading "{0}" to {1}{2}/{3} ...' -f $localFilePath,$context.BlobEndPoint,$ContainerName,$blobName)
            $result = Set-AzureStorageBlobContent -Context $context -File $localFilePath -Container $ContainerName -Blob $blobName -BlobType Block -Force:$Force

            [pscustomobject] @{
                Uri = $result.ICloudBlob.StorageUri.PrimaryUri
            }
        }
}
