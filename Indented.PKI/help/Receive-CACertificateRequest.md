---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Receive-CACertificateRequest

## SYNOPSIS
Receive an issued certificate request from a CA.

## SYNTAX

```
Receive-CACertificateRequest -RequestID <Int32> [-CA <String>] [-AndComplete]
```

## DESCRIPTION
Receive an issued certificate request from a CA as a Base64 encoded string (with header and footer).

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-CACertificateRequest -RequestID 3 -Issued | Receive-CACertificateRequest
```

Receive an issued request and display the received certificate object.

### -------------------------- EXAMPLE 2 --------------------------
```
Receive-CACertificateRequest -RequestID 9 | ConvertTo-X509Certificate
```

Receive an issued request and convert the request into an X509Certificate object.

### -------------------------- EXAMPLE 3 --------------------------
```
Receive-CACertificateRequest -RequestID 2 | Complete-Certificate
```

Receive the certificate request and install the signed public key into an existing (incomplete) certificate request.

## PARAMETERS

### -RequestID
The request ID to receive.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CA
Receive the request from the specified CA.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: (Get-DefaultCA)
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AndComplete
Complete the request

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

## NOTES
Change log:
    05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
    04/02/2015 - Chris Dent - Added CommonName as a pipeline parameter.
Added AndComplete parameter.
BugFix: Bad pipeline.
    02/02/2015 - Chris Dent - Added support for Get-DefaultCA.
    30/01/2015 - Chris Dent - Created.

## RELATED LINKS

