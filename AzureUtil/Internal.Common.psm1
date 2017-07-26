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
