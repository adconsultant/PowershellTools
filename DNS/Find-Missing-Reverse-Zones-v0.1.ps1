<# ----------------------------------------------------------------------

    Type : Powershell Script

    Description : This script will show missing Reverse Lookup DNS Zones
                  on a spedified DNS server for a specific Forward Lookup
                  DNS zone.

    Version : 0.1

    Author : Andre Dube

    Date :  2018-02-15

    Keywords : DNS, Reverse, Zones, Active Directory

    MIT License: https://opensource.org/licenses/MIT

------------------------------------------------------------------------ #>

$DNSServer = "server123.domain.xyz"
$ZoneToCheck = "abc.com"
$OutputFile = "$PSScriptRoot\Check-Missing-Reverse-Zones.txt"

$dnsEntries = @()
$dnsResult = @()
$MissingZones = @()
$RevResult = @()

$revZones = @(Get-DnsServerZone -ComputerName $DNSServer | where {$_.IsReverseLookupZone -EQ "True"})
$dnsEntries = Get-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $ZoneToCheck | select HostName, @{n='RecordData';e={if ($_.RecordData.IPv4Address.IPAddressToString) {$_.RecordData.IPv4Address.IPAddressToString} else {""}}}# {$_.RecordData.NameServer.ToUpper()}}}

foreach ($revZone in $revZones){

    $ipAddressParts = $revZone.ZoneName.Split('.')
    $RevResult += $ipAddressParts[2] + "." + $ipAddressParts[1] + "." + $ipAddressParts[0]
}

foreach ($dnsEntrie in $dnsEntries){

    $ipAddressParts = $dnsEntrie.RecordData.Split('.')
    $tmpResult = $ipAddressParts[0] + "." + $ipAddressParts[1] + "." + $ipAddressParts[2]
    if($tmpResult -notcontains ".."){$dnsResult += $tmpResult}
}

$MissingZones = $dnsResult | where {$RevResult -notcontains $_} | sort | Get-Unique -AsString

Write-Host "DNS Server: $DNSServer" -ForegroundColor Green
write-host "DNS Zone  : $ZoneToCheck" -ForegroundColor Green
Write-Host "Missing reverse zones" -ForegroundColor Green
Write-Host "-------------------------------------" -ForegroundColor Green
$MissingZones
$MissingZones | Out-File $OutputFile -Verbose
