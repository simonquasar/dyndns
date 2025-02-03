# Configuration
$Config = @{
    Email   = "EMAIL"
    Domain  = "BASEDOMAIN"
    Record  = "SUBDOMAIN.BASEDOMAIN"
    Token   = "CF_TOKEN"
}

# Visual Enhancements
$Colors = @{
    Primary   = "DarkBlue"
    Secondary = "Blue"
    Accent    = "DarkYellow"
    Text      = "White"  # Adjust text color for readability
}

function Show-Message {
    param([string]$Text, [string]$Color)
    Write-Host (" " * 2) + $Text -ForegroundColor $Colors['Text'] -BackgroundColor $Color
}

function Show-Section {
    param([string]$Text, [string]$Color)
    Show-Message "==== $Text ====" $Color
}

function Get-CurrentIP {
    (Invoke-RestMethod -Uri "http://ipinfo.io/ip").Trim()
}

function Prompt-User {
    param([string]$Prompt)
    Write-Host (" " * 2) -NoNewline
    Read-Host $Prompt
}

# Main Script
Show-Section "DDNS Updater for [$($Config.Record)]" $Colors['Secondary']

$currentIP = Get-CurrentIP
Show-Message "Your IP: $currentIP" $Colors['Secondary']

$whichIP = Prompt-User "Use $currentIP? (Or enter custom IP)"
$new_ip = if ($whichIP -eq "" -or $whichIP -ieq "Y" -or $whichIP -ieq "y") { $currentIP } else { $whichIP }
Show-Message "New IP for DDNS: $new_ip" $Colors['Secondary']

$useCloudflare = (Prompt-User "Update Cloudflare? (Y/N)").ToLower() -eq "y"
$useCPanel = (Prompt-User "Update cPanel? (Y/N)").ToLower() -eq "y"

if ($useCloudflare) {
    Show-Section "Cloudflare DDNS Update" $Colors['Accent']

    # see /UpdateDDNS.ps1

    Show-Message "Cloudflare Done." $Colors['Accent']
}

if ($useCPanel) {
    Show-Section "cPanel DDNS Update" $Colors['Secondary']

    # see /UpdateDDNS.ps1

    Show-Message "cPanel Done." $Colors['Accent']
}

Show-Message "DDNS Updater End." $Colors['Secondary']
