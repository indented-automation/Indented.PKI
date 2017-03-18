using namespace System.Security.Cryptography.X509Certificates

function ConvertTo-X509Certificate {
    # .SYNOPSIS
    #   Convert a Base64 encoded certificate (with header and footer) to an X509Certificate object.
    # .DESCRIPTION
    #   ConvertTo-X509Certificate reads a Base64 encoded certificate string or file and converts it to an X509Certificate object.
    # .PARAMETER Certificate
    #   A base64 encoded string describing the certificate.
    # .PARAMETER Path
    #   A path to an existing certificate file.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Security.Cryptography.X509Certificates.X509Certificate2
    # .EXAMPLE
    #   Get-CACertificate | ConvertTo-X509Certificate
    # .EXAMPLE
    #   Get-CACertificateRequest -RequestID 19 | ConvertTo-X509Certificate
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/02/2015 - Chris Dent - First release.
  
    [CmdletBinding(DefaultParameterSetName = "FromPipeline")]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName = "FromPipeline")]
        [Alias('RawCertificate')]
        [String]$Certificate,
        
        [Parameter(ParameterSetName = "FromFile")]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [String]$Path
    )
  
    process {
        if (-not $Certificate -and -not $Path) {
            Write-Error "Either a Base64 encoded string or a certificate file must be specified."
        } else {
            if ($pscmdlet.ParameterSetName -eq "FromPipeline") {
                if ($Certificate -notmatch '^-----BEGIN CERTIFICATE-----') {
                    # Wrap a RawCertificate string in a header and footer.
                    $Certificate = "-----BEGIN CERTIFICATE-----`r`n$Certificate`r`n-----END CERTIFICATE-----"
                }
              
                $Certificate | Out-File "$env:temp\Certificate.cer" -Encoding UTF8
                $Path = "$env:temp\Certificate.cer"
            }
            
            New-Object X509Certificate2($Path)
            
            if ($pscmdlet.ParameterSetName -eq "FromPipeline") {
                Remove-Item $Path
            }
        }
    }
}