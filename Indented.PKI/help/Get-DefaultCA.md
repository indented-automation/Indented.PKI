---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Get-DefaultCA

## SYNOPSIS
Get the default CA value.

## SYNTAX

```
Get-DefaultCA
```

## DESCRIPTION
By default all CmdLets operating against a CA require the executor to provide the name of the CA.

This command allows the executor to get a previously supplied default CA.
If the default value has been made persistent the value is read from Documents\WindowsPowerShell\DefaultCA.txt.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-KSDefaultCA
```

## PARAMETERS

## INPUTS

## OUTPUTS

## NOTES
Change log:
    02/02/2015 - Chris Dent - Created.

## RELATED LINKS

