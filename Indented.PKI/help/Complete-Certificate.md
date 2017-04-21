---
external help file: Indented.PKI-help.xml
online version: 
schema: 2.0.0
---

# Complete-Certificate

## SYNOPSIS
Complete an issued certificate request (a signed public key) from a CA.

## SYNTAX

### FromCertificate (Default)
```
Complete-Certificate [-Certificate <String>]
```

### FromFile
```
Complete-Certificate [-Path <String>]
```

## DESCRIPTION
Complete-Certificate remotely executes the certreq command to complete an issued certificate using the specifieid certificate (Base64 encoded string or an .cer / PKCS7 file).

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Complete-Certificate -Path certificate.cer
```

Complete a certificate request using certificate.cer on the local machine.

### -------------------------- EXAMPLE 2 --------------------------
```
Receive-Certificate -RequestID 9 | Complete-Certificate
```

Receive a certicate request issued by the default CA using certreq and use the resulting signed public key to complete a pending request.

### -------------------------- EXAMPLE 3 --------------------------
```
Receive-CACertificateRequest -RequestID 23 | Complete-Certificate
```

Receive a certicate request issued by the default CA using the certificate management API and use the resulting signed public key to complete a pending request.

### -------------------------- EXAMPLE 4 --------------------------
```
Complete-Certificate -Path C:\Temp\Certificate.cer -ComputerName SomeComputer
```

Complete a certificate request using C:\Temp\Certificate.cer on SomeComputer.

## PARAMETERS

### -Certificate
The certificate as a Base64 encoded string with a header and footer.

```yaml
Type: String
Parameter Sets: FromCertificate
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Path
The path to the certificate file containing a signed public key.

```yaml
Type: String
Parameter Sets: FromFile
Aliases: FullName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.String

## OUTPUTS

## NOTES
Change log:
    09/02/2015 - Chris Dent - Added quiet parameter to certreq.
    04/02/2015 - Chris Dent - Improved handling and validation of the Path parameter.
    03/02/2015 - Chris Dent - Created.

## RELATED LINKS

