function New-Certificate {
    <#
    .SYNOPSIS
        Create a new certificate using the certreq command.
    .DESCRIPTION
        New-Certificate will generate a new key-pair. If SelfSigned is not specified a CSR is generated for submission to a certificate authority.

        New-Certificate uses the certreq utility to provide compatilbity with hosts which do not run PowerShell.
    .INPUTS
        System.Security.Cryptography.X509Certificates.X509Certificate2
    .EXAMPLE
        New-Certificate -Subject "CN=test-cert,OU=IT,O=Organisation,L=City,S=County,C=GB"

        Generate a new certificate using the specified Subject name, default key length and default key usages.
    .EXAMPLE
        New-Certificate -CommonName "test-cert" -Department IT -Organization Organisation -City City -County County -Country GB

        Generate a new certificate using the specified common name, department, organization, city, county and country.
    .EXAMPLE
        Get-Certificate -StoreName My -HasPrivateKey | New-Certificate -KeyLength 2048

        Generate new certificate requests based on the content of the personal store. Force the key length of the certificates to 2048 regardless of the existing value.
    .EXAMPLE
        Get-Certificate -StoreName My -HasPrivateKey -ExpiresOn "31/03/2015" | New-Certificate

        Generate certificate requests for each certificate in the local machines personal store (My) which has a private key and expires on the 31/03/2015.
    .EXAMPLE
        New-Certificate -Subject "CN=NewCertificate" -AndSubmit

        Create a new private and public key pair, generate a signing request and immediately submit the signing request to the default CA.
    .EXAMPLE
        New-Certificate -Subject "CN=NewCertificate" -AndComplete

        Using the default CA: Create a new private and public key pair, generate a signing request, submit the request to a CA, approve the certificate (if required), receive the new certificate and complete the request.
    .EXAMPLE
        New-Certificate -CommonName myusername -SubjectAlternativeNames (New-SubjectAlternativeNameRequest -UPN "myusername@domain.example") -ClientAuthentication

        Create a new Client Authentication certificate which uses myusername as the common name and contains a User Principal Name in the Subject Alternative Name in the form "Other Name:Principal Name=myusername@domain.example".
    .NOTES
        Change log:
            03/03/2015 - Chris Dent - Added support for KDC Authentication and Smartcard Logon. Added support for SubjectAlternativeName for operating systems newer than 2003.
            13/02/2015 - Chris Dent - Updated to use Invoke-Command for remote execution.
            09/02/2015 - Chris Dent - Added quiet parameter to certreq. BugFix: Test-Path test for CSR existence.
            04/02/2015 - Chris Dent - Added AndSubmit and AndComplete.
            02/02/2015 - Chris Dent - Added template handling. Modified to use New-PSDrive to access file share.
            26/01/2015 - Chris Dent - BugFix: OperatingSystem testing.
            23/01/2015 - Chris Dent - Added KeyUsage / Extension handling. Added Client / Server authentication extension support.
            22/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = "Subject")]
    param (
        # The common name of the certificate. The common name is used to construct the certificate subject.
        [Parameter(Mandatory = $true, ParameterSetName = 'CommonName')]
        [String]$CommonName,

        # An optional Department for the certificate subject.
        [Parameter(ParameterSetName = 'CommonName')]
        [String]$Department,

        # An optional Organization for the certificate subject.
        [Parameter(ParameterSetName = 'CommonName')]
        [String]$Organization,

        # An optional City for the certificate subject.
        [Parameter(ParameterSetName = 'CommonName')]
        [String]$City,

        # An optional County for the certificate subject.
        [Parameter(ParameterSetName = 'CommonName')]
        [String]$County,

        # An optional Country for the certificate subject.
        [Parameter(ParameterSetName = 'CommonName')]
        [String]$Country,

        [ValidateNotNullOrEmpty()]
        [String]$FriendlyName,

        # The certificate subject. Mandatory is CommonName (and other optional parameters) are not supplied.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Subject')]
        [ValidatePattern('^CN *=')]
        [String]$Subject,

        # A template name may be specified for this request.
        [String]$Template,

        # The Extensions parameter processes extensions applied to a certificate passed through an input pipeline. Note that this parameter will override any value held in KeyUsage.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Subject')]
        [System.Security.Cryptography.X509Certificates.X509ExtensionCollection]$Extensions,

        # The PublicKey parameter processes the PublicKey from a certificate passed through an input pipeline. Note that this parameter will override any value held in KeyLength unless KeyLength is explicitly assigned a value.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Subject')]
        [System.Security.Cryptography.X509Certificates.PublicKey]$PublicKey,

        # Attempt to create a self signed certificate rather than generating a signing request for the certificate.
        [Switch]$SelfSigned,

        # Add the Client Authentication enhanced key usage extension to the certificate.
        [Switch]$ClientAuthentication,

        # Add the Server Authentication enhanced key usage extension to the certificate.
        [Switch]$ServerAuthentication,

        # Add the KDC Authentication enhanced key usage extension to the certificate.
        [Switch]$KDCAuthentication,

        # Add the Smartcard Logon enhanced key usage extension to the certificate.
        [Switch]$SmartcardLogon,

        # The SubjectAlternativeNames to include in this request. The SubjectAlternativeNames paramter expects one of two values:
        #
        #  * The value held in SubjectAlternativeNames returned by Get-Certificate (accepted using a pipeline)
        #  * A value created by New-SubjectAlternativeNameRequest.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$SubjectAlternativeNames,

        # The length of the key to create. By default the key length is 2048 bytes.
        [UInt32]$KeyLength = 2048,

        # Assign a usage for the key. By default, Key Usage is set to KeyEncipherment and DigitalSignature.
        [System.Security.Cryptography.X509Certificates.X509KeyUsageFlags]$KeyUsage = "KeyEncipherment, DigitalSignature",

        # By default keys are created in the LocalMachine store. The CurrentUser store may be specified for local certificate operations.
        [System.Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

        # Submission of the certificate to a CA is, by default, a separate step. Immediate submission may be requested by setting this parameter. If AndSubmit is specified a value for CA must be provided.
        [Switch]$AndSubmit,

        # Completion of the certificate request is, by default, a series of separate steps. Immediate completion may be requested by setting this parameter. If AndComplete is specified a value for CA must be provided. The requester must have sufficient permission to approve a certificate on the certificate server.
        #
        # The AndSubmit parameter is ignored if this parameter is set.
        [Switch]$AndComplete,

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA)
    )

    process {
        $OperatingSystem = $CimResponse.Name

        # Construct the certificate information file

        # Generate the cettificate subject if required.
        if ($pscmdlet.ParameterSetName -eq 'CommonName') {
            $Subject = "CN = $CommonName"
            if ($psboundparameters.ContainsKey('Department'))   { $Subject = "$Subject, OU=$Department" }
            if ($psboundparameters.ContainsKey('Organization')) { $Subject = "$Subject, O = $Organization" }
            if ($psboundparameters.ContainsKey('City'))         { $Subject = "$Subject, L = $City" }
            if ($psboundparameters.ContainsKey('County'))       { $Subject = "$Subject, S = $County" }
            if ($psboundparameters.ContainsKey('Country'))      { $Subject = "$Subject, C = $Country" }
        } else {
            # Extract the CommonName if required. It will be used to name the request file.
            if ($Subject -match '^CN *= *([^,]+)') {
                $CommonName = $matches[1]
            }
        }

        if ($psboundparameters.ContainsKey("Extensions")) {
            $KeyUsage = $Extensions | Where-Object { $_.KeyUsages } | Select-Object -ExpandProperty KeyUsages

            $Extensions.EnhancedKeyUsages | ForEach-Object {
                if ($_.FriendlyName -eq 'Client Authentication') {
                    $ClientAuthentication = $true
                }
                if ($_.FriendlyName -eq 'Server Authentication') {
                    $ServerAuthentication = $true
                }
                if ($_.FriendlyName -eq 'KDC Authentication') {
                    $KDCAuthentication = $true
                }
                if ($_.FriendlyName -eq 'SmartcardLogon ') {
                    $SmartcardLogon = $true
                }
            }
        }

        if ($psboundparameters.ContainsKey("PublicKey") -and -not $psboundparameters.ContainsKey("KeyLength")) {
            $KeyLength = $PublicKey.Key.KeySize
            if ($KeyLength -lt 2048) {
                Write-Warning "$($ComputerName): Key length for $($CommonName) is less than 2048 bytes"
            }
        }

        # Prepare a request to submit to a signing authority.
        $CertInfo = New-Object Text.StringBuilder
        $null = $CertInfo.AppendLine("[NewRequest]").
                            AppendLine("Subject = ""$Subject""")
        # The friendly name attribute cannot be created under Windows 2003
        if ($OperatingSystem -notlike "*2003*") {
            if ($psboundparameters.ContainsKey("FriendlyName")) {
                $null = $CertInfo.AppendLine("FriendlyName = ""$FriendlyName""")
            } else {
                $null = $CertInfo.AppendLine("FriendlyName = ""$CommonName""")
            }
        }
        # Adding this for now to maintain consistency with certificates issued under the existing web server template.
        $null = $CertInfo.AppendLine("SMIME = TRUE").
                          AppendLine("KeySpec = 1").
                          AppendLine("KeyLength = $KeyLength")

        # Add the key usage as hexadecimal.
        $KeyUsageString = [String]::Format("0x{0}", ('{0:X2}' -f [UInt32]$KeyUsage))
        $null = $CertInfo.AppendLine("KeyUsage = $KeyUsageString")

        if ($StoreLocation -eq [Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine) {
            $null = $CertInfo.AppendLine("MachineKeySet = TRUE")
        }

        # If SelfSigned has been requested override the default RequestType value
        # This value is not valid on Windows 2003 systems.
        if ($SelfSigned -and $OperatingSystem -notlike "*2003*") {
            $null = $CertInfo.AppendLine("RequestType = Cert")
        } elseif ($SelfSigned -and $OperatingSystem -like "*2003*") {
            Write-Warning "$($ComputerName): Unable to specify self-signed for Microsoft Windows 2003 or earlier. Generated certificate will be held in the REQUEST store."
        }

        # Insert Client or Server authentication extensions if they have been requested.
        if ($ClientAuthentication -or $ServerAuthentication -or $KDCAuthentication -or $SmartcardLogon) {
            $null = $CertInfo.AppendLine().
                              AppendLine("[EnhancedKeyUsageExtension]")
            if ($ClientAuthentication) {
                $null = $CertInfo.AppendLine("OID = 1.3.6.1.5.5.7.3.2")
            }
            if ($ServerAuthentication) {
                $null = $CertInfo.AppendLine("OID = 1.3.6.1.5.5.7.3.1")
            }
            if ($KDCAuthentication) {
                $null = $CertInfo.AppendLine("OID = 1.3.6.1.5.2.3.5")
            }
            if ($SmartcardLogon) {
                $null = $CertInfo.AppendLine("OID = 1.3.6.1.4.1.311.20.2.2")
            }
        }

        # The SAN attribute cannot be specified like this under Windows 2003
        if ($OperatingSystem -notlike "*2003*") {
            if ($psboundparameters.ContainsKey("SubjectAlternativeNames")) {
                # If this doesn't look like a prepared request section assume it's from the pipeline and attempt to create one.
                if ($SubjectAlternativeNames -notmatch '^2.5.29.17') {
                    $SubjectAlternativeNames = New-SubjectAlternativeNameRequest -SubjectAlternativeNames $SubjectAlternativeNames
                }
                if ($SubjectAlternativeNames) {
                    $null = $CertInfo.AppendLine().
                                      AppendLine("[Extensions]").
                                      AppendLine($SubjectAlternativeNames)
                }
            }
        }

        if ($psboundparameters.ContainsKey("Template")) {
        $null = $CertInfo.AppendLine().
                          AppendLine("[RequestAttributes]").
                          AppendLine("CertificateTemplate = ""$Template""")
        }

        # Save the certificate information to a file which will be sent to the remote server

        $CertInfo.ToString() | Out-File "$CommonName.inf"

        # Prepare the certreq command

        $Command = "certreq -new -q -f -config - $CommonName.inf $CommonName.csr"

        Write-Verbose "New-Certificate: $($ComputerName): Executing $Command"

        $Response = & "cmd.exe" "/c", $Command

        if ($lastexitcode -eq 0) {
            if (-not $SelfSigned -and (Test-Path "$CommonName.csr")) {
                Write-Verbose "New-Certificate: $($ComputerName): CSR saved to $($pwd.Path)\$CommonName.csr"

                # Construct a return object which will aid the onward pipeline.
                $SigningRequest = [PSCustomObject]@{
                    CommonName             = $CommonName
                    SigningRequest         = $(if ($IsLocal) { Get-Content "$CommonName.csr" -Raw } else { Get-Content "ReturnFiles\$CommonName.csr" -Raw })
                    CA                     = $CA
                    Disposition            = "New"
                } | Add-Member -TypeName "Indented.PKI.Certificate.SigningRequest" -PassThru

                if ($AndComplete) {
                    $SigningRequest | Submit-SigningRequest | Approve-CACertificateRequest | Receive-Certificate | Complete-Certificate
                } elseif ($AndSubmit) {
                    $SigningRequest | Submit-SigningRequest
                } else {
                    return $SigningRequest
                }
            } else {
                Write-Error "Unable to access csr file $CommonName.csr."
            }
        } else {
            Write-Error "certreq returned $lastexitcode - $Response"
        }
    }
}