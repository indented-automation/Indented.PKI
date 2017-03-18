function Get-DefaultCA {
    # .SYNOPSIS
    #   Get the default CA value.
    # .DESCRIPTION
    #   By default all CmdLets operating against a CA require the executor to provide the name of the CA. 
    #
    #   This CmdLet allows the executor to get a previously supplied default CA. If the default value has been made persistent the value is read from Documents\WindowsPowerShell\DefaultCA.txt.
    # .OUTPUTS
    #   System.String
    # .EXAMPLE
    #   Get-DefaultCA
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     02/02/2015 - Chris Dent - First release.

    [CmdletBinding()]
    param( )

    # This function will populate a script level variable if it doesn't exist and the DefaultCA file does.
    if (-not (Get-Variable CA -Scope Script -ErrorAction SilentlyContinue) -and (Test-Path "$(Split-Path $profile.CurrentUserAllHosts -Parent)\DefaultCA.txt")) {
        New-Variable CA -Scope Script -Value (Get-Content "$(Split-Path $profile.CurrentUserAllHosts -Parent)\DefaultCA.txt")
    }

    return $Script:CA
}