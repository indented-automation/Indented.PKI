---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Remove-CACertificateRequest

## SYNOPSIS
Remove a certificate request from a Microsoft Certificate Authority.

## SYNTAX

### DeleteByRequestID (Default)
```
Remove-CACertificateRequest -RequestID <Int32> [-Force] [-CA <String>] [-WhatIf] [-Confirm]
```

### DeleteByExpirationDate
```
Remove-CACertificateRequest -ExpiredBefore <Object> [-Force] [-CA <String>] [-WhatIf] [-Confirm]
```

### DeleteByLastModifiedDate
```
Remove-CACertificateRequest -LastModifiedBefore <Object> [-Force] [-CA <String>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Remove-CACertificateRequest allows an administrator to remove requests from a Microsoft Certificate Authority database.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-CACertificateRequest -CommonName SomeServer -Issued | Remove-CACertificateRequest
```

Get all certificates which are issued using SomeServer as the CommonName and delete each.

### -------------------------- EXAMPLE 2 --------------------------
```
Remove-CACertificateRequest -ExpiredBefore "01/01/2015"
```

Delete all certificate requests where the certificate expired before 01/01/2015.

### -------------------------- EXAMPLE 3 --------------------------
```
Remove-CACertificateRequest -LastModifiedBefore "01/01/2015"
```

Delete all pending or denied certificate requests which were last modified before 01/01/2015.

## PARAMETERS

### -RequestID
Delete the certificate request with the specified request ID.

```yaml
Type: Int32
Parameter Sets: DeleteByRequestID
Aliases: ID

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ExpiredBefore
Delete certificate requests which expired before the specified date.

```yaml
Type: Object
Parameter Sets: DeleteByExpirationDate
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastModifiedBefore
Delete pending or denied requests which were last modified before the specified date.

```yaml
Type: Object
Parameter Sets: DeleteByLastModifiedDate
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Suppress confirmation dialog.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
Change log:
    05/02/2015 - Chris Dent - Created.

## RELATED LINKS

