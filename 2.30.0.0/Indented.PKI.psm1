Add-Type -TypeDefinition '
    namespace Indented.PKI.CAAdmin
    {
        public enum DeleteRowFlag : int
        {
            NONE                     = 0,
            CDR_EXPIRED              = 1,
            CDR_REQUEST_LAST_CHANGED = 2
        }

        public enum ResponseDisposition : int
        {
            Incomplete      = 0,
            Error           = 1,
            Denied          = 2,
            Issued          = 3,
            IssuedOutOfBand = 4,
            UnderSubmission = 5,
            Revoked         = 6
        }
    }
'

Add-Type -TypeDefinition '
    namespace Indented.PKI.CAView
    {
        public enum DataType : int
        {
            PROPTYPE_BINARY = 1,
            PROPTYPE_DATE   = 2,
            PROPTYPE_LONG   = 3,
            PROPTYPE_STRING = 4
        }

        public enum RestrictionIndex : int
        {
            CV_COLUMN_QUEUE_DEFAULT      = -1,
            CV_COLUMN_LOG_DEFAULT        = -2,
            CV_COLUMN_LOG_FAILED_DEFAULT = -3
        }

        public enum ResultColumn : int
        {
            CVRC_COLUMN_SCHEMA = 0,
            CVRC_COLUMN_RESULT = 1,
            CVRC_COLUMN_VALUE  = 2
        }

        public enum Seek : int
        {
            CVR_SEEK_EQ = 1,
            CVR_SEEK_LT = 2,
            CVR_SEEK_LE = 4,
            CVR_SEEK_GE = 8,
            CVR_SEEK_GT = 16
        }

        public enum Sort : int
        {
            CVR_SORT_NONE    = 0,
            CVR_SORT_ASCEND  = 1,
            CVR_SORT_DESCEND = 2
        }

        public enum Table : int
        {
            CVRC_TABLE_REQCERT    = 0,
            CVRC_TABLE_EXTENSIONS = 12288,
            CVRC_TABLE_ATTRIBUTES = 16384,
            CVRC_TABLE_CRL        = 20480
        }
    }
'

Add-Type -TypeDefinition '
    namespace Indented.PKI.CA
    {
        public enum CertificateRequestDisposition : int
        {
            Active      = 8,
            Pending     = 9,
            Foreign     = 12,
            CACert      = 15,
            CACertChain = 16,
            KRACert     = 17,
            Issued      = 20,
            Revoked     = 21,
            Error       = 30,
            Denied      = 31
        }

        public enum CertificateRequestEncoding : int
        {
            CR_OUT_BASE64HEADER = 0,
            CR_OUT_BASE64       = 1,
            CR_OUT_BINARY       = 2
        }

        public enum CertificateRequestRequestType : int
        {
            CR_IN_FORMATANY    = 0,
            CR_IN_PKCS10       = 256,
            CR_IN_KEYGEN       = 512,
            CR_IN_PKCS7        = 768,
            CR_IN_CMC          = 1024,
            CR_IN_RPC          = 131072,
            CR_IN_FULLRESPONSE = 262144,
            CR_IN_CRLS         = 524288
        }
    }
'

Add-Type -TypeDefinition '
    namespace Indented.PKI.ResponseDisposition
    {
        public enum ResponseDisposition : int
        {
            Incomplete      = 0,
            Error           = 1,
            Denied          = 2,
            Issued          = 3,
            IssuedOutOfBand = 4,
            UnderSubmission = 5,
            Revoked         = 6
        }
    }
'

Add-Type -TypeDefinition '
    using System;

    namespace Indented.PKI.X509Certificate
    {
        [Flags]
        public enum KeyUsage : int
        {
            CERT_ENCIPHER_ONLY_KEY_USAGE      = 1,
            CERT_OFFLINE_CRL_SIGN_KEY_USAGE   = 2,
            CERT_KEY_CERT_SIGN_KEY_USAGE      = 4,
            CERT_KEY_AGREEMENT_KEY_USAGE      = 8,
            CERT_DATA_ENCIPHERMENT_KEY_USAGE  = 16,
            CERT_KEY_ENCIPHERMENT_KEY_USAGE   = 32,
            CERT_NON_REPUDIATION_KEY_USAGE    = 64,
            CERT_DIGITAL_SIGNATURE_KEY_USAGE  = 128,
            CERT_DECIPHER_ONLY_KEY_USAGE      = 32768
        }
    }
'

function NewCAError {
    <#
    .SYNOPSIS
        Creates an error record from an exception thrown by a CA COM object.
    .DESCRIPTION
        Parses Win32 error codes out of wrapped exceptions.
    #>

    param (
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    if ($ErrorRecord.Exception.Message -match 'CCert[^:]+::[^:]+: .*WIN32: (\d+)') {
        return New-Object System.Management.Automation.ErrorRecord(
            (New-Object ComponentModel.Win32Exception([Int32]$matches[1])),
            $_.Exception.Message,
            [System.Management.Automation.ErrorCategory]::OperationStopped,
            $null
        )
    }
    return $ErrorRecord
}

function Approve-CACertificateRequest {
    <#
    .SYNOPSIS
        Approve a certificate request and issue a certificate.
    .DESCRIPTION
        Approve a pending certificate request on the specified CA and issue a certificate.
    .EXAMPLE
        Get-CACertificateRequest -Pending | Approve-CACertificateRequest

        Approve and issue all pending certificates on the default CA.
    .EXAMPLE
        Approve-CACertificateRequest -RequestID 9

        Approve and issue certificate request 9 on the default CA.
    .NOTES
        Change log:
            24/02/2015 - Chris Dent - BugFix: Missing CA parameter when getting Issued certificates.
            13/02/2015 - Chris Dent - Modified pipeline to accept additional parameters for the Submit to Receive pipeline.
            05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
            04/02/2015 - Chris Dent - Allowed CmdLet to immediately return certificates which are already approved.
            03/02/2015 - Chris Dent - Modified input pipeline.
            02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
            29/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        # A request ID must be supplied for approval.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Int32]$RequestID,

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA)
    )

    begin {
        try {
           $caAdmin = New-Object -ComObject CertificateAuthority.Admin
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        if ($pscmdlet.ShouldProcess(('Issuing certificate Request ID: {0}' -f $RequestID))) {
            try {
                [Indented.PKI.CAAdmin.ResponseDisposition]$caResponse = $caAdmin.ResubmitRequest($CA,  $RequestID)
                Write-Debug ('CA response disposition: {0}' -f $caResponse)
            } catch {
                Write-Error -ErrorRecord (NewCAError $_)
            }
        }
    }

    end {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caAdmin)
    }
}

function Complete-Certificate {
    <#
    .SYNOPSIS
        Complete an issued certificate request (a signed public key) from a CA.
    .DESCRIPTION
        Complete-Certificate remotely executes the certreq command to complete an issued certificate using the specifieid certificate (Base64 encoded string or an .cer / PKCS7 file).
    .INPUTS
        System.String
    .EXAMPLE
        Complete-Certificate -Path certificate.cer

        Complete a certificate request using certificate.cer on the local machine.
    .EXAMPLE
        Receive-Certificate -RequestID 9 | Complete-Certificate

        Receive a certicate request issued by the default CA using certreq and use the resulting signed public key to complete a pending request.
    .EXAMPLE
        Receive-CACertificateRequest -RequestID 23 | Complete-Certificate

        Receive a certicate request issued by the default CA using the certificate management API and use the resulting signed public key to complete a pending request.
    .EXAMPLE
        Complete-Certificate -Path C:\Temp\Certificate.cer -ComputerName SomeComputer

        Complete a certificate request using C:\Temp\Certificate.cer on SomeComputer.
    .NOTES
        Change log:
            09/02/2015 - Chris Dent - Added quiet parameter to certreq.
            04/02/2015 - Chris Dent - Improved handling and validation of the Path parameter.
            03/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromCertificate')]
    param (
        # The certificate as a Base64 encoded string with a header and footer.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FromCertificate')]
        [String]$Certificate,

        # The path to the certificate file containing a signed public key.
        [Parameter(ParameterSetName = "FromFile")]
        [Alias('FullName')]
        [String]$Path
    )

    process {
        # The name of the file must exist on the remote server but we don't need to be able to read it here (certreq does).
        # If a CER string has been passed it needs saving to a file.
        if ($psboundparameters.ContainsKey("Certificate")) {
            $Path = $FileName = "Certificate.cer"
            $Certificate | Out-File $Path -Encoding UTF8
        } else {
            $FileName = Split-Path $Path -Leaf
        }

        $Command = "certreq -accept -q ""$Path"""

        Write-Verbose "Complete-Certificate: $($ComputerName): Executing $Command"

        $Response = & "cmd.exe" "/c", $Command
        if ($lastexitcode -ne 0) {
            Write-Error "Complete-Certificate: $($ComputerName): certreq returned $lastexitcode - $Response"
        }
    }
}

function ConvertTo-X509Certificate {
    <#
    .SYNOPSIS
        Convert a Base64 encoded certificate (with header and footer) to an X509Certificate object.
    .DESCRIPTION
        ConvertTo-X509Certificate reads a Base64 encoded certificate string or file and converts it to an X509Certificate object.
    .INPUTS
        System.String
    .EXAMPLE
        Get-CACertificate | ConvertTo-X509Certificate
    .EXAMPLE
        Get-CACertificateRequest -RequestID 19 | ConvertTo-X509Certificate
    .NOTES
        Change log:
            04/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param (
        # A base64 encoded string describing the certificate.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
        [Alias('RawCertificate')]
        [String]$Certificate,

        # A path to an existing certificate file.
        [Parameter(Mandatory = $true, ParameterSetName = 'FromFile')]
        [ValidateScript( { Test-Path $_ -PathType Leaf } )]
        [String]$Path
    )

    process {
        if ($pscmdlet.ParameterSetName -eq "FromPipeline") {
            if ($Certificate -notmatch '^-----BEGIN CERTIFICATE-----') {
                # Wrap a RawCertificate string in a header and footer.
                $Certificate = "-----BEGIN CERTIFICATE-----`r`n$Certificate`r`n-----END CERTIFICATE-----"
            }

            $Certificate | Out-File "$env:temp\Certificate.cer" -Encoding UTF8
            $Path = "$env:temp\Certificate.cer"
        }

        New-Object Security.Cryptography.X509Certificates.X509Certificate2($Path)

        if ($pscmdlet.ParameterSetName -eq "FromPipeline") {
            Remove-Item $Path
        }
    }
}

function Get-CACertificate {
    <#
    .SYNOPSIS
        Get signing certificate used by a CA.
    .DESCRIPTION
        Get-CACertificate requests the certificate used by a CA to sign content.

        The signing certificate must be trusted by the client operating system to install a certificate issued by the CA.
    .EXAMPLE
        Get-CACertificate -CA "SomeServer\SomeCA"

        Get the Base64 encoded signing certificate from the specified CA.
    .EXAMPLE
        Get-CACertificate | Out-File CACert.cer -Encoding UTF8

        Get the Base64 encoded signing certificate from the default CA and save it in a certificate file called CACert.cer.
    .EXAMPLE
        Get-CACertificate | ConvertTo-CACertificate | Install-Certificate -StoreName Root

        Get the signing certicate from the default CA and install it in the trusted root CA store on the local machine.
    .NOTES
        Change log:
            02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
            30/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    [OutputType([String])]
    param (
        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [String]$CA = (Get-DefaultCA)
    )

    try {
        $caRequest = New-Object -ComObject CertificateAuthority.Request
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    }

    try {
        $caRequest.GetCACertificate(
            $false,
            $CA,
            [Indented.PKI.CertificateRequestEncoding]::CR_OUT_BASE64HEADER
        )
    } catch {
        # Exceptions will be trapped as method invocation. Create specific exception types based on the Win32Exception number in the error message.
        Write-Error -ErrorRecord (NewCAError $_)
    }

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caRequest)
}

function Get-CACertificateRequest {
    <#
    .SYNOPSIS
        Get requests held by a certificate authority.
    .DESCRIPTION
        Get-CACertificateRequest may be used to list the different request types seen by a Microsoft Certificate Authority.

        Get-CACertificateRequest has a built-in limit of 10 concurrent connections to the CA.

        For very large CAs a 10 minute handle expiration timeout may be reached (see releated links). This presents as the error message below:

            CEnumCERTVIEWROW::Next: The handle is invalid.

        The error can be avoided by splitting a query down into smaller result sets, however the 10 concurrent connections limitation should be kept in mind.
    .EXAMPLE
        Get-CACertificateRequest -RequestID 9

        Get the certificiate with request ID 9 (regardless of disposition) from the default CA.
    .EXAMPLE
        Get-CACertificateRequest -Pending

        Get all pending certificate requests from the default CA.
    .EXAMPLE
        Get-CACertificateRequest -Issued -CA "SomeServer\Alt CA 01"

        Get all issued certificates from Alt CA 01.
    .EXAMPLE
        Get-CACertificateRequest -Filter "RequestID -ge 40 -and RequestID -le 50"

        Get all certificates requests where the request ID is between 40 and 50 (inclusive).
    .EXAMPLE
        Get-CACertificateRequest -Filter "CommonName -gt 'aa' -and CommonName -lt 'cz'"

        Get all certificate requests where the CommonName starts with a, b and c.

        Filtering on strings in this manner requires some experimentation, it does not always return the responses you might expect.
    .EXAMPLE
        Get-CACertificateRequest -Filter "NotBefore -ge '01/01/2015' -and NotBefore -le '18/02/2015'" -Issued

        Get certificates issued between 01/01/2015 and 18/02/2015.
    .EXAMPLE
        Get-CACertificateRequest -Issued -Filter "CertificateTemplate -eq '1.3.6.1.4.1.311.21.8.9498124.6089089.6112135.1244830.1219107.191.138660.11667527'"

        Get all certificate requests issued using the template described by the OID.
    .LINK
        http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
    .NOTES
        Change log:
            30/04/2015 - Chris Dent - Fixed the help text (typo).
            18/03/2015 - Chris Dent - Added a Properties parameter to allow for more efficient queries against the CA database.
            18/02/2015 - Chris Dent - Added Filter parameter.
            09/02/2015 - Chris Dent - Added ComObjectRelease call to attempt to close database session.
            05/02/2015 - Chris Dent - Added ExpiresOn, ExpiresBefore and ExpiresAfter parameters. Added check for Certification Authority tools (RSAT).
            04/02/2015 - Chris Dent - Added ComputerName as a property (parsed from RequestAttributes). Added CommonName and RequesterName as filters.
            03/02/2015 - Chris Dent - Added CA property to return object.
            02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
            29/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType('Indented.PKI.CA.CertificateRequest')]
    param (
        # Filter responses to a specific request ID.
        [Alias('ID')]
        [Int32]$RequestID,

        # Filter results to requests which expire on the specified day.
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiresOn,

        # Filter results to requests which expire before the specified date.
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiresBefore,

        # Filter results to requests which expire after the specified date.
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiresAfter,

        # Return the CRL.
        [Parameter(ParameterSetName = 'CRL')]
        [Switch]$CRL,

        # Filter results to issued certificates only.
        [Parameter(ParameterSetName = 'Issued')]
        [Switch]$Issued,

        # Filter results to failed requests only.
        [Parameter(ParameterSetName = 'Failed')]
        [Switch]$Failed,

        # Filter results to pending requests only.
        [Parameter(ParameterSetName = 'Pending')]
        [Switch]$Pending,

        # Filter responses to requests using the specified CommonName.
        [String]$CommonName,

        # Filter responses to those requested by a named individual (Domain\Username).
        [String]$RequesterName,

        <#
            Filter results using an expression.

            The following operators are supported in a filter:

                * -and
                * -eq
                * -ge
                * -gt
                * -le
                * -lt

            The property name must exactly match a valid property on the certificate request. Please note that the following properties are dynamically added by this command and are not filterable:

                * CA
                * ComputerName
        #>
        [String]$Filter,

        <#
            The properties to return. By default this command will return all available properties for any certificate request. The result set may be limited to specific properties to optimise any search.

            Some common properties are:

                * CommonName
                * NotAfter
                * Request.RequesterName
                * RequestID
        #>
        [String[]]$Properties,

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [String]$CA = (Get-DefaultCA)
    )

    if ($psboundparameters.ContainsKey('ExpiresOn')) {
        $ExpiresAfter = $psboundparameters.ExpiresAfter = (Get-Date $ExpiresOn).Date
        $ExpiresBefore = $psboundparameters.ExpiresBefore = (Get-Date $ExpiresOn).Date.AddDays(1).AddSeconds(-1)
    }

    try {
        $caView = New-Object -ComObject CertificateAuthority.View
        $caView.OpenConnection($CA)
    } catch {
        $pscmdlet.ThrowTerminatingError((NewCAError $_))
    }

    # Set the table to query
    if ($CRL) {
        $caView.SetTable([Int][Indented.PKI.CAView.Table]::CVRC_TABLE_CRL)
    } else {
        $caView.SetTable([Int][Indented.PKI.CAView.Table]::CVRC_TABLE_REQCERT)
    }

    # Properties
    if ($psboundparameters.ContainsKey("Properties")) {
        $columnIndexes = New-Object System.Collections.Generic.List[Object]

        foreach ($property in $Properties) {
            $columnIndex = $CAView.GetColumnIndex([Indented.PKI.CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, $property)

            if ($null -ne $ColumnIndex) {
                $columnIndexes.Add($ColumnIndex)
            }
        }

        if ($columnIndexes.Count -eq 0) {
            $errorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object ArgumentException('No valid columns have been selected.')),
                'InvalidPropertySet',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Properties
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        $caView.SetResultColumnCount($columnIndexes.Count)
        foreach ($index in $columnIndexes) {
            $caView.SetResultColumn($index)
        }
    } else {
        $columnCount = $caView.GetColumnCount([Indented.PKI.CAView.ResultColumn]::CVRC_COLUMN_SCHEMA)

        # Define the view
        $caView.SetResultColumnCount($columnCount)
        for ($i = 0; $i -lt $columnCount; $i++) {
            $caView.SetResultColumn($i)
        }
    }

    # Issued / Failed / Pending
    [Indented.PKI.CAView.Restrictionindex]$restrictionIndex = switch ($null) {
        { $Issued }  { 'CV_COLUMN_LOG_DEFAULT' }
        { $Failed }  { 'CV_COLUMN_LOG_FAILED_DEFAULT' }
        { $Pending } { 'CV_COLUMN_QUEUE_DEFAULT' }
        default      { 0 }
    }
    if ($restrictionIndex -ne 0) {
        $caView.SetRestriction(
            $restrictionIndex,
            [Indented.PKI.CAView.Seek]::CVR_SEEK_EQ,
            [Indented.PKI.CAView.Sort]::None,
            0
        )
    }

    # RequestID / CommonName / RequesterName / ExpiresAfter / ExpiresBefore
    foreach ($parameter in 'RequestID', 'CommonName', 'RequesterName') {
        if ($psboundparameters.ContainsKey($parameter)) {
            [Indented.PKI.CAView.Seek]$operator = 'CVR_SEEK_EQ'
            $columnName = switch ($parameter) {
                'ExpiresAfter'  { 'NotAfter'; $operator = 'CVR_SEEK_GT' }
                'ExpiresBefore' { 'NotBefore'; $operator = 'CVR_SEEK_LT' }
                'RequesterName' { 'Request.RequesterName' }
                default         { $columnName = $parameter }
            }

            $columnIndex = $caView.GetColumnIndex([Indented.PKI.CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, $columnName)
            $caView.SetRestriction(
                $ColumnIndex,
                $operator,
                [Indented.PKI.CAView.Sort]::None,
                $psboundparameters[$parameter]
            )
        }
    }

    # Parse and add restrictions associated with the Filter
    if ($psboundparameters.ContainsKey('Filter')) {
    # Types need to be passed as an appropriate type when setting a restriction. Get the column schema and expected types.
        $caViewColumn = $CAView.EnumCertViewColumn([Indented.PKI.CAView.ResultColumn]::CVRC_COLUMN_SCHEMA)
        $schema = @{}
        while ($caViewColumn.Next() -ne -1) {
            $schema.Add($caViewColumn.GetName(), $caViewColumn.GetType())
        }
        $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caViewColumn)

        $Filter -split '-and' | Where-Object { $_.Trim() -match '^ *(?<Property>\S+) +(?<Operator>\S+) +[''"]*(?<Value>[^''"]+)[''"]* *$' } | ForEach-Object {
            $property = $matches.Property
            $operator = $matches.Operator
            $value = $matches.Value

            if (-not $schema.Contains($property)) {
                $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                    (New-Object ArgumentException "Invalid property specified in filter."),
                    'InvalidFilterProperty',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $property
                )
                $pscmdlet.ThrowTerminatingError($errorRecord)
            }

            if ($operator -notin '-eq', '-ge', '-gt', '-le', '-lt') {
                $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                    (New-Object ArgumentException "Invalid operator specified in filter."),
                    'InvalidFilterOperator',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $operator)
                $pscmdlet.ThrowTerminatingError($errorRecord)
            }

            [Indented.PKI.CAView.Seek]$operator = switch ($Operator) {
                '-eq'   { 'CVR_SEEK_EQ' }
                '-ge'   { 'CVR_SEEK_GE' }
                '-gt'   { 'CVR_SEEK_GT' }
                '-le'   { 'CVR_SEEK_LE' }
                '-lt'   { 'CVR_SEEK_LT' }
            }

            # Attempt to cast the type to an expected type.
            # The cast for PROPTYPE_BINARY is a work-around at this point, Int32 seems to be the most successful.
            $value = switch ([Indented.PKI.CAView.DataType]$Schema[$Property]) {
                ([Indented.PKI.CAView.DataType]::PROPTYPE_BINARY) { [Int32]$Value }
                ([Indented.PKI.CAView.DataType]::PROPTYPE_DATE)   { Get-Date $Value }
                ([Indented.PKI.CAView.DataType]::PROPTYPE_LONG)   { [Int32]$Value }
                ([Indented.PKI.CAView.DataType]::PROPTYPE_STRING) { [String]$Value }
            }

            $columnIndex = $caView.GetColumnIndex([Indented.PKI.CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, $property)
            $caView.SetRestriction(
                $columnIndex,
                $operator,
                [Indented.PKI.CAView.Sort]::None,
                $value
            )
        }
    }

    $caViewRow = $caView.OpenView()

    # Display the content of the view
    while ($caViewRow.Next() -ne -1) {
        $certificateRequest = [PSCustomObject]@{ CA = $CA}

        $caViewColumn = $caViewRow.EnumCertViewColumn()
        while ($caViewColumn.Next() -ne -1) {
            $name = $caViewColumn.GetName()
            $value = $caViewColumn.GetValue(1)

            # Attempt to cast the value to an Enum to make a numeric value easier to understand.
            $enumName = 'Indented.PKI.CertificateRequest{0}' -f ($name -replace '^.+\.')
            if (($enumType = $enumName -as [Type]) -and $null -ne $value) {
                $value = [Enum]::Parse($enumType, $value)
            }
            if ($Name -eq 'Request.RequestAttributes') {
                if ($value -match 'ccm:(\S+)') {
                    $certificateRequest | Add-Member ComputerName $matches[1]
                }
            }
            $certificateRequest | Add-Member $name $value
        }

        $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caViewColumn)

        $certificateRequest | Add-Member -TypeName 'Indented.PKI.CA.CertificateRequest' -PassThru
    }

    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caViewRow)
    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caView)
}

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

function Get-DefaultCA {
    <#
    .SYNOPSIS
        Get the default CA value.
    .DESCRIPTION
        By default all CmdLets operating against a CA require the executor to provide the name of the CA.

        This command allows the executor to get a previously supplied default CA. If the default value has been made persistent the value is read from Documents\WindowsPowerShell\DefaultCA.txt.
    .EXAMPLE
        Get-KSDefaultCA
    .NOTES
        Change log:
            02/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    param ( )

    if (($Script:CA -eq $null) -and (Test-Path "$home\Documents\WindowsPowerShell\DefaultCA.txt")) {
        $Script:CA = (Get-Content "$home\Documents\WindowsPowerShell\DefaultCA.txt" -Raw).Trim()
    }

    return $Script:CA
}

function Install-Certificate {
    <#
    .SYNOPSIS
       Install an X509 certificate into a named store.
    .DESCRIPTION
       Install a certificate in the specified store.

       Install-Certificate can accept a public key, or a public/private key pair as an X509Certificate2 object.
    .INPUTS
       System.Security.Cryptography.X509Certificates.X509Certificate2
    .EXAMPLE
       Get-Certificate -StoreName My -ComputerName Server1 | Install-Certificate $Certificate -ComputerName Server2 -StoreName TrustedPeople

       Get certificates from the Personal (My) store of Server1 and install each into the TrustedPeople store of Server2.
    .EXAMPLE
       Get-CACertificate | ConvertTo-X509Certificate | Install-Certificate -StoreName Root
    .NOTES
        Change log:
            04/02/2015 - Chris Dent - Modified to accept pipeline input. BugFix: StoreName value when opening X509 store.
            12/06/2014 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    param (
        # The certificate to install.
        [Parameter(ValueFromPipeline = $true)]
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        # The store name to install the certificate into. By default certificates are installed in the personal store (My).
        [Security.Cryptography.X509Certificates.StoreName]$StoreName = "My",

        # The store to install the certificate into. By default the LocalMachine store is used.
        [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

        # An optional ComputerName to use for this query. If ComputerName is not specified Get-Certificate uses the current computer.
        [String]$ComputerName = $env:ComputerName
    )

    begin {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("\\$ComputerName\$StoreName", $StoreLocation)
        try {
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            $store.Add($Certificate)
        } catch {
            Write-Error -ErrorRecord $_
        }
    }

    end {
        $store.Close()
    }
}

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

function New-SubjectAlternativeNameRequest {
    <#
    .SYNOPSIS
        Create a new subject alternative name request block for use with the certreq command.
    .DESCRIPTION
        New-SubjectAlternativeNameRequest helps build a request block for a subject alternative name. The parameters for the SAN may be either manually defined or passed from Get-Certificate.
    .EXAMPLE
        New-SubjectAlternativeNameRequest -DNSName "one.domain.com", "one"
    .EXAMPLE
        Get-Certificate -HasPrivateKey -StoreName My | Where-Object SubjectAlternativeNames | New-SubjectAlternativeNameRequest
    .NOTES
        Change log:
            04/03/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    [OutputType([String])]
    param (
        # An X.500 Directory Name to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$DirectoryName = $null,

        # A DNS name to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$DNSName = $null,

        # An E-mail address to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$Email = $null,

        # An IP Address to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [IPAddress[]]$IPAddress = $null,

        # A User Principal Name to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$UPN = $null,

        # A URL value to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$URL = $null,

        # A Subject Alternative Names entry as a simple string (no line breaks). This parameter is intended to consume SAN values from Get-Certificate.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FromPipeline')]
        [String]$SubjectAlternativeNames
    )

    process {
        if ($psboundparameters.ContainsKey('SubjectAlternativeNames') -and $SubjectAlternativeNames) {
            $DirectoryName = [RegEx]::Matches($SubjectAlternativeNames, 'Directory Address:(?<DirectoryName>(?:(?:DC|CN|OU|O|STREET|L|ST|C|UID)=(?:\\,|[^,])+, *)*(?:(?:DC|CN|OU|O|STREET|L|ST|C|UID)=(?:\\,|[^,])+ *))', [Text.RegularExpressions.RegExOptions]::IgnoreCase) |
                ForEach-Object { $_.Groups['DirectoryName'].Value }

            $DNSName = [RegEx]::Matches($SubjectAlternativeNames, 'DNS Name=(?<DNSName>[^,]+)') |
                ForEach-Object { $_.Groups['DNSName'].Value }

            $Email = [RegEx]::Matches($SubjectAlternativeNames, 'RFC822 Name=(?<Email>[^,]+)') |
                ForEach-Object { $_.Groups['Email'].Value }

            $IPAddress = [RegEx]::Matches($SubjectAlternativeNames, 'IP Address=(?<IPAddress>[^,]+)') |
                ForEach-Object { $_.Groups['IPAddress'].Value }

            $UPN = [RegEx]::Matches($SubjectAlternativeNames, 'Other Name:Principal Name=(?<UPN>[^,]+)') |
                ForEach-Object { $_.Groups['UPN'].Value }

            $URL = [RegEx]::Matches($SubjectAlternativeNames, 'URL=(?<URL>[^,]+)') |
                ForEach-Object { $_.Groups['URL'].Value }
        }

        # Construct the request block
        $RequestBlock = New-Object System.Text.StringBuilder
        $null = $RequestBlock.AppendLine('2.5.29.17 = "{text}"')

        $DirectoryName | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""dn=$_&""")
        }

        $DNSName | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""dns=$_&""")
        }

        $Email | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""email=$_&""")
        }

        $IPAddress | Where-Object { $_ } | ForEach-Object {
            $IPAddressString = $_.ToString()
            if ($_.AddressFamily -eq 'InterNetworkV6') {
                $IPAddressBytes = $_.GetAddressBytes()
                $IPAddressString = $(for ($i = 0; $i -lt $IPAddressBytes.Count; $i += 2) {
                    [String]::Format('{0:X2}{1:X2}',
                        $IPAddressBytes[$i],
                        $IPAddressBytes[$i + 1]
                    )
                }) -join ':'
            }
            $null = $RequestBlock.AppendLine("_continue_ = ""ipaddress=$IPAddressString&""")
        }

        $UPN | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""upn=$_&""")
        }

        $URL | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""url=$_&""")
        }

        if ($DirectoryName -ne $null -or $DNSName -ne $null -or $Email -ne $null -or $IPAddress -ne $null -or $UPN -ne $null -or $URL -ne $null) {
            $RequestBlock.ToString().Trim() -replace '&"$', '"'
        }
    }
}

function Receive-CACertificateRequest {
    <#
    .SYNOPSIS
        Receive an issued certificate request from a CA.
    .DESCRIPTION
        Receive an issued certificate request from a CA as a Base64 encoded string (with header and footer).
    .EXAMPLE
        Get-CACertificateRequest -RequestID 3 -Issued | Receive-CACertificateRequest

        Receive an issued request and display the received certificate object.
    .EXAMPLE
        Receive-CACertificateRequest -RequestID 9 | ConvertTo-X509Certificate

        Receive an issued request and convert the request into an X509Certificate object.
    .EXAMPLE
        Receive-CACertificateRequest -RequestID 2 | Complete-Certificate

        Receive the certificate request and install the signed public key into an existing (incomplete) certificate request.
    .NOTES
        Change log:
            05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
            04/02/2015 - Chris Dent - Added CommonName as a pipeline parameter. Added AndComplete parameter. BugFix: Bad pipeline.
            02/02/2015 - Chris Dent - Added support for Get-DefaultCA.
            30/01/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    param (
        # The request ID to receive.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FromPipeline')]
        [Int32]$RequestID,

        # Receive the request from the specified CA.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

        # Complete the request
        [Switch]$AndComplete
    )

    begin {
        $caRequest = New-Object -ComObject CertificateAuthority.Request
    }

    process {
        try {
            $caResponse = $caRequest.GetIssuedCertificate($CA, $RequestID, $null)

            if ($caResponse -eq [Indented.PKI.CAAdmin.ResponseDisposition]::Issued) {
                $receivedCertificate = [PSCustomObject]@{
                    Certificate            = $caRequest.GetCertificate([Indented.PKI.CertificateRequestEncoding]::CR_OUT_BASE64HEADER)
                    CA                     = $CA
                    Disposition            = 'Received'
                } | Add-Member -TypeName 'Indented.PKI.ReceivedCertificate' -PassThru

                if ($AndComplete) {
                    $receivedCertificate | Complete-Certificate
                } else {
                    return $receivedCertificate
                }
            } else {
                Write-Warning ('Certificate request ({0}) must be issued to receive certificate.' -f $RequestID)
            }
        } catch {
            WriteError -ErrorRecord (NewCAError $_)
        }
    }

    end {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caRequest)
    }
}

function Receive-Certificate {
    <#
    .SYNOPSIS
        Receive an issued certificate request (a signed public key) from a CA.
    .DESCRIPTION
        Receive-Certificate remotely executes the certreq command to attempt to retrieve an issued certificate from the specified CA.
    .EXAMPLE
        Receive-Certificate -RequestID 23

        Attempt to receive certificate request 23 from the default CA.
    .EXAMPLE
        Receive-Certificate -RequestID 1220 -CA "ServerName\Alt CA 01"

        Receive request 1220 from the CA "Alt CA 01".
    .EXAMPLE
        Receive-Certificate -RequestID 93
    .NOTES
        Change log:
            24/02/2015 - Chris Dent - BugFix: CA is mandatory.
            09/02/2015 - Chris Dent - Added quiet parameter to certreq.
            04/02/2015 - Chris Dent - Added AndComplete parameter.
            03/02/2015 - Chris Dent - First release.
    #>

    [CmdletBinding()]
    param (
        # The request ID number for an existing issued certificate on the specified (or default) CA.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Int32]$RequestID,

        # CommonName is an optional parameter used to preserve a CommonName value while operating in pipeline mode. The parameter is optional and is used to name temporary files only.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CommonName = "Certificate",

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA),

        # Completion of the certificate request is, by default, a separate step. Immediate completion may be requested by setting this parameter.
        [Switch]$AndComplete
    )

    process {
        $Command = "certreq -retrieve -q -f -config ""$CA"" $RequestId ""$CommonName.cer"""

        Write-Debug "Executing $Command"

        $Response = & "cmd.exe" "/c", $Command

        if ($Response -match 'Taken Under Submission') {
            Write-Warning "The certificate request is not yet approved."
        } else {
            if ($lastexitcode -eq 0) {
                if (Test-Path "$CommonName.cer") {
                    Write-Verbose "Certificate saved to $($pwd.Path)\$CommonName.cer"

                    # Construct a return object which will aid the onward pipeline.
                    $ReceivedCertificate = [PSCustomObject]@{
                        CommonName             = $CommonName
                        Certificate            = Get-Content "$CommonName.cer" -Raw
                        CA                     = $CA
                        Disposition            = "Received"
                    } | Add-Member -TypeName "Indented.PKI.Certificate.ReceivedCertificate" -PassThru

                    if ($AndComplete) {
                        $ReceivedCertificate | Complete-Certificate
                    } else {
                        return $ReceivedCertificate
                    }
                } else {
                    Write-Error "Unable to access cer file $CommonName.cer."
                }
            } else {
                Write-Error "certreq returned $lastexitcode - $Response"
            }
        }
    }
}

function Remove-CACertificateRequest {
    <#
    .SYNOPSIS
        Remove a certificate request from a Microsoft Certificate Authority.
    .DESCRIPTION
        Remove-CACertificateRequest allows an administrator to remove requests from a Microsoft Certificate Authority database.
    .EXAMPLE
        Get-CACertificateRequest -CommonName SomeServer -Issued | Remove-CACertificateRequest

        Get all certificates which are issued using SomeServer as the CommonName and delete each.
    .EXAMPLE
        Remove-CACertificateRequest -ExpiredBefore "01/01/2015"

        Delete all certificate requests where the certificate expired before 01/01/2015.
    .EXAMPLE
        Remove-CACertificateRequest -LastModifiedBefore "01/01/2015"

        Delete all pending or denied certificate requests which were last modified before 01/01/2015.
    .NOTES
        Change log:
            05/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'DeleteByRequestID', SupportsShouldProcess = $true)]
    param (
        # Delete the certificate request with the specified request ID.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DeleteByRequestID')]
        [Alias('ID')]
        [Int32]$RequestID,

        # Delete certificate requests which expired before the specified date.
        [Parameter(Mandatory = $true, ParameterSetname = 'DeleteByExpirationDate')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiredBefore,

        # Delete pending or denied requests which were last modified before the specified date.
        [Parameter(Mandatory = $true, ParameterSetName = 'DeleteByLastModifiedDate')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $LastModifiedBefore,

        # Suppress confirmation dialog.
        [Switch]$Force,

        # A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [String]$CA = (Get-DefaultCA)
    )

    begin {
        try {
            $caAdmin = New-Object -ComObject CertificateAuthority.Admin
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        if ($pscmdlet.ShouldProcess("Deleting certificate Request ID: $($CertificateRequest.RequestID) ($($CertificateRequest.CommonName))")) {
            if ($Force -or $pscmdlet.ShouldContinue("", "Removing certificates from $CA")) {
                try {
                    switch ($pscmdlet.ParameterSetName) {
                        'DeleteByRequestID' {
                            $caAdmin.DeleteRow(
                                $CA,
                                [Indented.PKI.CAAdmin.DeleteRowFlag]::NONE,
                                0,
                                [Indented.PKI.CAView.Table]::CVRC_TABLE_REQCERT,
                                $RequestID
                            )
                        }
                        'DeleteByExpirationDate' {
                            $caAdmin.DeleteRow(
                                $CA,
                                [Indented.PKI.CAAdmin.DeleteRowFlag]::CDR_EXPIRED,
                                (Get-Date $ExpiredBefore),
                                [Indented.PKI.CAView.Table]::CVRC_TABLE_REQCERT,
                                0
                            )
                        }
                        'DeleteByLastModifiedDate' {
                            $caAdmin.DeleteRow(
                                $CA,
                                [Indented.PKI.CAAdmin.DeleteRowFlag]::CDR_REQUEST_LAST_CHANGED,
                                (Get-Date $LastModifiedBefore),
                                [Indented.PKI.CAView.Table]::CVRC_TABLE_REQCERT,
                                0
                            )
                        }
                    }
                } catch {
                    Write-Error -ErrorRecord (NewCAError $_)
                }
            }
        }
    }

    end {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($caAdmin)
    }
}

function Set-DefaultCA {
    <#
    .SYNOPSIS
        Set a default CA value.
    .DESCRIPTION
        By default all CmdLets operating against a CA require the executor to provide the name of the CA.

        This command allows the executor to define a default CA for all operations.
    .EXAMPLE
        Set-DefaultCA -CA "SomeServer\CA Name"

        Set the name of a DefaultCA for this session.
    .EXAMPLE
        Set-DefaultCA -CA "SomeServer\Default CA Name" -Persistent

        Set the name of a DefaultCA for this session and all future sessions.
    .NOTES
        Change log:
            04/03/2015 - Chris Dent - BugFix: Added handler for missing WindowsPowerShell folder.
            02/02/2015 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    param (
        # A string which identifies a certificate authority in the form "ServerName\CAName".
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$CA,

        # By default the CA value will only be used for this session. The CA value can be made to persist across all sessions for the current user with this setting. The CA text file is saved to the WindowsPowerShell folder under "Documents" for the current user.
        [Switch]$Persistent
    )

    $Script:CA = $CA

    if ($Persistent) {
        if (-not (Test-Path "$home\Documents\WindowsPowerShell")) {
            $null = New-Item "$home\Documents\WindowsPowerShell" -ItemType Directory -Force
        }
        $CA | Out-File "$home\Documents\WindowsPowerShell\DefaultCA.txt"
    }
}

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

function Submit-SigningRequest {
    <#
    .SYNOPSIS
        Submit a CSR to a Microsoft CA.
    .DESCRIPTION
        Submit an existing CSR file to a certificate authority using certreq.

        A CSR may be submitted from any system which can reach the CA. It does not need to be submitted from the system holding the private key.
    .INPUTS
        System.String
    .EXAMPLE
        Submit-SigningRequest -Path c:\temp\cert.csr

        Submit the CSR found in c:\temp\cert.csr to the default CA.
    .EXAMPLE
        Submit-SigningRequest -SigningRequest $CSR -CA "ServerName\CA Name"

        Submit the value held in the variable CSR to the CA "CA Name"
    .EXAMPLE
        New-Certificate -Subject "CN=localhost" -ClientAuthentication | Submit-SigningRequest

        Create a certificate with the specified subject and the ClientAuthentication enhanced key usage. Submit the resulting SigningRequest to the default CA.
    .NOTES
        Change log:
            03/03/2015 - Chris Dent - Changed CommonName to read from the file name when Path is specified. CSR is not decoded at this time.
            24/02/2015 - Chris Dent - Added Template parameter.
            09/02/2015 - Chris Dent - Added quiet parameter to certreq.
            04/02/2015 - Chris Dent - Fixed documentation.
            02/02/2015 - Chris Dent - Added support for Get-DefaultCA.
            27/01/2015 - Chris Dent - First release.
    #>

    [CmdletBinding(DefaultParameterSetName = "FromSigningRequest")]
    param (
        # The CSR as a string. The CSR string will be saved to a temporary file for submission to the CA.
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "FromSigningRequest")]
        [String]$SigningRequest,

        # A file containing a CSR. If using the ComputerName parameter the path is relative to the remote system.
        [Parameter(Mandatory = $true, ParameterSetName = "FromFile")]
        [Alias('FullName')]
        [String]$Path,

        [ValidateNotNullOrEmpty()]
        [String]$Template,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CommonName = "SigningRequest",

        # A string which idntifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [String]$CA = (Get-DefaultCA)
    )

    process {
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

        $Response = & "cmd.exe" "/c", $Command

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

function Test-TrustedCertificate {
    <#
    .SYNOPSIS
        Test for a certificate in the TrustedPeople store on the target computer.
    .DESCRIPTION
        Test-TrustedCertificate attempts to find a matching certificate in the TrustedPeople store.
    .EXAMPLE
        $Certificate = Get-Certificate -StoreName My -ComputerName Server1
        Test-TrustedCertificate $Certificate -ComputerName Server2

        Returns true if a matching public key from $Certificate is installed into the trusted store on Server2.
    .NOTES
        Change log:
            12/06/2014 - Chris Dent - First release.
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param (
        # The certificate to test.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

        # An optional ComputerName to use for this query. If ComputerName is not specified Test-TrustedCertificate uses the current computer.
        [String]$ComputerName = $env:ComputerName,

        # Test-TrustedCertificate returns a boolean (true or false) value by default. The result of all tests performed may be returned as an object by specifying the Detail parameter.
        [Switch]$Detail
    )

    $matchingCertificates = Get-Certificate -StoreName TrustedPeople -ComputerName $ComputerName |
        Where-Object { $_.FriendlyName -eq $Certificate.FriendlyName } |
        ForEach-Object {
            $Status = "Valid"
            if ($_.NotBefore -gt (Get-Date)) {
                $Status = "Not valid yet"
            }
            if ($_.NotAfter -lt (Get-Date)) {
                $Status = "Expired"
            }
            if ($_ -ne $Certificate) {
                $Status = "Friendly name match only"
            }
            $_ | Add-Member Status -MemberType NoteProperty -Value $Status -PassThru
        }

    if ($Detail) {
        return $matchingCertificates
    }
    if ($matchingCertificates | Where-Object Status -eq 'Valid') {
        return $true
    } else {
        return $false
    }
}