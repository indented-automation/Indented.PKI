function ConvertTo-X509Certificate {
    <#
    .SYNOPSIS
        Convert a Base64 encoded certificate (with header and footer) to an X509Certificate object.
    .DESCRIPTION
        ConvertTo-X509Certificate reads a Base64 encoded certificate string or file and converts it to an X509Certificate object.
    .INPUTS
        System.String
    .EXAMPLE
        Get-CACertificate | ConvertTo-X509Certificate
    .EXAMPLE
        Get-CACertificateRequest -RequestID 19 | ConvertTo-X509Certificate
    .NOTES
        Change log:
            04/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param (
        # A base64 encoded string describing the certificate.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
        [Alias('RawCertificate')]
        [String]$Certificate,

        # A path to an existing certificate file.
        [Parameter(Mandatory = $true, ParameterSetName = 'FromFile')]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [String]$Path
    )

    process {
        if ($pscmdlet.ParameterSetName -eq "FromPipeline") {
            if ($Certificate -notmatch '^-----BEGIN CERTIFICATE-----') {
                # Wrap a RawCertificate string in a header and footer.
                $Certificate = "-----BEGIN CERTIFICATE-----`r`n$Certificate`r`n-----END CERTIFICATE-----"
            }

            $Certificate | Out-File "$env:temp\Certificate.cer" -Encoding UTF8
            $Path = "$env:temp\Certificate.cer"
        }

        New-Object Security.Cryptography.X509Certificates.X509Certificate2($Path)

        if ($pscmdlet.ParameterSetName -eq "FromPipeline") {
            Remove-Item $Path
        }
    }
}