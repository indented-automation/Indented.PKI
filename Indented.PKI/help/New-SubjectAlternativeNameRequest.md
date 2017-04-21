---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# New-SubjectAlternativeNameRequest

## SYNOPSIS
Create a new subject alternative name request block for use with the certreq command.

## SYNTAX

### FromPipeline (Default)
```
New-SubjectAlternativeNameRequest [-SubjectAlternativeNames <String>]
```

### Manual
```
New-SubjectAlternativeNameRequest [-DirectoryName <String[]>] [-DNSName <String[]>] [-Email <String[]>]
 [-IPAddress <IPAddress[]>] [-UPN <String[]>] [-URL <String[]>]
```

## DESCRIPTION
New-SubjectAlternativeNameRequest helps build a request block for a subject alternative name.
The parameters for the SAN may be either manually defined or passed from Get-Certificate.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-SubjectAlternativeNameRequest -DNSName "one.domain.com", "one"
```

### -------------------------- EXAMPLE 2 --------------------------
```
Get-Certificate -HasPrivateKey -StoreName My | Where-Object SubjectAlternativeNames | New-SubjectAlternativeNameRequest
```

## PARAMETERS

### -DirectoryName
An X.500 Directory Name to include in the SAN.

```yaml
Type: String[]
Parameter Sets: Manual
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DNSName
A DNS name to include in the SAN.

```yaml
Type: String[]
Parameter Sets: Manual
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Email
An E-mail address to include in the SAN.

```yaml
Type: String[]
Parameter Sets: Manual
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IPAddress
An IP Address to include in the SAN.

```yaml
Type: IPAddress[]
Parameter Sets: Manual
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UPN
A User Principal Name to include in the SAN.

```yaml
Type: String[]
Parameter Sets: Manual
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -URL
A URL value to include in the SAN.

```yaml
Type: String[]
Parameter Sets: Manual
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SubjectAlternativeNames
A Subject Alternative Names entry as a simple string (no line breaks).
This parameter is intended to consume SAN values from Get-Certificate.

```yaml
Type: String
Parameter Sets: FromPipeline
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.String

## NOTES
Change log:
    04/03/2015 - Chris Dent - Created.

## RELATED LINKS

