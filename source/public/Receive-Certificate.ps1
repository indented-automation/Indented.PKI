function Receive-Certificate {
    # .SYNOPSIS
    #   Receive an issued certificate request (a signed public key) from a CA.
    # .DESCRIPTION
    #   Receive-Certificate remotely executes the certreq command to attempt to retrieve an issued certificate from the specified CA.
    # .PARAMETER AndComplete
    #   Completion of the certificate request is, by default, a separate step. Immediate completion may be requested by setting this parameter.
    # .PARAMETER CA
    #   A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .PARAMETER CommonName
    #   CommonName is an optional parameter used to preserve a CommonName value while operating in pipeline mode. The parameter is optional and is used to name temporary files only.
    # .PARAMETER ComputerName
    #   The name of the computer to execute against.
    # .PARAMETER Credential
    #   Credentials to use for this operation.
    #
    #   Credentials are mandatory for certificate operations against remote servers.
    # .PARAMETER RemoteWorkingDirectory
    #   The working path for remote operations. By default C:\Windows\Temp is used.
    # .PARAMETER RequestID
    #   The request ID number for an existing issued certificate on the specified (or default) CA.
    # .INPUTS
    #   System.Management.Automation.PSCredential
    #   System.String
    # .OUTPUTS
    #   Indented.PKI.Certificate.ReceivedCertificate
    # .EXAMPLE
    #   Receive-Certificate -RequestID 23
    #
    #   Attempt to receive certificate request 23 from the default CA.
    # .EXAMPLE
    #   Receive-Certificate -RequestID 1220 -CA "ServerName\Alt CA 01"
    #
    #   Receive request 1220 from the CA "Alt CA 01".
    # .EXAMPLE
    #   Receive-Certificate -RequestID 93 
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     24/02/2015 - Chris Dent - BugFix: CA is mandatory.
    #     09/02/2015 - Chris Dent - Added quiet parameter to certreq.
    #     04/02/2015 - Chris Dent - Added AndComplete parameter.
    #     03/02/2015 - Chris Dent - First release.

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Int32]$RequestID,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CommonName = "Certificate",

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
        if (-not $RequestID) {
            $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object ArgumentException "A request ID must be supplied."),
                "ArgumentException",
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($ErrorRecord)
        }

        $IsLocal = $false
        if ($ComputerName -in 'localhost', '127.0.0.1', $env:ComputerName, "$env:ComputerName.$env:UserDNSDomain") {
            $IsLocal = $true
        }
        if ($IsLocal -and $psboundparameters.ContainsKey("Credential") -and $Credential -ne $null) {
            Write-Error "Receive-SigningRequest: Credentials are not supported for local operations"
        } else {
            $Command = "certreq -retrieve -q -f -config ""$CA"" $RequestId ""$CommonName.cer"""

            Write-Verbose "Receive-Certificate: $($ComputerName): Executing $Command"

            if ($IsLocal) {
                $Response = & "cmd.exe" "/c", $Command
            } else {
                $InvokeParams = @{
                    Command          = $Command
                    ComputerName     = $ComputerName
                    ReturnFiles      = "$CommonName.cer"
                    WorkingDirectory = $RemoteWorkingDirectory
                }
                if ($psboundparameters.ContainsKey("Credential")) {
                    $InvokeParams.Add("Credential", $Credential)
                }

                $Response = Invoke-Command -UsePSExec @InvokeParams
            }

            if ($Response -match 'Taken Under Submission') {
                Write-Warning "Receive-Certificate: $($ComputerName): The certificate request is not yet approved."
            } else {
                if ($lastexitcode -eq 0) {
                    if (((Test-Path "ReturnFiles\$CommonName.cer") -or (Test-Path "$CommonName.cer"))) {
                        if ($IsLocal) {
                            Write-Host "Receive-Certificate: $($ComputerName): Certificate saved to $($pwd.Path)\$CommonName.cer" -ForegroundColor Yellow
                        } else {
                            Write-Host "Receive-Certificate: $($ComputerName): Certificate saved to $RemoteWorkingDirectory\$CommonName.cer" -ForegroundColor Yellow
                        }

                        # Construct a return object which will aid the onward pipeline.
                        $ReceivedCertificate = [PSCustomObject]@{
                            ComputerName           = $ComputerName
                            Credential             = $(if ($psboundparameters.ContainsKey("Credential")) { $Credential })
                            RemoteWorkingDirectory = $RemoteWorkingDirectory
                            CommonName             = $CommonName
                            Certificate            = $(if ($IsLocal) { Get-Content "$CommonName.cer" -Raw } else { Get-Content "ReturnFiles\$CommonName.cer" -Raw })
                            CA                     = $CA
                            Disposition            = "Received"
                        } | Add-Member -TypeName "Indented.PKI.Certificate.ReceivedCertificate" -PassThru

                        if ($AndComplete) {
                            $ReceivedCertificate | Complete-Certificate
                        } else {
                            return $ReceivedCertificate
                        }
                    } else {
                        Write-Error "$($ComputerName): Unable to access cer file $CommonName.cer."
                    }

                    if (Test-Path ReturnFiles) {
                        Remove-Item ReturnFiles -Recurse
                    }
                } else {
                    Write-Error "Receive-Certificate: $($ComputerName): certreq returned $lastexitcode - $Response"
                }
            }
        }
    }
}