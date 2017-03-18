function Set-DefaultCA {
    # .SYNOPSIS
    #   Set a default CA value.
    # .DESCRIPTION
    #   By default all CmdLets operating against a CA require the executor to provide the name of the CA.
    #
    #   This command allows the executor to define a default CA for all operations.
    # .PARAMETER CA
    #   A string which identifies a certificate authority in the form "ServerName\CAName".
    # .PARAMETER Persistent
    #   By default the CA value will only be used for this session. The CA value can be made to persist across all sessions for the current user with this setting. The CA text file is saved to the WindowsPowerShell folder under "Documents" for the current user.
    # .INPUTS
    #   System.String
    # .EXAMPLE
    #   Set-DefaultCA -CA "SomeServer\CA Name"
    #
    #   Set the name of a DefaultCA for this session.
    # .EXAMPLE
    #   Set-DefaultCA -CA "SomeServer\Default CA Name" -Persistent
    #
    #   Set the name of a DefaultCA for this session and all future sessions.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/03/2015 - Chris Dent - BugFix: Added handler for missing WindowsPowerShell folder.
    #     02/02/2015 - Chris Dent - First release.

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$CA,

        [Switch]$Persistent
    )

    if (Get-Variable CA -Scope Script -ErrorAction SilentlyContinue) {
        if ($Script:CA -ne $CA) {
            $Script:CA = $CA
        }
    } else {
        New-Variable CA -Scope Script -Value $CA
    }

    if ($Persistent) {
        if (-not (Test-Path (Split-Path $profile.CurrentUserAllHosts -Parent))) {
            $null = New-Item (Split-Path $profile.CurrentUserAllHosts -Parent) -ItemType Directory -Force
        }
        $CA | Out-File "$(Split-Path $profile.CurrentUserAllHosts -Parent)\DefaultCA.txt"
    }
}