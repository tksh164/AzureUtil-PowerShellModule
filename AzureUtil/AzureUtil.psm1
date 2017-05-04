#requires -Version 5
#requires -Modules @{ ModuleName='Microsoft.PowerShell.Utility'; ModuleVersion='3.1.0.0' }
#requires -Modules @{ ModuleName='AzureRM.Resources'; ModuleVersion='3.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='AzureRM.Compute'; ModuleVersion='2.7.0' }
#requires -Modules @{ ModuleName='AzureRM.Storage'; ModuleVersion='2.6.0' }
#requires -Modules @{ ModuleName='Azure.Storage'; ModuleVersion='2.6.0' }

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'EmptyResourceGroup.psm1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'NonAttachedManagedDisk.psm1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'NonAttachedNonManagedDisk.psm1' -Resolve)
