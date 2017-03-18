function Receive-CACertificateRequest {
    # .SYNOPSIS
    #   Receive an issued certificate request from a CA.
    # .DESCRIPTION
    #   Receive an issued certificate request from a CA as a Base64 encoded string (with header and footer).
    # .PARAMETER AndComplete
    #   Completion of the certificate request is, by default, a separate step. Immediate completion may be requested by setting this parameter.
    # .PARAMETER CA
    #   A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .PARAMETER CertificateRequest
    #   A pending certificate request returned from Get-CACertificateRequest.
    # .PARAMETER CommonName
    #   CommonName is an optional parameter used to preserve a CommonName value while operating in pipeline mode. The parameter is optional and is used to name temporary files only.
    # .PARAMETER ComputerName
    #   The ComputerName parameter is provided to support a pipeline from Approve-CertificateRequest to Complete-Certificate. 
    # .PARAMETER Credential
    #   The Credential parameter is provided to support a pipeline from Approve-CertificateRequest to Complete-Certificate.
    # .PARAMETER RemoteWorkingDirectory
    #   The working path for remote operations. By default C:\Windows\Temp is used. The RemoteWorkingDirectory parameter is provided to support a pipeline from Approve-CertificateRequest to Complete-Certificate.
    # .PARAMETER RequestID
    #   A request ID must be supplied to receive a certificate.
    # .EXAMPLE
    #   Get-CACertificateRequest -RequestID 3 -Issued | Receive-CACertificateRequest
    #
    #   Receive an issued request and display the received certificate object.
    # .EXAMPLE
    #   Receive-CACertificateRequest -RequestID 9 | ConvertTo-X509Certificate
    #
    #   Receive an issued request and convert the request into an X509Certificate object.
    # .EXAMPLE
    #   Receive-CACertificateRequest -RequestID 2 | Complete-Certificate
    #
    #   Receive the certificate request and install the signed public key into an existing (incomplete) certificate request.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
    #     04/02/2015 - Chris Dent - Added CommonName as a pipeline parameter. Added AndComplete parameter. BugFix: Bad pipeline.
    #     02/02/2015 - Chris Dent - Added support for Get-DefaultCA.
    #     30/01/2015 - Chris Dent - First release.

    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'FindRequest')]
        [Int32]$RequestID,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CommonName = "Certificate",

        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
        [PSTypeNames('Indented.PKI.CertificateRequest')]
        $CertificateRequest,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

        [Switch]$AndComplete,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$RemoteWorkingDirectory = "C:\Windows\Temp",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
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

        if ($psboundparameters.ContainsKey("RequestID")) {
            Get-CACertificateRequest -RequestID $RequestID -Issued -CA $CA | Receive-CACertificateRequest
        } else {
            $CARequest = New-Object -COMObject CertificateAuthority.Request
        }
    }

    process {
        if (-not $CA) {
            $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object ArgumentException "The CA parameter is mandatory."),
                "ArgumentException",
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($ErrorRecord)
        }

        if ($CertificateRequest) {
            if ($CertificateRequest."Request.Disposition" -ne [CertificateRequest.Disposition]::Issued) {
                Write-Warning "Request ID: $($CertificateRequest.RequestID) ($($CertificateRequest.CommonName)): Certificate request must be issued to receive certificate."
            } else {
                Write-Verbose "Receive-CACertificateRequest: $($ComputerName): Receiving certificate using $($CertificateRequest.RequestID)"

                try {
                    $CAResponse = $CARequest.GetIssuedCertificate($CA, $CertificateRequest.RequestID, $null)
                } catch {
                    $pscmdlet.ThrowTerminatingError((NewWin32ErrorRecord $_))
                }

                if ($CAResponse -eq [Response.Disposition]::Issued) {
                    $ReceivedCertificate = [PSCustomObject]@{
                        ComputerName           = $ComputerName
                        Credential             = $Credential
                        RemoteWorkingDirectory = $RemoteWorkingDirectory
                        CommonName             = $CommonName
                        Certificate            = $CARequest.GetCertificate([CertificateRequest.Encoding]::CR_OUT_BASE64HEADER)
                        CA                     = $CA
                        Disposition            = "Received"
                    } | Add-Member -TypeName "Indented.PKI.Certificate.ReceivedCertificate" -PassThru

                    if ($AndComplete) {
                        $ReceivedCertificate | Complete-Certificate
                    } else {
                        return $ReceivedCertificate
                    }
                }
            }
        }
    }
}