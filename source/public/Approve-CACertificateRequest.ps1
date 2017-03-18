using namespace Indented.PKI
using namespace System.ComponentModel
using namespace System.Management.Automation

function Approve-CACertificateRequest {
    # .SYNOPSIS
    #   Approve a certificate request and issue the certificate.
    # .DESCRIPTION
    #   Approve a pending certificate request on the specified CA and issue the certificate.
    # .PARAMETER CA
    #   A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .PARAMETER ComputerName
    #   The ComputerName parameter is provided to support a pipeline from Approve-CertificateRequest to Complete-Certificate. 
    # .PARAMETER Credential
    #   The Credential parameter is provided to support a pipeline from Approve-CertificateRequest to Complete-Certificate.
    # .PARAMETER RemoteWorkingDirectory
    #   The working path for remote operations. By default C:\Windows\Temp is used. The RemoteWorkingDirectory parameter is provided to support a pipeline from Approve-CertificateRequest to Complete-Certificate.
    # .PARAMETER RequestID
    #   A request ID must be supplied for approval.
    # .INPUTS
    #   System.Int32
    #   System.String
    # .OUTPUTS
    #   Indented.PKI.CertificateRequest
    # .EXAMPLE
    #   Get-CACertificateRequest -Pending | Approve-CACertificateRequest
    #
    #   Approve and issue all pending certificates on the default CA.
    # .EXAMPLE
    #   Approve-CACertificateRequest -RequestID 9
    #
    #   Approve and issue certificate request 9 on the default CA.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     24/02/2015 - Chris Dent - BugFix: Missing CA parameter when getting Issued certificates.
    #     13/02/2015 - Chris Dent - Modified pipeline to accept additional parameters for the Submit to Receive pipeline.
    #     05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
    #     04/02/2015 - Chris Dent - Allowed CmdLet to immediately return certificates which are already approved.
    #     03/02/2015 - Chris Dent - Modified input pipeline.
    #     02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
    #     29/01/2015 - Chris Dent - First release.

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Int32]$RequestID,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$RemoteWorkingDirectory = "C:\Windows\Temp",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$ComputerName = $env:ComputerName,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [PSCredential]$Credential
    )

    begin {
        if (-not (Test-Path "$env:WinDir\System32\certadm.dll") -or -not (Test-Path "$env:WinDir\System32\certcli.dll")) {
            $errorRecord = New-Object ErrorRecord(
                (New-Object InvalidOperationException 'The Certification Authority tools must be installed to use this command.'),
                'MissingAdminTools',
                [ErrorCategory]::OperationStopped,
                $pscmdlet
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }
    }

    process {
        if (-not $RequestID) {
            $errorRecord = New-Object ErrorRecord(
                (New-Object ArgumentException 'A request ID must be supplied.'),
                'InvalidRequestID',
                [ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        if (-not $CA) {
            $errorRecord = New-Object ErrorRecord(
                (New-Object ArgumentException 'The CA parameter is mandatory.'),
                'ArgumentException',
                [ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        $CertificateRequest = Get-CACertificateRequest -RequestID $RequestID -CA $CA
        $CAAdmin = New-Object -COMObject CertificateAuthority.Admin

        if ($CertificateRequest.'Request.Disposition' -eq [CertificateRequest.Disposition]::Issued) {
            # If the certificate is issued, immediately return it.
            Write-Warning "Request ID: $($CertificateRequest.RequestID) ($($CertificateRequest.CommonName)): Certificate already issued. Approval is not required, returning issued certificate."

            $CertificateRequest
        } elseif ($CertificateRequest.'Request.Disposition' -ne [CertificateRequest.Disposition]::Pending) {
            Write-Warning "Request ID: $($CertificateRequest.RequestID) ($($CertificateRequest.CommonName)): Certificate request must be pending to issue certificate."
        } else {
            Write-Verbose "Approve-CACertificateRequest: $($ComputerName): Receiving certificate using $($CertificateRequest.RequestID)"

            if ($pscmdlet.ShouldProcess("Issuing certificate Request ID: $($CertificateRequest.RequestID) ($($CertificateRequest.CommonName))")) {
                try {
                    [CAResponse.Disposition]$CAResponse = $CAAdmin.ResubmitRequest($CA,  $CertificateRequest.RequestID)
                } catch {
                    # Exceptions will be trapped as method invocation. Create specific exception types based on the Win32Exception number in the error message.
                    if ($_.Exception.Message -match 'CCert[^:]+::[^:]+: .*WIN32: (\d+)') {
                        $errorRecord = New-Object ErrorRecord(
                            (New-Object Win32Exception([Int32]$matches[1])),
                            $_.Exception.Message,
                            [ErrorCategory]::OperationStopped,
                            $CA
                        )
                    }
                    if (-not $errorRecord) {
                        $errorRecord = New-Object ErrorRecord(
                            $_.Exception,
                            $_.Exception.Message,
                            [ErrorCategory]::OperationStopped,
                            $pscmdlet
                        )
                    }
                    $pscmdlet.ThrowTerminatingError($errorRecord)
                }

                if ($CAResponse -ne [CAResponse.Disposition]::Issued) {
                    Write-Error $CAResponse
                } else {
                    $IssuedCertificate = Get-CACertificateRequest -RequestID $CertificateRequest.RequestID -Issued -CA $CA
                    if ($psboundparameters.ContainsKey("ComputerName")) {
                        $IssuedCertificate.ComputerName = $ComputerName
                    }
                    if ($psboundparameters.ContainsKey("RemoteWorkingDirectory")) {
                        $IssuedCertificate | Add-Member RemoteWorkingDirectory -MemberType NoteProperty -Value $RemoteWorkingDirectory
                    }
                    if ($psboundparameters.ContainsKey("Credential")) {
                        $IssuedCertificate | Add-Member Credential -MemberType NoteProperty -Value $Credential
                    }

                    return $IssuedCertificate
                }
            }
        }
    }
}