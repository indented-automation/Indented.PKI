---
external help file: Indented.PKI-help.xml
online version: http://blogs.technet.com/b/instan/archive/2013/01/31/tweaking-adcs-performance.aspx
schema: 2.0.0
---

# New-Certificate

## SYNOPSIS
Create a new certificate using the certreq command.

## SYNTAX

### Subject (Default)
```
New-Certificate [-FriendlyName <String>] -Subject <String> [-Template <String>]
 [-Extensions <X509ExtensionCollection>] [-PublicKey <PublicKey>] [-SelfSigned] [-ClientAuthentication]
 [-ServerAuthentication] [-KDCAuthentication] [-SmartcardLogon] [-SubjectAlternativeNames <String>]
 [-KeyLength <UInt32>] [-KeyUsage <X509KeyUsageFlags>] [-StoreLocation <StoreLocation>] [-AndSubmit]
 [-AndComplete] [-CA <String>]
```

### CommonName
```
New-Certificate -CommonName <String> [-Department <String>] [-Organization <String>] [-City <String>]
 [-County <String>] [-Country <String>] [-FriendlyName <String>] [-Template <String>] [-SelfSigned]
 [-ClientAuthentication] [-ServerAuthentication] [-KDCAuthentication] [-SmartcardLogon]
 [-SubjectAlternativeNames <String>] [-KeyLength <UInt32>] [-KeyUsage <X509KeyUsageFlags>]
 [-StoreLocation <StoreLocation>] [-AndSubmit] [-AndComplete] [-CA <String>]
```

## DESCRIPTION
New-Certificate will generate a new key-pair.
If SelfSigned is not specified a CSR is generated for submission to a certificate authority.

New-Certificate uses the certreq utility to provide compatilbity with hosts which do not run PowerShell.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-Certificate -Subject "CN=test-cert,OU=IT,O=Organisation,L=City,S=County,C=GB"
```

Generate a new certificate using the specified Subject name, default key length and default key usages.

### -------------------------- EXAMPLE 2 --------------------------
```
New-Certificate -CommonName "test-cert" -Department IT -Organization Organisation -City City -County County -Country GB
```

Generate a new certificate using the specified common name, department, organization, city, county and country.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-Certificate -StoreName My -HasPrivateKey | New-Certificate -KeyLength 2048
```

Generate new certificate requests based on the content of the personal store.
Force the key length of the certificates to 2048 regardless of the existing value.

### -------------------------- EXAMPLE 4 --------------------------
```
Get-Certificate -StoreName My -HasPrivateKey -ExpiresOn "31/03/2015" | New-Certificate
```

Generate certificate requests for each certificate in the local machines personal store (My) which has a private key and expires on the 31/03/2015.

### -------------------------- EXAMPLE 5 --------------------------
```
New-Certificate -Subject "CN=NewCertificate" -AndSubmit
```

Create a new private and public key pair, generate a signing request and immediately submit the signing request to the default CA.

### -------------------------- EXAMPLE 6 --------------------------
```
New-Certificate -Subject "CN=NewCertificate" -AndComplete
```

Using the default CA: Create a new private and public key pair, generate a signing request, submit the request to a CA, approve the certificate (if required), receive the new certificate and complete the request.

### -------------------------- EXAMPLE 7 --------------------------
```
New-Certificate -CommonName myusername -SubjectAlternativeNames (New-SubjectAlternativeNameRequest -UPN "myusername@domain.example") -ClientAuthentication
```

Create a new Client Authentication certificate which uses myusername as the common name and contains a User Principal Name in the Subject Alternative Name in the form "Other Name:Principal Name=myusername@domain.example".

## PARAMETERS

### -CommonName
The common name of the certificate.
The common name is used to construct the certificate subject.

```yaml
Type: String
Parameter Sets: CommonName
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Department
An optional Department for the certificate subject.

```yaml
Type: String
Parameter Sets: CommonName
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Organization
An optional Organization for the certificate subject.

```yaml
Type: String
Parameter Sets: CommonName
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -City
An optional City for the certificate subject.

```yaml
Type: String
Parameter Sets: CommonName
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -County
An optional County for the certificate subject.

```yaml
Type: String
Parameter Sets: CommonName
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Country
An optional Country for the certificate subject.

```yaml
Type: String
Parameter Sets: CommonName
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName
{{Fill FriendlyName Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subject
The certificate subject.
Mandatory is CommonName (and other optional parameters) are not supplied.

```yaml
Type: String
Parameter Sets: Subject
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Template
A template name may be specified for this request.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Extensions
The Extensions parameter processes extensions applied to a certificate passed through an input pipeline.
Note that this parameter will override any value held in KeyUsage.

```yaml
Type: X509ExtensionCollection
Parameter Sets: Subject
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PublicKey
The PublicKey parameter processes the PublicKey from a certificate passed through an input pipeline.
Note that this parameter will override any value held in KeyLength unless KeyLength is explicitly assigned a value.

```yaml
Type: PublicKey
Parameter Sets: Subject
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SelfSigned
Attempt to create a self signed certificate rather than generating a signing request for the certificate.

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

### -ClientAuthentication
Add the Client Authentication enhanced key usage extension to the certificate.

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

### -ServerAuthentication
Add the Server Authentication enhanced key usage extension to the certificate.

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

### -KDCAuthentication
Add the KDC Authentication enhanced key usage extension to the certificate.

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

### -SmartcardLogon
Add the Smartcard Logon enhanced key usage extension to the certificate.

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

### -SubjectAlternativeNames
The SubjectAlternativeNames to include in this request.
The SubjectAlternativeNames paramter expects one of two values:

 * The value held in SubjectAlternativeNames returned by Get-Certificate (accepted using a pipeline)
 * A value created by New-SubjectAlternativeNameRequest.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -KeyLength
The length of the key to create.
By default the key length is 2048 bytes.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: 2048
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyUsage
Assign a usage for the key.
By default, Key Usage is set to KeyEncipherment and DigitalSignature.

```yaml
Type: X509KeyUsageFlags
Parameter Sets: (All)
Aliases: 
Accepted values: None, EncipherOnly, CrlSign, KeyCertSign, KeyAgreement, DataEncipherment, KeyEncipherment, NonRepudiation, DigitalSignature, DecipherOnly

Required: False
Position: Named
Default value: KeyEncipherment, DigitalSignature
Accept pipeline input: False
Accept wildcard characters: False
```

### -StoreLocation
By default keys are created in the LocalMachine store.
The CurrentUser store may be specified for local certificate operations.

```yaml
Type: StoreLocation
Parameter Sets: (All)
Aliases: 
Accepted values: CurrentUser, LocalMachine

Required: False
Position: Named
Default value: LocalMachine
Accept pipeline input: False
Accept wildcard characters: False
```

### -AndSubmit
Submission of the certificate to a CA is, by default, a separate step.
Immediate submission may be requested by setting this parameter.
If AndSubmit is specified a value for CA must be provided.

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

### -AndComplete
Completion of the certificate request is, by default, a series of separate steps.
Immediate completion may be requested by setting this parameter.
If AndComplete is specified a value for CA must be provided.
The requester must have sufficient permission to approve a certificate on the certificate server.

The AndSubmit parameter is ignored if this parameter is set.

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
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

## INPUTS

### System.Security.Cryptography.X509Certificates.X509Certificate2

## OUTPUTS

## NOTES
Change log:
    03/03/2015 - Chris Dent - Added support for KDC Authentication and Smartcard Logon.
Added support for SubjectAlternativeName for operating systems newer than 2003.
    13/02/2015 - Chris Dent - Updated to use Invoke-Command for remote execution.
    09/02/2015 - Chris Dent - Added quiet parameter to certreq.
BugFix: Test-Path test for CSR existence.
    04/02/2015 - Chris Dent - Added AndSubmit and AndComplete.
    02/02/2015 - Chris Dent - Added template handling.
Modified to use New-PSDrive to access file share.
    26/01/2015 - Chris Dent - BugFix: OperatingSystem testing.
    23/01/2015 - Chris Dent - Added KeyUsage / Extension handling.
Added Client / Server authentication extension support.
    22/01/2015 - Chris Dent - Created.

## RELATED LINKS

