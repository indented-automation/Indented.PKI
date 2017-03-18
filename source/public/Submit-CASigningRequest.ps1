function Submit-CASigningRequest {
    # .SYNOPSIS
    #   Submit a CSR to a Microsoft CA.
    # .DESCRIPTION
    #   Submit an existing CSR file to a certificate authority using the certificate services API.
    #
    #   A CSR may be submitted from any system which can reach the CA. It does not need to be submitted from the system holding the private key.
    # .PARAMETER CA
    #   A string which idntifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .PARAMETER CommonName
    #   CommonName is an optional parameter used to preserve a CommonName value while operating in pipeline mode. The parameter is optional and is used to name temporary files only.
    # .PARAMETER ComputerName
    #   The ComputerName parameter is provided to support a pipeline from New-Certificate to Receive-Certificate or Receive-CASigningRequest. 
    # .PARAMETER Credential
    #   The credential parameter is provided to support a pipeline from New-Certificate to Receive-Certificate or Receive-CASigningRequest. 
    # .PARAMETER Path
    #   A file containing a CSR. If using the ComputerName parameter the path is relative to the remote system.
    # .PARAMETER RemoteWorkingDirectory
    #   The working path for remote operations. By default C:\Windows\Temp is used. The RemoteWorkingDirectory parameter is provided to support a pipeline from New-Certificate to Receive-Certificate or Receive-CASigningRequest.
    # .PARAMETER SigningRequest
    #   The CSR as a string. The CSR string will be saved to a temporary file for submission to the CA.
    # .INPUTS
    #   System.Management.Automation.PSCredential
    #   System.String
    # .OUTPUTS
    #   Indented.PKI.RequestDisposition
    # .EXAMPLE
    #   Submit-CASigningRequest -Path c:\temp\cert.csr
    #
    #   Submit the CSR found in c:\temp\cert.csr to the default CA.
    # .EXAMPLE
    #   Submit-CASigningRequest -SigningRequest $CSR -CA "ServerName\CA Name"
    #
    #   Submit the value held in the variable CSR to the CA "CA Name"
    # .EXAMPLE
    #   New-Certificate -Subject "CN=localhost" -ClientAuthentication | Submit-CASigningRequest
    #
    #   Create a certificate with the specified subject and the ClientAuthentication enhanced key usage. Submit the resulting SigningRequest to the default CA.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
    #     04/02/2015 - Chris Dent - First release.

    [CmdletBinding(DefaultParameterSetName = "FromSigningRequest")]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "FromSigningRequest")]
        [ValidateNotNullOrEmpty()]
        [String]$SigningRequest,

        [Parameter(ParameterSetName = "FromFile")]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [String]$Path,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CommonName = "SigningRequest",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$RemoteWorkingDirectory = "C:\Windows\Temp",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ComputerName = $env:ComputerName,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]$Credential
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

        $CARequest = New-Object -COMObject CertificateAuthority.Request
    }

    process {
        if (-not $CA) {
            $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object ArgumentException "The CA parameter is mandatory."),
                "ArgumentException",
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $CA
            )
            $pscmdlet.ThrowTerminatingError($ErrorRecord)
        }

        try {
            [ResponseDisposition]$CAResponse = $CARequest.Submit(
                ([CertificateRequest.Encoding]::CR_IN_BASE64HEADER),
                $SigningRequest,
                "",
                $CA
            )
        } catch {
            $pscmdlet.ThrowTerminatingError((NewWin32ErrorRecord $_))
        }

        # Best effort method of finding the new certificate request (issued or pending)
        if ($CAResponse -eq [CAResponse.Disposition]::Issued) {
            $CertificateRequest = Get-CACertificateRequest -RequesterName (whoami) -Issued -CA $CA | Sort-Object RequestId | Select-Object -Last 1
        } elseif ($CAResponse -eq [CAResponse.Disposition]::UnderSubmission) {
            $CertificateRequest = Get-CACertificateRequest -RequesterName (whoami) -Pending -CA $CA | Sort-Object RequestId | Select-Object -Last 1
        }

        if ($CertificateRequest) {
            [PSCustomObject]@{
                ComputerName           = $ComputerName
                Credential             = $Credential
                RemoteWorkingDirectory = $RemoteWorkingDirectory
                CommonName             = $CertificateRequest.CommonName
                RequestID              = $CertificateRequest.RequestID
                Response               = $CertificateRequest.'Request.DispositionMessage'
                CA                     = $CA
                Disposition            = "Pending"
            } | Add-Member -TypeName "Indented.PKI.Certificate.RequestDisposition" -PassThru
        } else {
            $CAResponse
        }
    }
}