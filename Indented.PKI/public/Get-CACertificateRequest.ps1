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