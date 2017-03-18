function Remove-CACertificateRequest {
    # .SYNOPSIS
    #   Remove a certificate request from a Microsoft Certificate Authority.
    # .DESCRIPTION
    #   Remove-CACertificateRequest allows an administrator to remove requests from a Microsoft Certificate Authority database.
    # .PARAMETER CA
    #   A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .PARAMETER RequestId
    #   Delete the certificate request with the specified request ID.
    # .PARAMETER ExpiredBefore
    #   Delete certificate requests which expired before the specified date.
    # .PARAMETER LastModifiedBefore
    #   Delete pending or denied requests which were last modified before the specified date.
    # .PARAMETER Force
    #   Suppress confirmation dialog.
    # .INPUTS
    #   System.Int32
    #   System.String
    # .OUTPUTS
    #   System.Int32
    # .EXAMPLE
    #   Get-CACertificateRequest -CommonName SomeServer -Issued | Remove-CACertificateRequest
    #
    #   Get all certificates which are issued using SomeServer as the CommonName and delete each.
    # .EXAMPLE
    #   Remove-CACertificateRequest -ExpiredBefore "01/01/2015"
    #
    #   Delete all certificate requests where the certificate expired before 01/01/2015.
    # .EXAMPLE
    #   Remove-CACertificateRequest -LastModifiedBefore "01/01/2015"
    #
    #   Delete all pending or denied certificate requests which were last modified before 01/01/2015.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     05/02/2015 - Chris Dent - First release. Added check for Certification Authority tools (RSAT).

    [CmdletBinding(DefaultParameterSetName = 'DeleteByRequestID', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DeleteByRequestID')]
        [ValidateNotNullOrEmpty()]
        [Alias('ID')]
        [Int32]$RequestID,

        [Parameter(Mandatory = $true, ParameterSetname = 'DeleteByExpirationDate')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiredBefore,

        [Parameter(Mandatory = $true, ParameterSetName = 'DeleteByLastModifiedDate')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $LastModifiedBefore,

        [Switch]$Force,

        [ValidateNotNullOrEmpty()]
        [String]$CA = (Get-DefaultCA)
    )

    begin {
        if (-not (Test-Path "$env:WinDir\System32\certadm.dll") -or -not (Test-Path "$env:WinDir\System32\certcli.dll")) {
            $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object InvalidOperationException "The Certification Authority tools must be installed to use this CmdLet."),
                "InvalidOperationException",
                [Management.Automation.ErrorCategory]::OperationStopped,
                $pscmdlet
            )
            $pscmdlet.ThrowTerminatingError($ErrorRecord)
        }

        $CAAdmin = New-Object -COMObject CertificateAuthority.Admin
    }

    process {
        if (-not $CA) {
            $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object ArgumentException "The CA parameter is mandatory."),
                "ArgumentException",
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($ErrorRecord)
        }  

        if ($pscmdlet.ShouldProcess("Deleting certificate Request ID: $($CertificateRequest.RequestID) ($($CertificateRequest.CommonName))")) {
            if ($Force -or $pscmdlet.ShouldContinue("", "Removing certificates from $CA")) {
                try {
                    $RowsDeleted = switch ($pscmdlet.ParameterSetName) {
                        'DeleteByRequestID' {
                            $CAAdmin.DeleteRow(
                                $CA,
                                [CAAdmin.DeleteRowFlag]::NONE,
                                0,
                                [CAView.Table]::CVRC_TABLE_REQCERT,
                                $RequestID
                            )
                        }
                        'DeleteByExpirationDate' {
                            $CAAdmin.DeleteRow(
                                $CA,
                                [CAAdmin.DeleteRowFlag]::CDR_EXPIRED,
                                (Get-Date $ExpiredBefore),
                                [CAView.Table]::CVRC_TABLE_REQCERT,
                                0
                            )
                        }
                        'DeleteByLastModifiedDate' {
                            $CAAdmin.DeleteRow(
                                $CA,
                                [CAAdmin.DeleteRowFlag]::CDR_REQUEST_LAST_CHANGED,
                                (Get-Date $LastModifiedBefore),
                                [CAView.Table]::CVRC_TABLE_REQCERT,
                                0
                            )
                        }
                    }
                } catch {
                    $pscmdlet.ThrowTerminatingError((NewWin32ErrorRecord $_))
                }
                return $RowsDeleted
            }
        }
    }
}