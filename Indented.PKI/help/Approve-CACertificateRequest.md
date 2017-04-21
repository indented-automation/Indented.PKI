---
external help file: Indented.PKI-help.xml
online version: 
schema: 2.0.0
---

# Approve-CACertificateRequest

## SYNOPSIS
Approve a certificate request and issue a certificate.

## SYNTAX

```
Approve-CACertificateRequest [-RequestID] <Int32> [[-CA] <String>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
Approve a pending certificate request on the specified CA and issue a certificate.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-CACertificateRequest -Pending | Approve-CACertificateRequest
```

Approve and issue all pending certificates on the default CA.

### -------------------------- EXAMPLE 2 --------------------------
```
Approve-CACertificateRequest -RequestID 9
```

Approve and issue certificate request 9 on the default CA.

## PARAMETERS

### -RequestID
A request ID must be supplied for approval.

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

### -CA
A string which identifies a certificate authority in the form "ServerName\CAName".
If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: (Get-DefaultCA)
Accept pipeline input: True (ByPropertyName)
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
    24/02/2015 - Chris Dent - BugFix: Missing CA parameter when getting Issued certificates.
    13/02/2015 - Chris Dent - Modified pipeline to accept additional parameters for the Submit to Receive pipeline.
    05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
    04/02/2015 - Chris Dent - Allowed CmdLet to immediately return certificates which are already approved.
    03/02/2015 - Chris Dent - Modified input pipeline.
    02/02/2015 - Chris Dent - Added error handling.
Added support for Get-DefaultCA.
    29/01/2015 - Chris Dent - Created.

## RELATED LINKS

