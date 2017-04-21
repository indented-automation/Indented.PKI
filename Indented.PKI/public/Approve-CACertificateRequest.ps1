function Approve-CACertificateRequest {
    <#
    .SYNOPSIS
        Approve a certificate request and issue a certificate.
    .DESCRIPTION
        Approve a pending certificate request on the specified CA and issue a certificate.
    .EXAMPLE
        Get-CACertificateRequest -Pending | Approve-CACertificateRequest

        Approve and issue all pending certificates on the default CA.
    .EXAMPLE
        Approve-CACertificateRequest -RequestID 9

        Approve and issue certificate request 9 on the default CA.
    .NOTES
        Change log:
            24/02/2015 - Chris Dent - BugFix: Missing CA parameter when getting Issued certificates.
            13/02/2015 - Chris Dent - Modified pipeline to accept additional parameters for the Submit to Receive pipeline.
            05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
            04/02/2015 - Chris Dent - Allowed CmdLet to immediately return certificates which are already approved.
            03/02/2015 - Chris Dent - Modified input pipeline.
            02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
            29/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # A request ID must be supplied for approval.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Int32]$RequestID,

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
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
        if ($pscmdlet.ShouldProcess(('Issuing certificate Request ID: {0}' -f $RequestID))) {
            try {
                [Indented.PKI.CAAdmin.ResponseDisposition]$caResponse = $caAdmin.ResubmitRequest($CA,  $RequestID)
                Write-Debug ('CA response disposition: {0}' -f $caResponse)
            } catch {
                Write-Error -ErrorRecord (NewCAError $_)
            }
        }
    }

    end {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caAdmin)
    }
}