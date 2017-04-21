---
external help file: Indented.PKI-help.xml
online version: 
schema: 2.0.0
---

# Get-CACertificate

## SYNOPSIS
Get signing certificate used by a CA.

## SYNTAX

```
Get-CACertificate [[-CA] <String>]
```

## DESCRIPTION
Get-CACertificate requests the certificate used by a CA to sign content.

The signing certificate must be trusted by the client operating system to install a certificate issued by the CA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-CACertificate -CA "SomeServer\SomeCA"
```

Get the Base64 encoded signing certificate from the specified CA.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-CACertificate | Out-File CACert.cer -Encoding UTF8
```

Get the Base64 encoded signing certificate from the default CA and save it in a certificate file called CACert.cer.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-CACertificate | ConvertTo-CACertificate | Install-Certificate -StoreName Root
```

Get the signing certicate from the default CA and install it in the trusted root CA store on the local machine.

## PARAMETERS

### -CA
A string which identifies a certificate authority in the form "ServerName\CAName".
If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: (Get-DefaultCA)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.String

## NOTES
Change log:
    02/02/2015 - Chris Dent - Added error handling.
Added support for Get-DefaultCA.
    30/01/2015 - Chris Dent - Created.

## RELATED LINKS

