function Get-Certificate {
    <#
    .SYNOPSIS
        Get certificates from a local or remote certificate store.
    .DESCRIPTION
        Get certificates from a local or remote certificate store.
    .INPUTS
        System.String
    .EXAMPLE
        Get-Certificate -StoreName My -StoreLocation CurrentUser

        Get all certificates from the Personal store for the CurrentUser (caller).
    .EXAMPLE
        Get-Certificate -StoreLocation LocalMachine -Request

        Get pending certificate requests.
    .NOTES
        Change log:
            03/03/2015 - Chris Dent - Changed Subject Alternate Names decode to drop line breaks.
            02/03/2015 - Chris Dent - Added EnhangedKeyUsages property to base object.
            27/02/2015 - Chris Dent - Merged store queries into a single statement. Added decode support for Subject Alternate Names.
            09/02/2015 - Chris Dent - BugFix: Parameter existence check for ExpiresOn.
            04/02/2015 - Chris Dent - Added Issuer and NotAfter parameters.
            22/01/2015 - Chris Dent - Added Request parameter.
            24/06/2014 - Chris Dent - Added HasPrivateKey and Expired parameters.
            12/06/2014 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'Certificate')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param (
        # Get-Certificate gets certificates from all stores. A specific store name, or list of store names, may be supplied if required.
        [Parameter(ParameterSetName = 'Certificate')]
        [System.Security.Cryptography.X509Certificates.StoreName[]]$StoreName = [Enum]::GetNames([StoreName]),

        # Get-Certificate gets certificates from the LocalMachine store. The CurrentUser store may be specified.
        [System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

        # An optional ComputerName to use for this query. If ComputerName is not specified Get-Certificate uses the current computer.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('ComputerNameString', 'Name')]
        [String]$ComputerName = $env:ComputerName,

        # Filter results to only include certificates which have a private key available.
        [Switch]$HasPrivateKey,

        # Filter results to only include expired certificates.
        [Switch]$Expired,

        <#
            Filter restults to only include certificates which expire on the specified day (between 00:00:00 and 23:59:59).

            This parameter may be used in conjunction with Expired to find certificates which expired on a specific day.
        #>
        [ValidateScript( { Get-Date $_ } )]
        $ExpiresOn,

        [ValidateNotNullOrEmpty()]
        [String]$Issuer,

        # Show pending certificate requests.
        [Parameter(ParameterSetName = 'Request')]
        [Switch]$Request
    )

    begin {
        $whereStatementText = New-Object System.Text.StringBuilder
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
                $Store = New-Object System.Security.Cryptography.X509Certificates.X509Store($StorePath, $StoreLocation)
                $Store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)

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