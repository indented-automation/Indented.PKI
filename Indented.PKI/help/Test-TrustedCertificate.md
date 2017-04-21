---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Test-TrustedCertificate

## SYNOPSIS
Test for a certificate in the TrustedPeople store on the target computer.

## SYNTAX

```
Test-TrustedCertificate [-Certificate] <X509Certificate2> [[-StoreLocation] <StoreLocation>]
 [[-ComputerName] <String>] [-Detail]
```

## DESCRIPTION
Test-TrustedCertificate attempts to find a matching certificate in the TrustedPeople store.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
$Certificate = Get-Certificate -StoreName My -ComputerName Server1
```

Test-TrustedCertificate $Certificate -ComputerName Server2

Returns true if a matching public key from $Certificate is installed into the trusted store on Server2.

## PARAMETERS

### -Certificate
The certificate to test.

```yaml
Type: X509Certificate2
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StoreLocation
{{Fill StoreLocation Description}}

```yaml
Type: StoreLocation
Parameter Sets: (All)
Aliases: 
Accepted values: CurrentUser, LocalMachine

Required: False
Position: 2
Default value: LocalMachine
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
An optional ComputerName to use for this query.
If ComputerName is not specified Test-TrustedCertificate uses the current computer.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: $env:ComputerName
Accept pipeline input: False
Accept wildcard characters: False
```

### -Detail
Test-TrustedCertificate returns a boolean (true or false) value by default.
The result of all tests performed may be returned as an object by specifying the Detail parameter.

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

## INPUTS

## OUTPUTS

### System.Boolean

### System.Security.Cryptography.X509Certificates.X509Certificate2

## NOTES
Change log:
    12/06/2014 - Chris Dent - First release.

## RELATED LINKS

