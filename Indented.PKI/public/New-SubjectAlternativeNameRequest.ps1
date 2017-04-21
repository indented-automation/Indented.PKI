function New-SubjectAlternativeNameRequest {
    <#
    .SYNOPSIS
        Create a new subject alternative name request block for use with the certreq command.
    .DESCRIPTION
        New-SubjectAlternativeNameRequest helps build a request block for a subject alternative name. The parameters for the SAN may be either manually defined or passed from Get-Certificate.
    .EXAMPLE
        New-SubjectAlternativeNameRequest -DNSName "one.domain.com", "one"
    .EXAMPLE
        Get-Certificate -HasPrivateKey -StoreName My | Where-Object SubjectAlternativeNames | New-SubjectAlternativeNameRequest
    .NOTES
        Change log:
            04/03/2015 - Chris Dent - Created.
    #>

    [CmdletBinding(DefaultParameterSetName = 'FromPipeline')]
    [OutputType([String])]
    param (
        # An X.500 Directory Name to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$DirectoryName = $null,

        # A DNS name to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$DNSName = $null,

        # An E-mail address to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$Email = $null,

        # An IP Address to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [IPAddress[]]$IPAddress = $null,

        # A User Principal Name to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$UPN = $null,

        # A URL value to include in the SAN.
        [Parameter(ParameterSetName = 'Manual')]
        [String[]]$URL = $null,

        # A Subject Alternative Names entry as a simple string (no line breaks). This parameter is intended to consume SAN values from Get-Certificate.
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FromPipeline')]
        [String]$SubjectAlternativeNames
    )

    process {
        if ($psboundparameters.ContainsKey('SubjectAlternativeNames') -and $SubjectAlternativeNames) {
            $DirectoryName = [RegEx]::Matches($SubjectAlternativeNames, 'Directory Address:(?<DirectoryName>(?:(?:DC|CN|OU|O|STREET|L|ST|C|UID)=(?:\\,|[^,])+, *)*(?:(?:DC|CN|OU|O|STREET|L|ST|C|UID)=(?:\\,|[^,])+ *))', [Text.RegularExpressions.RegExOptions]::IgnoreCase) |
                ForEach-Object { $_.Groups['DirectoryName'].Value }

            $DNSName = [RegEx]::Matches($SubjectAlternativeNames, 'DNS Name=(?<DNSName>[^,]+)') |
                ForEach-Object { $_.Groups['DNSName'].Value }

            $Email = [RegEx]::Matches($SubjectAlternativeNames, 'RFC822 Name=(?<Email>[^,]+)') |
                ForEach-Object { $_.Groups['Email'].Value }

            $IPAddress = [RegEx]::Matches($SubjectAlternativeNames, 'IP Address=(?<IPAddress>[^,]+)') |
                ForEach-Object { $_.Groups['IPAddress'].Value }

            $UPN = [RegEx]::Matches($SubjectAlternativeNames, 'Other Name:Principal Name=(?<UPN>[^,]+)') |
                ForEach-Object { $_.Groups['UPN'].Value }

            $URL = [RegEx]::Matches($SubjectAlternativeNames, 'URL=(?<URL>[^,]+)') |
                ForEach-Object { $_.Groups['URL'].Value }
        }

        # Construct the request block
        $RequestBlock = New-Object System.Text.StringBuilder
        $null = $RequestBlock.AppendLine('2.5.29.17 = "{text}"')

        $DirectoryName | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""dn=$_&""")
        }

        $DNSName | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""dns=$_&""")
        }

        $Email | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""email=$_&""")
        }

        $IPAddress | Where-Object { $_ } | ForEach-Object {
            $IPAddressString = $_.ToString()
            if ($_.AddressFamily -eq 'InterNetworkV6') {
                $IPAddressBytes = $_.GetAddressBytes()
                $IPAddressString = $(for ($i = 0; $i -lt $IPAddressBytes.Count; $i += 2) {
                    [String]::Format('{0:X2}{1:X2}',
                        $IPAddressBytes[$i],
                        $IPAddressBytes[$i + 1]
                    )
                }) -join ':'
            }
            $null = $RequestBlock.AppendLine("_continue_ = ""ipaddress=$IPAddressString&""") 
        }

        $UPN | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""upn=$_&""")
        }

        $URL | Where-Object { $_ } | ForEach-Object {
            $null = $RequestBlock.AppendLine("_continue_ = ""url=$_&""")
        }

        if ($DirectoryName -ne $null -or $DNSName -ne $null -or $Email -ne $null -or $IPAddress -ne $null -or $UPN -ne $null -or $URL -ne $null) {
            $RequestBlock.ToString().Trim() -replace '&"$', '"'
        }
    }
}