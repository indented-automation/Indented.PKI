function Submit-SigningRequest {
    # .SYNOPSIS
    #   Submit a CSR to a Microsoft CA.
    # .DESCRIPTION
    #   Submit an existing CSR file to a certificate authority using certreq.
    #
    #   A CSR may be submitted from any system which can reach the CA. It does not need to be submitted from the system holding the private key.
    # .PARAMETER CA
    #   A string which idntifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .PARAMETER CommonName
    #   CommonName is an optional parameter used to preserve a CommonName value while operating in pipeline mode. The parameter is optional and is used to name temporary files only.
    # .PARAMETER ComputerName
    #   The name of the computer to execute against.
    # .PARAMETER Credential
    #   Credentials to use for this operation.
    #
    #   Credentials are mandatory for certificate operations against remote servers.
    # .PARAMETER Path
    #   A file containing a CSR. If using the ComputerName parameter the path is relative to the remote system.
    # .PARAMETER RemoteWorkingDirectory
    #   The working path for remote operations. By default C:\Windows\Temp is used.
    # .PARAMETER SigningRequest
    #   The CSR as a string. The CSR string will be saved to a temporary file for submission to the CA.
    # .INPUTS
    #   System.Management.Automation.PSCredential
    #   System.String
    # .OUTPUTS
    #   Indented.Certificate.RequestDisposition
    # .EXAMPLE
    #   Submit-SigningRequest -Path c:\temp\cert.csr
    #
    #   Submit the CSR found in c:\temp\cert.csr to the default CA.
    # .EXAMPLE
    #   Submit-SigningRequest -SigningRequest $CSR -CA "ServerName\CA Name"
    #
    #   Submit the value held in the variable CSR to the CA "CA Name"
    # .EXAMPLE
    #   New-Certificate -Subject "CN=localhost" -ClientAuthentication | Submit-SigningRequest
    #
    #   Create a certificate with the specified subject and the ClientAuthentication enhanced key usage. Submit the resulting SigningRequest to the default CA.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     03/03/2015 - Chris Dent - Changed CommonName to read from the file name when Path is specified. CSR is not decoded at this time.
    #     24/02/2015 - Chris Dent - Added Template parameter.
    #     09/02/2015 - Chris Dent - Added quiet parameter to certreq.
    #     04/02/2015 - Chris Dent - Fixed documentation.
    #     02/02/2015 - Chris Dent - Added support for Get-DefaultCA.
    #     27/01/2015 - Chris Dent - First release.

    [CmdletBinding(DefaultParameterSetName = "FromSigningRequest")]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = "FromSigningRequest")]
        [String]$SigningRequest,

        [Parameter(ParameterSetName = "FromFile")]
        [Alias('FullName')]
        [String]$Path,

        [ValidateNotNullOrEmpty()]
        [String]$Template,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CommonName = "SigningRequest",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

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
                $CA
            )
            $pscmdlet.ThrowTerminatingError($ErrorRecord)
        }

        if ($psboundparameters.ContainsKey("Path") -and $ComputerName -eq $env:ComputerName) {
            if (Test-Path $Path -PathType Leaf) {
                $Path = Get-Item $Path | Select-Object -ExpandProperty FullName
            } else {
                $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                    (New-Object ArgumentException "The specified certificate file path is invalid."),
                    "ArgumentException",
                    [Management.Automation.ErrorCategory]::InvalidArgument,
                    $Path
                )
                $pscmdlet.ThrowTerminatingError($ErrorRecord)
            }
        }

        if (-not $SigningRequest -and -not $Path) {
            $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object ArgumentException "A signing request string or file must be specified."),
                "ArgumentException",
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $Name)
            $pscmdlet.ThrowTerminatingError($ErrorRecord)
        }

        $IsLocal = $false
        if ($ComputerName -in 'localhost', '127.0.0.1', $env:ComputerName, "$env:ComputerName.$env:UserDNSDomain") {
            $IsLocal = $true
        }
        if ($IsLocal -and $psboundparameters.ContainsKey("Credential") -and $Credential -ne $null) {
            Write-Error "Submit-SigningRequest: Credentials are not supported for local operations"
        } else {
            # The name of the file must exist on the remote server but we don't need to be able to read it here (certreq does).
            # If a CSR string has been passed it needs saving to a file then submitting as a RequiredFile.
            if ($psboundparameters.ContainsKey("SigningRequest")) {
                $Path = $FileName = "$CommonName.csr"
                $SigningRequest | Out-File $Path -Encoding UTF8
            } else {
                $CommonName = (Split-Path $Path -Leaf) -replace '\.[^.]+$'
                $FileName = Split-Path $Path -Leaf
            }

            if ($psboundparameters.ContainsKey('Template')) {
                $Command = "certreq -submit -q -f -config ""$CA"" -attrib ""CertificateTemplate:$Template"" ""$Path"""
            } else {
                $Command = "certreq -submit -q -f -config ""$CA"" ""$Path"""
            }

            Write-Verbose "Submit-SigningRequest: $($ComputerName): Executing $Command"

            if ($IsLocal) {
                $Response = & "cmd.exe" "/c", $Command
            } else {
                $InvokeParams = @{
                    Command             = $Command
                    ComputerName        = $ComputerName
                    WorkingDirectory    = $RemoteWorkingDirectory
                }
                if ($psboundparameters.ContainsKey("SigningRequest")) {
                    $InvokeParams.Add("DeleteRequiredFiles", $false)
                    $InvokeParams.Add("RequiredFiles", $FileName)
                }
                if ($psboundparameters.ContainsKey("Credential")) {
                    $InvokeParams.Add("Credential", $Credential)
                }

                $Response = Invoke-Command -UsePSExec @InvokeParams
            }

            $RequestDisposition =[PSCustomObject]@{
                ComputerName           = $ComputerName
                Credential             = $(if ($psboundparameters.ContainsKey("Credential")) { $Credential })
                RemoteWorkingDirectory = $RemoteWorkingDirectory
                CommonName             = $CommonName
                RequestID              = $null
                Response               = $null
                CA                     = $CA
                Disposition            = "Pending"
            } | Add-Member -TypeName "Indented.PKI.Certificate.RequestDisposition" -PassThru

            $Response | ForEach-Object {
                if ($_ -match 'RequestId: (\d+)') {
                    $RequestDisposition.RequestID = $matches[1]
                } elseif ($_ -match 'RequestId') {
                    # Ignore this
                } else {
                    $RequestDisposition.Response = $_
                }
            }
            if (-not $RequestDisposition.RequestID) {
                Write-Error "Submit-SigningRequest: $($ComputerName): $($RequestDisposition.Response)"
            } else {
                return $RequestDisposition
            }
        }
    }
}