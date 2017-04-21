function Get-DefaultCA {
    <#
    .SYNOPSIS
        Get the default CA value.
    .DESCRIPTION
        By default all CmdLets operating against a CA require the executor to provide the name of the CA. 

        This command allows the executor to get a previously supplied default CA. If the default value has been made persistent the value is read from Documents\WindowsPowerShell\DefaultCA.txt.
    .EXAMPLE
        Get-KSDefaultCA
    .NOTES
        Change log:
            02/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    param ( )

    if (($Script:CA -eq $null) -and (Test-Path "$home\Documents\WindowsPowerShell\DefaultCA.txt")) {
        $Script:CA = (Get-Content "$home\Documents\WindowsPowerShell\DefaultCA.txt" -Raw).Trim()
    }

    return $Script:CA
}