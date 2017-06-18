#requires -Version 5
#requires -Modules @{ ModuleName='AzureRM.Profile'; ModuleVersion='3.1.0' }

function PreventUnloggedExecution
{
    try {
        $context = Get-AzureRmContext -ErrorAction Stop

        if (($context.Tenant.Id -eq $null) -or ($context.Subscription.Id -eq $null))
        {
            throw 'Run Login-AzureRmAccount to login.'
        }
    }
    catch
    {
        throw
    }
}
