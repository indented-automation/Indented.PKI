using namespace Indented.PKI
using namespace System.ComponentModel
using namespace System.Management.Automation

function Get-CACertificate {
    # .SYNOPSIS
    #   Get signing certificate used by a CA.
    # .DESCRIPTION
    #   Get-CACertificate requests the certificate used by a CA to sign content.
    #
    #   The signing certificate must be trusted by the client operating system to install a certificate issued by the CA.
    # .PARAMETER CA
    #   A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.String
    # .EXAMPLE
    #   Get-CACertificate -CA "SomeServer\SomeCA"
    #
    #   Get the Base64 encoded signing certificate from the specified CA.
    # .EXAMPLE
    #   Get-CACertificate | Out-File CACert.cer -Encoding UTF8
    #
    #   Get the Base64 encoded signing certificate from the default CA and save it in a certificate file called CACert.cer.
    # .EXAMPLE
    #   Get-CACertificate | ConvertTo-CACertificate | Install-Certificate -StoreName Root
    #
    #   Get the signing certicate from the default CA and install it in the trusted root CA store on the local machine.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
    #     30/01/2015 - Chris Dent - First release.

    [CmdletBinding()]
    param(
        [String]$CA = (Get-DefaultCA)
    )
  
    begin {
        if (-not $CA) {
            $errorRecord = New-Object ErrorRecord(
                (New-Object ArgumentException "The CA parameter is mandatory."),
                "ArgumentException",
                [ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        $CARequest = New-Object -COMObject CertificateAuthority.Request
        
        try {
            $CARequest.GetCACertificate(
                $false,
                $CA,
                [CertificateRequest.Encoding]::CR_OUT_BASE64HEADER
            )
        } catch {
            # Exceptions will be trapped as method invocation. Create specific exception types based on the Win32Exception number in the error message.
            if ($_.Exception.Message -match 'CCert[^:]+::[^:]+: .*WIN32: (\d+)') {
                $errorRecord = New-Object ErrorRecord(
                    (New-Object ComponentModel.Win32Exception([Int32]$matches[1])),
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
    }
}