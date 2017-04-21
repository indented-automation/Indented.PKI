function Complete-Certificate {
    <#
    .SYNOPSIS
        Complete an issued certificate request (a signed public key) from a CA.
    .DESCRIPTION
        Complete-Certificate remotely executes the certreq command to complete an issued certificate using the specifieid certificate (Base64 encoded string or an .cer / PKCS7 file).
    .INPUTS
        System.String
    .EXAMPLE
        Complete-Certificate -Path certificate.cer

        Complete a certificate request using certificate.cer on the local machine.
    .EXAMPLE
        Receive-Certificate -RequestID 9 | Complete-Certificate

        Receive a certicate request issued by the default CA using certreq and use the resulting signed public key to complete a pending request.
    .EXAMPLE
        Receive-CACertificateRequest -RequestID 23 | Complete-Certificate

        Receive a certicate request issued by the default CA using the certificate management API and use the resulting signed public key to complete a pending request.
    .EXAMPLE
        Complete-Certificate -Path C:\Temp\Certificate.cer -ComputerName SomeComputer

        Complete a certificate request using C:\Temp\Certificate.cer on SomeComputer.
    .NOTES
        Change log:
            09/02/2015 - Chris Dent - Added quiet parameter to certreq.
            04/02/2015 - Chris Dent - Improved handling and validation of the Path parameter.
            03/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromCertificate')]
    param (
        # The certificate as a Base64 encoded string with a header and footer.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FromCertificate')]
        [String]$Certificate,

        # The path to the certificate file containing a signed public key. 
        [Parameter(ParameterSetName = "FromFile")]
        [Alias('FullName')]
        [String]$Path
    )

    process {
        # The name of the file must exist on the remote server but we don't need to be able to read it here (certreq does).
        # If a CER string has been passed it needs saving to a file.
        if ($psboundparameters.ContainsKey("Certificate")) {
            $Path = $FileName = "Certificate.cer"
            $Certificate | Out-File $Path -Encoding UTF8
        } else {
            $FileName = Split-Path $Path -Leaf
        }

        $Command = "certreq -accept -q ""$Path"""

        Write-Verbose "Complete-Certificate: $($ComputerName): Executing $Command"
        
        $Response = & "cmd.exe" "/c", $Command
        if ($lastexitcode -ne 0) {
            Write-Error "Complete-Certificate: $($ComputerName): certreq returned $lastexitcode - $Response"
        }
    }
}