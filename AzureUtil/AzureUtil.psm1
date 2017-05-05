Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'EmptyResourceGroup.psm1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'NonAttachedManagedDisk.psm1' -Resolve)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'NonAttachedUnmanagedDisk.psm1' -Resolve)
