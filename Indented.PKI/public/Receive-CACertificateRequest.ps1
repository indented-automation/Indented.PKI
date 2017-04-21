function Receive-CACertificateRequest {
    <#
    .SYNOPSIS
        Receive an issued certificate request from a CA.
    .DESCRIPTION
        Receive an issued certificate request from a CA as a Base64 encoded string (with header and footer).
    .EXAMPLE
        Get-CACertificateRequest -RequestID 3 -Issued | Receive-CACertificateRequest

        Receive an issued request and display the received certificate object.
    .EXAMPLE
        Receive-CACertificateRequest -RequestID 9 | ConvertTo-X509Certificate

        Receive an issued request and convert the request into an X509Certificate object.
    .EXAMPLE
        Receive-CACertificateRequest -RequestID 2 | Complete-Certificate

        Receive the certificate request and install the signed public key into an existing (incomplete) certificate request.
    .NOTES
        Change log:
            05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
            04/02/2015 - Chris Dent - Added CommonName as a pipeline parameter. Added AndComplete parameter. BugFix: Bad pipeline.
            02/02/2015 - Chris Dent - Added support for Get-DefaultCA.
            30/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    param (
        # The request ID to receive.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FromPipeline')]
        [Int32]$RequestID,

        # Receive the request from the specified CA.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

        # Complete the request
        [Switch]$AndComplete
    )

    begin {
        $caRequest = New-Object -ComObject CertificateAuthority.Request
    }

    process {
        try {
            $caResponse = $caRequest.GetIssuedCertificate($CA, $RequestID, $null)

            if ($caResponse -eq [Indented.PKI.CAAdmin.ResponseDisposition]::Issued) {
                $receivedCertificate = [PSCustomObject]@{
                    Certificate            = $caRequest.GetCertificate([Indented.PKI.CertificateRequestEncoding]::CR_OUT_BASE64HEADER)
                    CA                     = $CA
                    Disposition            = 'Received'
                } | Add-Member -TypeName 'Indented.PKI.ReceivedCertificate' -PassThru

                if ($AndComplete) {
                    $receivedCertificate | Complete-Certificate
                } else {
                    return $receivedCertificate
                }
            } else {
                Write-Warning ('Certificate request ({0}) must be issued to receive certificate.' -f $RequestID)
            }
        } catch {
            WriteError -ErrorRecord (NewCAError $_)
        }
    }

    end {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caRequest)
    }
}