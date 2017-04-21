function Remove-CACertificateRequest {
    <#
    .SYNOPSIS
        Remove a certificate request from a Microsoft Certificate Authority.
    .DESCRIPTION
        Remove-CACertificateRequest allows an administrator to remove requests from a Microsoft Certificate Authority database.
    .EXAMPLE
        Get-CACertificateRequest -CommonName SomeServer -Issued | Remove-CACertificateRequest
    
        Get all certificates which are issued using SomeServer as the CommonName and delete each.
    .EXAMPLE
        Remove-CACertificateRequest -ExpiredBefore "01/01/2015"
    
        Delete all certificate requests where the certificate expired before 01/01/2015.
    .EXAMPLE
        Remove-CACertificateRequest -LastModifiedBefore "01/01/2015"
    
        Delete all pending or denied certificate requests which were last modified before 01/01/2015.
    .NOTES
        Change log:
            05/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'DeleteByRequestID', SupportsShouldProcess = $true)]
    param (
        # Delete the certificate request with the specified request ID.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DeleteByRequestID')]
        [Alias('ID')]
        [Int32]$RequestID,

        # Delete certificate requests which expired before the specified date.
        [Parameter(Mandatory = $true, ParameterSetname = 'DeleteByExpirationDate')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiredBefore,

        # Delete pending or denied requests which were last modified before the specified date.
        [Parameter(Mandatory = $true, ParameterSetName = 'DeleteByLastModifiedDate')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $LastModifiedBefore,

        # Suppress confirmation dialog.
        [Switch]$Force,

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [String]$CA = (Get-DefaultCA)
    )

    begin {
        try {
            $caAdmin = New-Object -ComObject CertificateAuthority.Admin
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        if ($pscmdlet.ShouldProcess("Deleting certificate Request ID: $($CertificateRequest.RequestID) ($($CertificateRequest.CommonName))")) {
            if ($Force -or $pscmdlet.ShouldContinue("", "Removing certificates from $CA")) {
                try {
                    switch ($pscmdlet.ParameterSetName) {
                        'DeleteByRequestID' {
                            $caAdmin.DeleteRow(
                                $CA,
                                [Indented.PKI.CAAdmin.DeleteRowFlag]::NONE,
                                0,
                                [Indented.PKI.CAView.Table]::CVRC_TABLE_REQCERT,
                                $RequestID
                            )
                        }
                        'DeleteByExpirationDate' {
                            $caAdmin.DeleteRow(
                                $CA,
                                [Indented.PKI.CAAdmin.DeleteRowFlag]::CDR_EXPIRED,
                                (Get-Date $ExpiredBefore),
                                [Indented.PKI.CAView.Table]::CVRC_TABLE_REQCERT,
                                0
                            )
                        }
                        'DeleteByLastModifiedDate' {
                            $caAdmin.DeleteRow(
                                $CA,
                                [Indented.PKI.CAAdmin.DeleteRowFlag]::CDR_REQUEST_LAST_CHANGED,
                                (Get-Date $LastModifiedBefore),
                                [Indented.PKI.CAView.Table]::CVRC_TABLE_REQCERT,
                                0
                            )
                        }
                    }
                } catch {
                    Write-Error -ErrorRecord (NewCAError $_)
                }
            }
        }
    }

    end {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caAdmin)
    }
}