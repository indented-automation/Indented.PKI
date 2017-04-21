function NewCAError {
    <#
    .SYNOPSIS
        Creates an error record from an exception thrown by a CA COM object.
    .DESCRIPTION
        Parses Win32 error codes out of wrapped exceptions.
    #>

    param (
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    if ($ErrorRecord.Exception.Message -match 'CCert[^:]+::[^:]+: .*WIN32: (\d+)') {
        return New-Object System.Management.Automation.ErrorRecord(
            (New-Object ComponentModel.Win32Exception([Int32]$matches[1])),
            $_.Exception.Message,
            [System.Management.Automation.ErrorCategory]::OperationStopped,
            $null
        )
    }
    return $ErrorRecord
}