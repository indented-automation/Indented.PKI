using namespace Indented.PKI
using namespace System.Management.Automation
using namespace System.Runtime.InteropServices

function Get-CACertificateRequest {
    # .SYNOPSIS
    #   Get requests held by a certificate authority.
    # .DESCRIPTION
    #   Get-CACertificateRequest may be used to list the different request types seen by a Microsoft Certificate Authority.
    #
    #   Get-CACertificateRequest has a built-in limit of 10 concurrent connections to the CA.
    #
    #   For very large CAs a 10 minute handle expiration timeout may be reached. This presents as the error message below:
    #
    #     CEnumCERTVIEWROW::Next: The handle is invalid.
    #
    #   The error can be avoided by splitting a query down into smaller result sets, however the 10 concurrent connections limitation should be kept in mind.
    # .PARAMETER CA
    #   A string which identifies a certificate authority in the form "ServerName\CAName". If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.
    # .PARAMETER CommonName
    #   Filter responses to requests using the specified CommonName.
    # .PARAMETER CRL
    #   Return the CRL.
    # .PARAMETER ExpiresAfter
    #   Filter results to requests which expire after the specified date.
    # .PARAMETER ExpiresBefore
    #   Filter results to requests which expire before the specified date.
    # .PARAMETER ExpiresOn
    #   Filter results to requests which expire on the specified day.
    # .PARAMETER Failed
    #   Filter results to failed requests only.
    # .PARAMETER Filter
    #   Filter results using an expression.
    # 
    #   The following operators are supported in a filter:
    #
    #     * -and
    #     * -eq
    #     * -ge
    #     * -gt
    #     * -le
    #     * -lt
    #
    #   The property name must exactly match a valid property on the certificate request. Please note that the following properties are dynamically added by this CmdLet and are not filterable:
    #
    #     * CA
    #     * ComputerName
    #
    # .PARAMETER Issued
    #   Filter results to issued certificates only.
    # .PARAMETER Pending
    #   Filter results to pending requests only.
    # .PARAMETER Properties
    #   The properties to return. By default this CmdLet will return all available properties for any certificate request. The result set may be limited to specific properties to optimise any search.
    #
    #   Some common properties are:
    #
    #     * CommonName
    #     * NotAfter
    #     * Request.RequesterName
    #     * RequestID
    #
    # .PARAMETER RequesterName
    #   Filter responses to those requested by a named individual (Domain\Username).
    # .PARAMETER RequestId
    #   Filter responses to a specific request ID.
    # .INPUTS
    #   System.Int32
    #   System.String
    # .OUTPUTS
    #   Indented.PKI.CA.CertificateRequest
    # .EXAMPLE
    #   Get-CACertificateRequest -RequestID 9
    #
    #   Get the certificiate with request ID 9 (regardless of disposition) from the default CA.
    # .EXAMPLE
    #   Get-CACertificateRequest -Pending
    #
    #   Get all pending certificate requests from the default CA.
    # .EXAMPLE
    #   Get-CACertificateRequest -Issued -CA "SomeServer\Alt CA 01"
    #
    #   Get all issued certificates from Alt CA 01.
    # .EXAMPLE
    #   Get-CACertificateRequest -Filter "RequestID -ge 40 -and RequestID -le 50"
    #
    #   Get all certificates requests where the request ID is between 40 and 50 (inclusive).
    # .EXAMPLE
    #   Get-CACertificateRequest -Filter "CommonName -gt 'aa' -and CommonName -lt 'cz'"
    #
    #   Get all certificate requests where the CommonName starts with a, b and c.
    #
    #   Filtering on strings in this manner requires some experimentation, it does not always return the responses you might expect.
    # .EXAMPLE
    #   Get-CACertificateRequest -Filter "NotBefore -ge '01/01/2015' -and NotBefore -le '18/02/2015'" -Issued
    #
    #   Get certificates issued between 01/01/2015 and 18/02/2015.
    # .EXAMPLE
    #   Get-CACertificateRequest -Issued -Filter "CertificateTemplate -eq '1.3.6.1.4.1.311.21.8.9498124.6089089.6112135.1244830.1219107.191.138660.11667527'"
    #
    #   Get all certificate requests issued using the template described by the OID.
    # .LINK
    #   http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     30/04/2015 - Chris Dent - Fixed the help text (typo).
    #     18/03/2015 - Chris Dent - Added a Properties parameter to allow for more efficient queries against the CA database.
    #     18/02/2015 - Chris Dent - Added Filter parameter.
    #     09/02/2015 - Chris Dent - Added ComObjectRelease call to attempt to close database session.
    #     05/02/2015 - Chris Dent - Added ExpiresOn, ExpiresBefore and ExpiresAfter parameters. Added check for Certification Authority tools (RSAT).
    #     04/02/2015 - Chris Dent - Added ComputerName as a property (parsed from RequestAttributes). Added CommonName and RequesterName as filters.
    #     03/02/2015 - Chris Dent - Added CA property to return object.
    #     02/02/2015 - Chris Dent - Added error handling. Added support for Get-DefaultCA.
    #     29/01/2015 - Chris Dent - First release.

    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Alias('ID')]
        [Int32]$RequestID,

        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiresOn,

        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiresBefore,

        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Get-Date $_ } )]
        $ExpiresAfter,

        [Parameter(ParameterSetName = 'CRL')]
        [Switch]$CRL,

        [Parameter(ParameterSetName = 'Issued')]
        [Switch]$Issued,

        [Parameter(ParameterSetName = 'Failed')]
        [Switch]$Failed,

        [Parameter(ParameterSetName = 'Pending')]
        [Switch]$Pending,

        [ValidateNotNullOrEmpty()]
        [String]$CommonName,

        [ValidateNotNullOrEmpty()]
        [String]$RequesterName,

        [ValidateNotNullOrEmpty()]
        [String]$Filter,

        [String[]]$Properties,

        [ValidateNotNullOrEmpty()]
        [String]$CA = (Get-DefaultCA)
    )

    begin {
        if (-not (Test-Path "$env:WinDir\System32\certadm.dll") -or -not (Test-Path "$env:WinDir\System32\certcli.dll")) {
            $errorRecord = New-Object ErrorRecord(
                (New-Object InvalidOperationException "The Certification Authority tools must be installed to use this CmdLet."),
                'MissingCATools',
                [ErrorCategory]::OperationStopped,
                $pscmdlet
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        if (-not $CA) {
            $errorRecord = New-Object ErrorRecord(
                (New-Object ArgumentException "The CA parameter is mandatory."),
                "ArgumentException",
                [ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        $CAView = New-Object -ComObject CertificateAuthority.View
        try {
            $CAView.OpenConnection($CA)
        } catch {
            $pscmdlet.ThrowTerminatingError((NewWin32ErrorRecord))
        }

        # Set the table to query
        if ($CRL) {
            $CAView.SetTable([Int][CAView.Table]::CVRC_TABLE_CRL)
        } else {
            $CAView.SetTable([Int][CAView.Table]::CVRC_TABLE_REQCERT)
        }

        if ($psboundparameters.ContainsKey("Properties")) {
            $ColumnIndices = @()

            $Properties | ForEach-Object {
                $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, $_)

                if ($ColumnIndex -ne $null) {
                    $ColumnIndices += $ColumnIndex
                }
            }
            $ColumnIndices = $ColumnIndices | Sort-Object

            if (-not $ColumnIndices) {
                $errorRecord = New-Object ErrorRecord(
                    (New-Object ArgumentException "No valid columns have been selected."),
                    "ArgumentException",
                    [ErrorCategory]::InvalidArgument,
                    $Name
                )
                $pscmdlet.ThrowTerminatingError($errorRecord)
            }

            $CAView.SetResultColumnCount($ColumnIndices.Count)
            $ColumnIndices | ForEach-Object {
                $CAView.SetResultColumn($_)
            }
        } else {
            # Get the column count for the table
            $ColumnCount = $CAView.GetColumnCount([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA)

            # Define the view
            $CAView.SetResultColumnCount($ColumnCount)
            for ($i = 0; $i -lt $ColumnCount; $i++) {
                $CAView.SetResultColumn($i)
            }
        }

        # Apply any restrictions to the view
        if ($Issued) {
            $CAView.SetRestriction(
                [CAView.RestrictionIndex]::CV_COLUMN_LOG_DEFAULT,
                [CAView.Seek]::CVR_SEEK_EQ,
                [CAView.Sort]::None,
                0
            )
        } elseif ($Failed) {
            $CAView.SetRestriction(
                [CAView.RestrictionIndex]::CV_COLUMN_LOG_FAILED_DEFAULT,
                [CAView.Seek]::CVR_SEEK_EQ,
                [CAView.Sort]::None,
                0
            )
        } elseif ($Pending) {
            $CAView.SetRestriction(
                [CAView.RestrictionIndex]::CV_COLUMN_QUEUE_DEFAULT,
                [CAView.Seek]::CVR_SEEK_EQ,
                [CAView.Sort]::None,
                0
            )
        }
        if ($psboundparameters.ContainsKey('RequestID')) {
            $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, "RequestID")

            $CAView.SetRestriction(
                $ColumnIndex,
                [CAView.Seek]::CVR_SEEK_EQ,
                [CAView.Sort]::None,
                $RequestID
            )
        }
        if ($psboundparameters.ContainsKey('CommonName')) {
            $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, "CommonName")

            $CAView.SetRestriction(
                $ColumnIndex,
                [CAView.Seek]::CVR_SEEK_EQ,
                [CAView.Sort]::None,
                $CommonName
            )
        }
        if ($psboundparameters.ContainsKey('RequesterName')) {
            $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, "Request.RequesterName")

            $CAView.SetRestriction(
                $ColumnIndex,
                [CAView.Seek]::CVR_SEEK_EQ,
                [CAView.Sort]::None,
                $RequesterName
            )
        }
        if ($psboundparameters.ContainsKey('ExpiresOn')) {
            $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, "NotAfter")

            $CAView.SetRestriction(
                $ColumnIndex,
                [CAView.Seek]::CVR_SEEK_GT,
                [CAView.Sort]::None,
                (Get-Date $ExpiresOn).Date
            )
            $CAView.SetRestriction(
                $ColumnIndex,
                [CAView.Seek]::CVR_SEEK_LT,
                [CAView.Sort]::None,
                (Get-Date $ExpiresOn).Date.AddDays(1).AddSeconds(-1)
            )
        }
        if ($psboundparameters.ContainsKey('ExpiresBefore')) {
            $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, "NotAfter")

            $CAView.SetRestriction(
                $ColumnIndex,
                [CAView.Seek]::CVR_SEEK_LT,
                [CAView.Sort]::None,
                (Get-Date $ExpiresBefore)
            )
        }
        if ($psboundparameters.ContainsKey('ExpiresAfter')) {
            $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, "NotAfter")

            $CAView.SetRestriction(
                $ColumnIndex,
                [CAView.Seek]::CVR_SEEK_GT,
                [CAView.Sort]::None,
                (Get-Date $ExpiresAfter)
            )
        }

        # Parse and add restrictions associated with the Filter
        if ($psboundparameters.ContainsKey('Filter')) {
            # Types need to be passed as an appropriate type when setting a restriction. Get the column schema and expected types.
            $CAViewColumn = $CAView.EnumCertViewColumn([CAView.ResultCOlumn]::CVRC_COLUMN_SCHEMA)
            $Schema = @{}
            while ($CAViewColumn.Next() -ne -1) {
                $Schema.Add($CAViewColumn.GetName(), $CAViewColumn.GetType())
            }
            $null = [Marshal]::ReleaseComObject($CAViewColumn)
            Remove-Variable CAViewColumn

            $Filter -split '-and' | ForEach-Object {
                if ($_.Trim() -match '^ *(?<Property>\S+) +(?<Operator>\S+) +[''"]*(?<Value>[^''"]+)[''"]* *$') {
                    $Property = $matches.Property
                    $Operator = $matches.Operator
                    $Value = $matches.Value

                    if (-not $Schema.Contains($Property)) {
                        $errorRecord = New-Object ErrorRecord(
                            (New-Object ArgumentException "Invalid property specified in filter."),
                            "ArgumentException",
                            [ErrorCategory]::InvalidArgument,
                            $Property
                        )
                        $pscmdlet.ThrowTerminatingError($errorRecord)
                    }
                    if ($Operator -notin '-eq', '-ge', '-gt', '-le', '-lt') {
                        $errorRecord = New-Object ErrorRecord(
                            (New-Object ArgumentException "Invalid operator specified in filter."),
                            "ArgumentException",
                            [ErrorCategory]::InvalidArgument,
                            $Property
                        )
                        $pscmdlet.ThrowTerminatingError($errorRecord)          
                    }

                    $SeekOperator = switch ($Operator) {
                        '-eq'   { [CAView.Seek]::CVR_SEEK_EQ; break }
                        '-ge'   { [CAView.Seek]::CVR_SEEK_GE; break }
                        '-gt'   { [CAView.Seek]::CVR_SEEK_GT; break }
                        '-le'   { [CAView.Seek]::CVR_SEEK_LE; break }
                        '-lt'   { [CAView.Seek]::CVR_SEEK_LT; break }
                    }

                    # Attempt to cast the type to an expected type.
                    # The cast for PROPTYPE_BINARY is a work-around at this point, Int32 seems to be the most successful.
                    $Value = switch ([CAView.DataType]$Schema[$Property]) {
                        ([CAView.DataType]::PROPTYPE_BINARY) { [Int32]$Value; break }
                        ([CAView.DataType]::PROPTYPE_DATE)   { Get-Date $Value; break }
                        ([CAView.DataType]::PROPTYPE_LONG)   { [Int32]$Value; break }
                        ([CAView.DataType]::PROPTYPE_STRING) { [String]$Value; break }
                    }

                    $ColumnIndex = $CAView.GetColumnIndex([CAView.ResultColumn]::CVRC_COLUMN_SCHEMA, $Property)
                    $CAView.SetRestriction(
                        $ColumnIndex,
                        $SeekOperator,
                        [CAView.Sort]::None,
                        $Value
                    )
                }
            }
        }

        $CAViewRow = $CAView.OpenView()

        # Display the content of the view
        while ($CAViewRow.Next() -ne -1) {
            $CertificateRequest = [PSCustomObject]@{CA = $CA}

            $CAViewColumn = $CAViewRow.EnumCertViewColumn()

            while ($CAViewColumn.Next() -ne -1) {
                $Name = $CAViewColumn.GetName()
                # Attempt to cast the value to an Enum to make a numeric value easier to understand.
                $EnumName = "CertificateRequest.$($Name -replace '^.+\.')"
                $Value = $CAViewColumn.GetValue(1)
                if ($EnumName -as [Type] -and $Value) {
                    $Value = [Enum]::Parse(($EnumName -as [Type]), $Value)
                }
                if ($Name -eq 'Request.RequestAttributes') {
                    if ($Value -match 'ccm:(\S+)') {
                        $CertificateRequest | Add-Member ComputerName -MemberType NoteProperty -Value $matches[1]
                    }
                }
                $CertificateRequest | Add-Member $Name -MemberType NoteProperty -Value $Value
            }

            $null = [Marshal]::ReleaseComObject($CAViewColumn)
            Remove-Variable CAViewColumn

            $CertificateRequest = $CertificateRequest | Update-PropertyOrder
            $CertificateRequest.PSObject.TypeNames.Add("Indented.PKI.CACertificateRequest")

            $CertificateRequest
        }

        $null = [Marshal]::ReleaseComObject($CAViewRow)
        Remove-Variable CAViewRow
        $null = [Marshal]::ReleaseComObject($CAView)
        Remove-Variable CAView
    }
}