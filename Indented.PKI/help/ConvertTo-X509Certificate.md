---
external help file: Indented.PKI-help.xml
online version: 
schema: 2.0.0
---

# ConvertTo-X509Certificate

## SYNOPSIS
Convert a Base64 encoded certificate (with header and footer) to an X509Certificate object.

## SYNTAX

### FromPipeline (Default)
```
ConvertTo-X509Certificate -Certificate <String>
```

### FromFile
```
ConvertTo-X509Certificate -Path <String>
```

## DESCRIPTION
ConvertTo-X509Certificate reads a Base64 encoded certificate string or file and converts it to an X509Certificate object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-CACertificate | ConvertTo-X509Certificate
```

### -------------------------- EXAMPLE 2 --------------------------
```
Get-CACertificateRequest -RequestID 19 | ConvertTo-X509Certificate
```

## PARAMETERS

### -Certificate
A base64 encoded string describing the certificate.

```yaml
Type: String
Parameter Sets: FromPipeline
Aliases: RawCertificate

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Path
A path to an existing certificate file.

```yaml
Type: String
Parameter Sets: FromFile
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.String

## OUTPUTS

### System.Security.Cryptography.X509Certificates.X509Certificate2

## NOTES
Change log:
    04/02/2015 - Chris Dent - Created.

## RELATED LINKS

