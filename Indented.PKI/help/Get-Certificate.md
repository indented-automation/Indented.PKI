---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Get-Certificate

## SYNOPSIS
Get certificates from a local or remote certificate store.

## SYNTAX

### Certificate (Default)
```
Get-Certificate [-StoreName <StoreName[]>] [-StoreLocation <StoreLocation>] [-ComputerName <String>]
 [-HasPrivateKey] [-Expired] [-ExpiresOn <Object>] [-Issuer <String>]
```

### Request
```
Get-Certificate [-StoreLocation <StoreLocation>] [-ComputerName <String>] [-HasPrivateKey] [-Expired]
 [-ExpiresOn <Object>] [-Issuer <String>] [-Request]
```

## DESCRIPTION
Get certificates from a local or remote certificate store.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-Certificate -StoreName My -StoreLocation CurrentUser
```

Get all certificates from the Personal store for the CurrentUser (caller).

### -------------------------- EXAMPLE 2 --------------------------
```
Get-Certificate -StoreLocation LocalMachine -Request
```

Get pending certificate requests.

## PARAMETERS

### -StoreName
Get-Certificate gets certificates from all stores.
A specific store name, or list of store names, may be supplied if required.

```yaml
Type: StoreName[]
Parameter Sets: Certificate
Aliases: 
Accepted values: AddressBook, AuthRoot, CertificateAuthority, Disallowed, My, Root, TrustedPeople, TrustedPublisher

Required: False
Position: Named
Default value: [Enum]::GetNames([StoreName])
Accept pipeline input: False
Accept wildcard characters: False
```

### -StoreLocation
Get-Certificate gets certificates from the LocalMachine store.
The CurrentUser store may be specified.

```yaml
Type: StoreLocation
Parameter Sets: (All)
Aliases: 
Accepted values: CurrentUser, LocalMachine

Required: False
Position: Named
Default value: LocalMachine
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
An optional ComputerName to use for this query.
If ComputerName is not specified Get-Certificate uses the current computer.

```yaml
Type: String
Parameter Sets: (All)
Aliases: ComputerNameString, Name

Required: False
Position: Named
Default value: $env:ComputerName
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HasPrivateKey
Filter results to only include certificates which have a private key available.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Expired
Filter results to only include expired certificates.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExpiresOn
Filter restults to only include certificates which expire on the specified day (between 00:00:00 and 23:59:59).

This parameter may be used in conjunction with Expired to find certificates which expired on a specific day.

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

### -Issuer
{{Fill Issuer Description}}

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

### -Request
Show pending certificate requests.

```yaml
Type: SwitchParameter
Parameter Sets: Request
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.String

## OUTPUTS

### System.Security.Cryptography.X509Certificates.X509Certificate2

## NOTES
Change log:
    03/03/2015 - Chris Dent - Changed Subject Alternate Names decode to drop line breaks.
    02/03/2015 - Chris Dent - Added EnhangedKeyUsages property to base object.
    27/02/2015 - Chris Dent - Merged store queries into a single statement.
Added decode support for Subject Alternate Names.
    09/02/2015 - Chris Dent - BugFix: Parameter existence check for ExpiresOn.
    04/02/2015 - Chris Dent - Added Issuer and NotAfter parameters.
    22/01/2015 - Chris Dent - Added Request parameter.
    24/06/2014 - Chris Dent - Added HasPrivateKey and Expired parameters.
    12/06/2014 - Chris Dent - Created.

## RELATED LINKS

