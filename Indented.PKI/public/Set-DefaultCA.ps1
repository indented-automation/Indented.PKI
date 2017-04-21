function Set-DefaultCA {
    <#
    .SYNOPSIS
        Set a default CA value.
    .DESCRIPTION
        By default all CmdLets operating against a CA require the executor to provide the name of the CA.

        This command allows the executor to define a default CA for all operations.
    .EXAMPLE
        Set-DefaultCA -CA "SomeServer\CA Name"

        Set the name of a DefaultCA for this session.
    .EXAMPLE
        Set-DefaultCA -CA "SomeServer\Default CA Name" -Persistent

        Set the name of a DefaultCA for this session and all future sessions.
    .NOTES
        Change log:
            04/03/2015 - Chris Dent - BugFix: Added handler for missing WindowsPowerShell folder.
            02/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    param (
        # A string which identifies a certificate authority in the form "ServerName\CAName".
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$CA,

        # By default the CA value will only be used for this session. The CA value can be made to persist across all sessions for the current user with this setting. The CA text file is saved to the WindowsPowerShell folder under "Documents" for the current user.
        [Switch]$Persistent
    )

    $Script:CA = $CA

    if ($Persistent) {
        if (-not (Test-Path "$home\Documents\WindowsPowerShell")) {
            $null = New-Item "$home\Documents\WindowsPowerShell" -ItemType Directory -Force
        }
        $CA | Out-File "$home\Documents\WindowsPowerShell\DefaultCA.txt"
    }
}