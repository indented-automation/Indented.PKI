function Submit-CASigningRequest {
    <#
    .SYNOPSIS
        Submit a CSR to a Microsoft CA.
    .DESCRIPTION
        Submit an existing CSR file to a certificate authority using the certificate services API.

        A CSR may be submitted from any system which can reach the CA. It does not need to be submitted from the system holding the private key.
    .INPUTS
        System.String
    .EXAMPLE
        Submit-CASigningRequest -Path c:\temp\cert.csr

        Submit the CSR found in c:\temp\cert.csr to the default CA.
    .EXAMPLE
        Submit-CASigningRequest -SigningRequest $CSR -CA "ServerName\CA Name"

        Submit the value held in the variable CSR to the CA "CA Name"
    .EXAMPLE
        New-Certificate -Subject "CN=localhost" -ClientAuthentication | Submit-CASigningRequest

        Create a certificate with the specified subject and the ClientAuthentication enhanced key usage. Submit the resulting SigningRequest to the default CA.
    .NOTES
        Change log:
            05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
            04/02/2015 - Chris Dent - First release.
    #>

    [CmdletBinding(DefaultParameterSetName = "FromSigningRequest")]
    param(
        # The CSR as a string. The CSR string will be saved to a temporary file for submission to the CA.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "FromSigningRequest")]
        [String]$SigningRequest,

        # A file containing a CSR. If using the ComputerName parameter the path is relative to the remote system.
        [Parameter(ParameterSetName = 'FromFile')]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [Alias('FullName')]
        [String]$Path,

        # A string which idntifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA)
    )

    begin {
        try {
            $caRequest = New-Object -COMObject CertificateAuthority.Request
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            [Indented.PKI.CAAdmin.ResponseDisposition]$caResponse = $caRequest.Submit(
                ([Indented.PKI.CertificateRequestEncoding]::CR_IN_BASE64HEADER),
                $SigningRequest,
                $null,
                $CA
            )

        if ($CertificateRequest) {
            $RequestDisposition = [PSCustomObject]@{
                CommonName             = $CertificateRequest.CommonName
                RequestID              = $CertificateRequest.RequestID
                Response               = $CertificateRequest.'Request.DispositionMessage'
                CA                     = $CA
                Disposition            = 'Pending'
            } | Add-Member -TypeName 'Indented.PKI.Request' -PassThru
        } else {
            $caResponse
        }


        } catch {
            Write-Error -ErrorRecord (NewCAError $_)
        }
    }

    end {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caRequest)
    }
}