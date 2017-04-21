function Receive-Certificate {
    <#
    .SYNOPSIS
        Receive an issued certificate request (a signed public key) from a CA.
    .DESCRIPTION
        Receive-Certificate remotely executes the certreq command to attempt to retrieve an issued certificate from the specified CA.
    .EXAMPLE
        Receive-Certificate -RequestID 23

        Attempt to receive certificate request 23 from the default CA.
    .EXAMPLE
        Receive-Certificate -RequestID 1220 -CA "ServerName\Alt CA 01"

        Receive request 1220 from the CA "Alt CA 01".
    .EXAMPLE
        Receive-Certificate -RequestID 93 
    .NOTES
        Change log:
            24/02/2015 - Chris Dent - BugFix: CA is mandatory.
            09/02/2015 - Chris Dent - Added quiet parameter to certreq.
            04/02/2015 - Chris Dent - Added AndComplete parameter.
            03/02/2015 - Chris Dent - First release.
    #>

    [CmdletBinding()]
    param (
        # The request ID number for an existing issued certificate on the specified (or default) CA.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Int32]$RequestID,

        # CommonName is an optional parameter used to preserve a CommonName value while operating in pipeline mode. The parameter is optional and is used to name temporary files only.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CommonName = "Certificate",

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

        # Completion of the certificate request is, by default, a separate step. Immediate completion may be requested by setting this parameter.
        [Switch]$AndComplete
    )

    process {
        $Command = "certreq -retrieve -q -f -config ""$CA"" $RequestId ""$CommonName.cer"""

        Write-Debug "Executing $Command"

        $Response = & "cmd.exe" "/c", $Command

        if ($Response -match 'Taken Under Submission') {
            Write-Warning "The certificate request is not yet approved."
        } else {
            if ($lastexitcode -eq 0) {
                if (Test-Path "$CommonName.cer") {
                    Write-Verbose "Certificate saved to $($pwd.Path)\$CommonName.cer"

                    # Construct a return object which will aid the onward pipeline.
                    $ReceivedCertificate = [PSCustomObject]@{
                        CommonName             = $CommonName
                        Certificate            = Get-Content "$CommonName.cer" -Raw
                        CA                     = $CA
                        Disposition            = "Received"
                    } | Add-Member -TypeName "Indented.PKI.Certificate.ReceivedCertificate" -PassThru

                    if ($AndComplete) {
                        $ReceivedCertificate | Complete-Certificate
                    } else {
                        return $ReceivedCertificate
                    }
                } else {
                    Write-Error "Unable to access cer file $CommonName.cer."
                }
            } else {
                Write-Error "certreq returned $lastexitcode - $Response"
            }
        }
    }
}