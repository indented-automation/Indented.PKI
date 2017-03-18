using namespace System.Management.Automation
using namespace System.ComponentModel

function NewWin32ErrorRecord {
    param(
        [ErrorRecord]$ErrorRecord
    )

    if ($ErrorRecord.Exception.Message -match 'CCert[^:]+::[^:]+: .*WIN32: (\d+)') {
        $newErrorRecord = New-Object ErrorRecord(
            (New-Object Win32Exception([Int32]$matches[1])),
            $_.Exception.Message,
            [ErrorCategory]::OperationStopped,
            $null
        )
    }
    if (-not $newErrorRecord) {
        $newErrorRecord = New-Object ErrorRecord(
            $_.Exception,
            $_.Exception.Message,
            [ErrorCategory]::OperationStopped,
            $null
        )
    }

    return $newErrorRecord
}