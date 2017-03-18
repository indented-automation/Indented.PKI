using namespace System.Management.Automation
using namespace System.Security.Cryptography.X509Certificates

function Install-Certificate {
    # .SYNOPSIS
    #   Install an X509 certificate into a named store.
    # .DESCRIPTION
    #   Install a certificate in the specified store.
    #
    #   Install-Certificate can accept a public key, or a public/private key pair as an X509Certificate2 object.
    # .PARAMETER Certificate
    #   The certificate to install.
    # .PARAMETER ComputerName
    #   An optional ComputerName to use for this query. If ComputerName is not specified Get-Certificate uses the current computer.
    # .PARAMETER StoreLocation
    #   The store to install the certificate into. By default the LocalMachine store is used.
    # .PARAMETER StoreName
    #   The store name to install the certificate into. By default certificates are installed in the personal store (My).
    # .INPUTS
    #   System.Security.Cryptography.X509Certificates.X509Certificate2
    #   System.Security.Cryptography.X509Certificates.StoreName
    #   System.Security.Cryptography.X509Certificates.StoreLocation
    #   System.String
    # .EXAMPLE
    #   Get-Certificate -StoreName My -ComputerName Server1 | Install-Certificate $Certificate -ComputerName Server2 -StoreName TrustedPeople
    #
    #   Get certificates from the Personal (My) store of Server1 and install each into the TrustedPeople store of Server2.
    # .EXAMPLE
    #   Get-CACertificate | ConvertTo-X509Certificate | Install-Certificate -StoreName Root
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/02/2015 - Chris Dent - Modified to accept pipeline input. BugFix: StoreName value when opening X509 store.
    #     12/06/2014 - Chris Dent - First release.

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Security.Cryptography.X509Certificates.StoreName]$StoreName = "My",

        [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

        [String]$ComputerName = $env:ComputerName
    )

    begin {
        $store = New-Object X509Store("\\$ComputerName\$StoreName", $StoreLocation)
        try {
            $store.Open([OpenFlags]::ReadWrite)
        } catch {
            $errorRecord = New-Object ErrorRecord(
                $_.Exception.InnerException,
                "Exception",
                [ErrorCategory]::OpenError,
                $pscmdlet
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
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