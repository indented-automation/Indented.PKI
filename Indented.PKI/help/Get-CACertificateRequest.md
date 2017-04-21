---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Get-CACertificateRequest

## SYNOPSIS
Get requests held by a certificate authority.

## SYNTAX

### All (Default)
```
Get-CACertificateRequest [-RequestID <Int32>] [-ExpiresOn <Object>] [-ExpiresBefore <Object>]
 [-ExpiresAfter <Object>] [-CommonName <String>] [-RequesterName <String>] [-Filter <String>]
 [-Properties <String[]>] [-CA <String>]
```

### CRL
```
Get-CACertificateRequest [-RequestID <Int32>] [-ExpiresOn <Object>] [-ExpiresBefore <Object>]
 [-ExpiresAfter <Object>] [-CRL] [-CommonName <String>] [-RequesterName <String>] [-Filter <String>]
 [-Properties <String[]>] [-CA <String>]
```

### Issued
```
Get-CACertificateRequest [-RequestID <Int32>] [-ExpiresOn <Object>] [-ExpiresBefore <Object>]
 [-ExpiresAfter <Object>] [-Issued] [-CommonName <String>] [-RequesterName <String>] [-Filter <String>]
 [-Properties <String[]>] [-CA <String>]
```

### Failed
```
Get-CACertificateRequest [-RequestID <Int32>] [-ExpiresOn <Object>] [-ExpiresBefore <Object>]
 [-ExpiresAfter <Object>] [-Failed] [-CommonName <String>] [-RequesterName <String>] [-Filter <String>]
 [-Properties <String[]>] [-CA <String>]
```

### Pending
```
Get-CACertificateRequest [-RequestID <Int32>] [-ExpiresOn <Object>] [-ExpiresBefore <Object>]
 [-ExpiresAfter <Object>] [-Pending] [-CommonName <String>] [-RequesterName <String>] [-Filter <String>]
 [-Properties <String[]>] [-CA <String>]
```

## DESCRIPTION
Get-CACertificateRequest may be used to list the different request types seen by a Microsoft Certificate Authority.

Get-CACertificateRequest has a built-in limit of 10 concurrent connections to the CA.

For very large CAs a 10 minute handle expiration timeout may be reached (see releated links).
This presents as the error message below:

    CEnumCERTVIEWROW::Next: The handle is invalid.

The error can be avoided by splitting a query down into smaller result sets, however the 10 concurrent connections limitation should be kept in mind.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-CACertificateRequest -RequestID 9
```

Get the certificiate with request ID 9 (regardless of disposition) from the default CA.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-CACertificateRequest -Pending
```

Get all pending certificate requests from the default CA.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-CACertificateRequest -Issued -CA "SomeServer\Alt CA 01"
```

Get all issued certificates from Alt CA 01.

### -------------------------- EXAMPLE 4 --------------------------
```
Get-CACertificateRequest -Filter "RequestID -ge 40 -and RequestID -le 50"
```

Get all certificates requests where the request ID is between 40 and 50 (inclusive).

### -------------------------- EXAMPLE 5 --------------------------
```
Get-CACertificateRequest -Filter "CommonName -gt 'aa' -and CommonName -lt 'cz'"
```

Get all certificate requests where the CommonName starts with a, b and c.

Filtering on strings in this manner requires some experimentation, it does not always return the responses you might expect.

### -------------------------- EXAMPLE 6 --------------------------
```
Get-CACertificateRequest -Filter "NotBefore -ge '01/01/2015' -and NotBefore -le '18/02/2015'" -Issued
```

Get certificates issued between 01/01/2015 and 18/02/2015.

### -------------------------- EXAMPLE 7 --------------------------
```
Get-CACertificateRequest -Issued -Filter "CertificateTemplate -eq '1.3.6.1.4.1.311.21.8.9498124.6089089.6112135.1244830.1219107.191.138660.11667527'"
```

Get all certificate requests issued using the template described by the OID.

## PARAMETERS

### -RequestID
Filter responses to a specific request ID.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: ID

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpiresOn
Filter results to requests which expire on the specified day.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpiresBefore
Filter results to requests which expire before the specified date.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpiresAfter
Filter results to requests which expire after the specified date.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CRL
Return the CRL.

```yaml
Type: SwitchParameter
Parameter Sets: CRL
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Issued
Filter results to issued certificates only.

```yaml
Type: SwitchParameter
Parameter Sets: Issued
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Failed
Filter results to failed requests only.

```yaml
Type: SwitchParameter
Parameter Sets: Failed
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pending
Filter results to pending requests only.

```yaml
Type: SwitchParameter
Parameter Sets: Pending
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommonName
Filter responses to requests using the specified CommonName.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequesterName
Filter responses to those requested by a named individual (Domain\Username).

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filter results using an expression.

The following operators are supported in a filter:

    * -and
    * -eq
    * -ge
    * -gt
    * -le
    * -lt

The property name must exactly match a valid property on the certificate request.
Please note that the following properties are dynamically added by this command and are not filterable:

    * CA
    * ComputerName

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Properties
The properties to return.
By default this command will return all available properties for any certificate request.
The result set may be limited to specific properties to optimise any search.

Some common properties are:

    * CommonName
    * NotAfter
    * Request.RequesterName
    * RequestID

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CA
A string which identifies a certificate authority in the form "ServerName\CAName".
If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: (Get-DefaultCA)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### Indented.PKI.CA.CertificateRequest

## NOTES
Change log:
    30/04/2015 - Chris Dent - Fixed the help text (typo).
    18/03/2015 - Chris Dent - Added a Properties parameter to allow for more efficient queries against the CA database.
    18/02/2015 - Chris Dent - Added Filter parameter.
    09/02/2015 - Chris Dent - Added ComObjectRelease call to attempt to close database session.
    05/02/2015 - Chris Dent - Added ExpiresOn, ExpiresBefore and ExpiresAfter parameters.
Added check for Certification Authority tools (RSAT).
    04/02/2015 - Chris Dent - Added ComputerName as a property (parsed from RequestAttributes).
Added CommonName and RequesterName as filters.
    03/02/2015 - Chris Dent - Added CA property to return object.
    02/02/2015 - Chris Dent - Added error handling.
Added support for Get-DefaultCA.
    29/01/2015 - Chris Dent - Created.

## RELATED LINKS

[http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx](http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx)

