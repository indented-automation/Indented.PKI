function Test-TrustedCertificate {
    <#
    .SYNOPSIS
        Test for a certificate in the TrustedPeople store on the target computer.
    .DESCRIPTION
        Test-TrustedCertificate attempts to find a matching certificate in the TrustedPeople store.
    .EXAMPLE
        $Certificate = Get-Certificate -StoreName My -ComputerName Server1
        Test-TrustedCertificate $Certificate -ComputerName Server2

        Returns true if a matching public key from $Certificate is installed into the trusted store on Server2.
    .NOTES
        Change log:
            12/06/2014 - Chris Dent - First release.
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param (
        # The certificate to test.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

        # An optional ComputerName to use for this query. If ComputerName is not specified Test-TrustedCertificate uses the current computer.
        [String]$ComputerName = $env:ComputerName,

        # Test-TrustedCertificate returns a boolean (true or false) value by default. The result of all tests performed may be returned as an object by specifying the Detail parameter.
        [Switch]$Detail
    )

    $matchingCertificates = Get-Certificate -StoreName TrustedPeople -ComputerName $ComputerName |
        Where-Object { $_.FriendlyName -eq $Certificate.FriendlyName } |
        ForEach-Object {
            $Status = "Valid"
            if ($_.NotBefore -gt (Get-Date)) {
                $Status = "Not valid yet"
            }
            if ($_.NotAfter -lt (Get-Date)) {
                $Status = "Expired"
            }
            if ($_ -ne $Certificate) {
                $Status = "Friendly name match only"
            }
            $_ | Add-Member Status -MemberType NoteProperty -Value $Status -PassThru
        }

    if ($Detail) {
        return $matchingCertificates
    }
    if ($matchingCertificates | Where-Object Status -eq 'Valid') {
        return $true
    } else {
        return $false
    }
}