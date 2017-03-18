using namespace System.Management.Automation
using namespace System.Security.Cryptography.X509Certificates

function Get-Certificate {
    # .SYNOPSIS
    #   Get certificates from a local or remote certificate store.
    # .DESCRIPTION
    #   Get X509 certificates from a certificate store.
    # .PARAMETER ComputerName
    #   An optional ComputerName to use for this query. If ComputerName is not specified Get-Certificate uses the current computer.
    # .PARAMETER Expired
    #   Filter results to only include expired certificates.
    # .PARAMETER ExpiresOn
    #   Filter restults to only include certificates which expire on the specified day (between 00:00:00 and 23:59:59).
    #
    #   This parameter may be used in conjunction with Expired to find certificates which expired on a specific day.
    # .PARAMETER HasPrivateKey
    #   Filter results to only include certificates which have a private key available.
    # .PARAMETER Request
    #   Show pending certificate requests.
    # .PARAMETER StoreLocation
    #   Get-Certificate gets certificates from the LocalMachine store. The CurrentUser store may be specified.
    # .PARAMETER StoreName
    #   Get-Certificate gets certificates from all stores. A specific store name, or list of store names, may be supplied if required.
    # .INPUTS
    #   System.Security.Cryptography.X509Certificates.StoreName
    #   System.Security.Cryptography.X509Certificates.StoreLocation
    #   System.String
    # .EXAMPLE
    #   Get-Certificate -StoreName My -StoreLocation CurrentUser
    #
    #   Get all certificates from the Personal store for the CurrentUser (caller).
    # .EXAMPLE
    #   Get-Certificate -StoreLocation LocalMachine -Request
    #
    #   Get pending certificate requests.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     03/03/2015 - Chris Dent - Changed Subject Alternate Names decode to drop line breaks.
    #     02/03/2015 - Chris Dent - Added EnhangedKeyUsages property to base object.
    #     27/02/2015 - Chris Dent - Merged store queries into a single statement. Added decode support for Subject Alternate Names.
    #     09/02/2015 - Chris Dent - BugFix: Parameter existence check for ExpiresOn.
    #     04/02/2015 - Chris Dent - Added Issuer and NotAfter parameters.
    #     22/01/2015 - Chris Dent - Added Request parameter.
    #     24/06/2014 - Chris Dent - Added HasPrivateKey and Expired parameters.
    #     12/06/2014 - Chris Dent - First release.  

    [CmdletBinding(DefaultParameterSetName = 'Certificate')]
    param(
        [Parameter(ParameterSetName = 'Certificate')]
        [StoreName[]]$StoreName = [Enum]::GetNames([StoreName]),

        [StoreLocation]$StoreLocation = "LocalMachine",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('ComputerNameString', 'Name')]
        [String]$ComputerName = $env:ComputerName,

        [Switch]$HasPrivateKey,

        [Switch]$Expired,

        [ValidateScript( { Get-Date $_ } )]
        $ExpiresOn,

        [ValidateNotNullOrEmpty()]
        [String]$Issuer,

        [Parameter(ParameterSetName = 'Request')]
        [Switch]$Request
    )

    begin {
        if ($StoreLocation -ne [StoreLocation]::LocalMachine -and $ComputerName -ne $env:ComputerName) {
            $errorRecord = New-Object ErrorRecord(
                (New-Object ArgumentException("Certificates in the CurrentUser location cannot be read remotely.")),
                'InvalidParameterValues',
                [ErrorCategory]::InvalidArgument,
                $null
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        $whereStatementText = New-Object StringBuilder
        $whereStatementText.Append('$_')
        if ($HasPrivateKey) {
            $null = $whereStatementText.Append(' -and $_.HasPrivateKey')
        }
        if ($Expired) {
            $null = $whereStatementText.Append(' -and $_.NotAfter -lt (Get-Date)')
        }
        if ($psboundparameters.ContainsKey("ExpiresOn")) {
            $null = $whereStatementText.Append(' -and $_.NotAfter -gt (Get-Date $ExpiresOn).Date -and $_.NotAfter -lt (Get-Date $ExpiresOn).Date.AddDays(1).AddSeconds(-1)')
        }
        if ($psboundparameters.ContainsKey("Issuer")) {
            $null = $whereStatementText.Append(' -and $_.Issuer -like "*CN=$Issuer*"')
        }
        $WhereStatement = [ScriptBlock]::Create($whereStatementText.ToString())
    }

    process {
        if ($Request) {
            $StoreNames = 'REQUEST'
        } else {
            $StoreNames = $StoreName
        }

        $StoreNames | ForEach-Object {
            if ($ComputerName -eq $env:ComputerName) {
                $StorePath = $_
            } else {
                $StorePath = "\\$ComputerName\$_"
            }

            try {
                $Store = New-Object X509Store($StorePath, $StoreLocation)
                $Store.Open([OpenFlags]::ReadOnly)

                $Store.Certificates |
                    Add-Member StorePath -MemberType NoteProperty -Value $StorePath -PassThru |
                    Add-Member ComputerName -MemberType NoteProperty -Value $ComputerName -PassThru |
                    Add-Member SubjectAlternativeNames -MemberType ScriptProperty -Value {
                        if ($this.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' }) {
                            $this.Extensions['2.5.29.17'].Format($false)
                        }
                    } -PassThru |
                    Add-Member EnhancedKeyUsages -MemberType ScriptProperty -Value {
                        if ($this.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.37' }) {
                            foreach ($usage in $this.Extensions['2.5.29.37'].EnhancedKeyUsages) {
                                $usage | Add-Member ToString -MemberType ScriptMethod -Force -PassThru -Value {
                                    "$($this.Value) ($($this.FriendlyName))"
                                }
                            }
                        }
                    } -PassThru |
                    Where-Object $WhereStatement

                $Store.Close()
            } catch {
                throw
            }
        }
    }
}