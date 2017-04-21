function Get-CACertificate {
    <#
    .SYNOPSIS
        Get signing certificate used by a CA.
    .DESCRIPTION
        Get-CACertificate requests the certificate used by a CA to sign content.

        The signing certificate must be trusted by the client operating system to install a certificate issued by the CA.
    .EXAMPLE
        Get-CACertificate -CA "SomeServer\SomeCA"

        Get the Base64 encoded signing certificate from the specified CA.
    .EXAMPLE
        Get-CACertificate | Out-File CACert.cer -Encoding UTF8

        Get the Base64 encoded signing certificate from the default CA and save it in a certificate file called CACert.cer.
    .EXAMPLE
        Get-CACertificate | ConvertTo-CACertificate | Install-Certificate -StoreName Root

        Get the signing certicate from the default CA and install it in the trusted root CA store on the local machine.
    .NOTES
        Change log:
            02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
            30/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    [OutputType([String])]
    param (
        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [String]$CA = (Get-DefaultCA)
    )

    try {
        $caRequest = New-Object -ComObject CertificateAuthority.Request
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    }

    try {
        $caRequest.GetCACertificate(
            $false,
            $CA,
            [Indented.PKI.CertificateRequestEncoding]::CR_OUT_BASE64HEADER
        )
    } catch {
        # Exceptions will be trapped as method invocation. Create specific exception types based on the Win32Exception number in the error message.
        Write-Error -ErrorRecord (NewCAError $_)
    }

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caRequest)
}