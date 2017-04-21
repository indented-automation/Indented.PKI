function Install-Certificate {
    <#
    .SYNOPSIS
       Install an X509 certificate into a named store.
    .DESCRIPTION
       Install a certificate in the specified store.
    
       Install-Certificate can accept a public key, or a public/private key pair as an X509Certificate2 object.
    .INPUTS
       System.Security.Cryptography.X509Certificates.X509Certificate2
    .EXAMPLE
       Get-Certificate -StoreName My -ComputerName Server1 | Install-Certificate $Certificate -ComputerName Server2 -StoreName TrustedPeople
    
       Get certificates from the Personal (My) store of Server1 and install each into the TrustedPeople store of Server2.
    .EXAMPLE
       Get-CACertificate | ConvertTo-X509Certificate | Install-Certificate -StoreName Root
    .NOTES
        Change log:
            04/02/2015 - Chris Dent - Modified to accept pipeline input. BugFix: StoreName value when opening X509 store.
            12/06/2014 - Chris Dent - Created.
    #>

    [CmdletBinding()]
    param (
        # The certificate to install.
        [Parameter(ValueFromPipeline = $true)]
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        # The store name to install the certificate into. By default certificates are installed in the personal store (My).
        [Security.Cryptography.X509Certificates.StoreName]$StoreName = "My",

        # The store to install the certificate into. By default the LocalMachine store is used.
        [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

        # An optional ComputerName to use for this query. If ComputerName is not specified Get-Certificate uses the current computer.
        [String]$ComputerName = $env:ComputerName
    )

    begin {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("\\$ComputerName\$StoreName", $StoreLocation)
        try {
            $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    process {
        try {
            $store.Add($Certificate)
        } catch {
            Write-Error -ErrorRecord $_
        }
    }

    end {
        $store.Close()
    }
}