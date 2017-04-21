---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Set-DefaultCA

## SYNOPSIS
Set a default CA value.

## SYNTAX

```
Set-DefaultCA [-CA] <String> [-Persistent]
```

## DESCRIPTION
By default all CmdLets operating against a CA require the executor to provide the name of the CA.

This command allows the executor to define a default CA for all operations.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Set-DefaultCA -CA "SomeServer\CA Name"
```

Set the name of a DefaultCA for this session.

### -------------------------- EXAMPLE 2 --------------------------
```
Set-DefaultCA -CA "SomeServer\Default CA Name" -Persistent
```

Set the name of a DefaultCA for this session and all future sessions.

## PARAMETERS

### -CA
A string which identifies a certificate authority in the form "ServerName\CAName".

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Persistent
By default the CA value will only be used for this session.
The CA value can be made to persist across all sessions for the current user with this setting.
The CA text file is saved to the WindowsPowerShell folder under "Documents" for the current user.

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
    04/03/2015 - Chris Dent - BugFix: Added handler for missing WindowsPowerShell folder.
    02/02/2015 - Chris Dent - Created.

## RELATED LINKS

