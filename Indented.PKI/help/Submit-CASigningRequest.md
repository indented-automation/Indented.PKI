---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Submit-CASigningRequest

## SYNOPSIS
Submit a CSR to a Microsoft CA.

## SYNTAX

### FromSigningRequest (Default)
```
Submit-CASigningRequest [-SigningRequest <String>] [-CA <String>]
```

### FromFile
```
Submit-CASigningRequest [-Path <String>] [-CA <String>]
```

## DESCRIPTION
Submit an existing CSR file to a certificate authority using the certificate services API.

A CSR may be submitted from any system which can reach the CA.
It does not need to be submitted from the system holding the private key.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Submit-CASigningRequest -Path c:\temp\cert.csr
```

Submit the CSR found in c:\temp\cert.csr to the default CA.

### -------------------------- EXAMPLE 2 --------------------------
```
Submit-CASigningRequest -SigningRequest $CSR -CA "ServerName\CA Name"
```

Submit the value held in the variable CSR to the CA "CA Name"

### -------------------------- EXAMPLE 3 --------------------------
```
New-Certificate -Subject "CN=localhost" -ClientAuthentication | Submit-CASigningRequest
```

Create a certificate with the specified subject and the ClientAuthentication enhanced key usage.
Submit the resulting SigningRequest to the default CA.

## PARAMETERS

### -SigningRequest
The CSR as a string.
The CSR string will be saved to a temporary file for submission to the CA.

```yaml
Type: String
Parameter Sets: FromSigningRequest
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Path
A file containing a CSR.
If using the ComputerName parameter the path is relative to the remote system.

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

### -CA
A string which idntifies a certificate authority in the form "ServerName\CAName".
If a default CA is defined (Get-DefaultCA) it will be used by default, any value supplied for this parameter overrides the default.

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

## INPUTS

### System.String

## OUTPUTS

## NOTES
Change log:
    05/02/2015 - Chris Dent - Added check for Certification Authority tools (RSAT).
    04/02/2015 - Chris Dent - First release.

## RELATED LINKS

