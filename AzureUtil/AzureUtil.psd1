#
# Module manifest for module 'AzureUtil'
#
# Generated by: Takeshi Katano
#
# Generated on: 4/7/2017
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'AzureUtil.psm1'

# Version number of this module.
ModuleVersion = '1.0.3'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '74573774-2beb-4542-93b9-9fea66eb24fa'

# Author of this module
Author = 'Takeshi Katano'

# Company or vendor of this module
CompanyName = 'Takeshi Katano'

# Copyright statement for this module
Copyright = '(c) 2017 Takeshi Katano. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Utility cmdlets for Azure management operations.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
CLRVersion = '4.0.30319.42000'

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
    'Microsoft.PowerShell.Utility',
    'AzureRM.Profile',
    'AzureRM.Resources',
    'AzureRM.Compute',
    'Azure.Storage',
    'AzureRM.Storage',
    'AzureRM.Network'
)

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Get-AzureUtilEmptyResourceGroup',
    'Get-AzureUtilNonAttachedManagedDisk',
    'Get-AzureUtilNonAttachedUnmanagedDisk',
    'Out-AzureUtilRdcManRdgFile'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @(
    'AzureUtil.psd1',
    'AzureUtil.psm1',
    'EmptyResourceGroup.psm1',
    'NonAttachedManagedDisk.psm1',
    'NonAttachedUnmanagedDisk.psm1',
    'RdcManRdgFile.psm1'
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @(
            'Azure',
            'ARM',
            'ResourceGroup',
            'Management',
            'VM',
            'VirtualMachne',
            'Disk',
            'VHD',
            'Blob',
            'ManagedDisks',
            'RDCMan',
            'RemoteDesktopConnectionManager',
            'rdg',
            'RemoteDesktop',
            'RDP'
        )

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/tksh164/AzureUtil-PowerShellModule/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/tksh164/AzureUtil-PowerShellModule'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'https://github.com/tksh164/AzureUtil-PowerShellModule#release-notes'

        # External dependent modules of this module.
        ExternalModuleDependencies = @(
            'Microsoft.PowerShell.Utility',
            'AzureRM.Profile',
            'AzureRM.Resources',
            'AzureRM.Compute',
            'Azure.Storage',
            'AzureRM.Storage',
            'AzureRM.Network'
        )

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/tksh164/AzureUtil-PowerShellModule'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
#DefaultCommandPrefix = ''

}
