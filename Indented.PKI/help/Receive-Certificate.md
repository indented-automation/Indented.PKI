---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Receive-Certificate

## SYNOPSIS
Receive an issued certificate request (a signed public key) from a CA.

## SYNTAX

```
Receive-Certificate [-RequestID] <Int32> [[-CommonName] <String>] [[-CA] <String>] [-AndComplete]
```

## DESCRIPTION
Receive-Certificate remotely executes the certreq command to attempt to retrieve an issued certificate from the specified CA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Receive-Certificate -RequestID 23
```

Attempt to receive certificate request 23 from the default CA.

### -------------------------- EXAMPLE 2 --------------------------
```
Receive-Certificate -RequestID 1220 -CA "ServerName\Alt CA 01"
```

Receive request 1220 from the CA "Alt CA 01".

### -------------------------- EXAMPLE 3 --------------------------
```
Receive-Certificate -RequestID 93
```

## PARAMETERS

### -RequestID
The request ID number for an existing issued certificate on the specified (or default) CA.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CommonName
CommonName is an optional parameter used to preserve a CommonName value while operating in pipeline mode.
The parameter is optional and is used to name temporary files only.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: Certificate
Accept pipeline input: True (ByPropertyName)
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
Position: 3
Default value: (Get-DefaultCA)
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AndComplete
Completion of the certificate request is, by default, a separate step.
Immediate completion may be requested by setting this parameter.

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
    24/02/2015 - Chris Dent - BugFix: CA is mandatory.
    09/02/2015 - Chris Dent - Added quiet parameter to certreq.
    04/02/2015 - Chris Dent - Added AndComplete parameter.
    03/02/2015 - Chris Dent - First release.

## RELATED LINKS

