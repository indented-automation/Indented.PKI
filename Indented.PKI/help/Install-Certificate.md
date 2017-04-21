---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# Install-Certificate

## SYNOPSIS
Install an X509 certificate into a named store.

## SYNTAX

```
Install-Certificate [[-Certificate] <X509Certificate2>] [[-StoreName] <StoreName>]
 [[-StoreLocation] <StoreLocation>] [[-ComputerName] <String>]
```

## DESCRIPTION
Install a certificate in the specified store.

Install-Certificate can accept a public key, or a public/private key pair as an X509Certificate2 object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-Certificate -StoreName My -ComputerName Server1 | Install-Certificate $Certificate -ComputerName Server2 -StoreName TrustedPeople
```

Get certificates from the Personal (My) store of Server1 and install each into the TrustedPeople store of Server2.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-CACertificate | ConvertTo-X509Certificate | Install-Certificate -StoreName Root
```

## PARAMETERS

### -Certificate
The certificate to install.

```yaml
Type: X509Certificate2
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -StoreName
The store name to install the certificate into.
By default certificates are installed in the personal store (My).

```yaml
Type: StoreName
Parameter Sets: (All)
Aliases: 
Accepted values: AddressBook, AuthRoot, CertificateAuthority, Disallowed, My, Root, TrustedPeople, TrustedPublisher

Required: False
Position: 2
Default value: My
Accept pipeline input: False
Accept wildcard characters: False
```

### -StoreLocation
The store to install the certificate into.
By default the LocalMachine store is used.

```yaml
Type: StoreLocation
Parameter Sets: (All)
Aliases: 
Accepted values: CurrentUser, LocalMachine

Required: False
Position: 3
Default value: LocalMachine
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
An optional ComputerName to use for this query.
If ComputerName is not specified Get-Certificate uses the current computer.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: $env:ComputerName
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.Security.Cryptography.X509Certificates.X509Certificate2

## OUTPUTS

## NOTES
Change log:
    04/02/2015 - Chris Dent - Modified to accept pipeline input.
BugFix: StoreName value when opening X509 store.
    12/06/2014 - Chris Dent - Created.

## RELATED LINKS

