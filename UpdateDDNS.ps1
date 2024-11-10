#requires -Version 7.1

[cmdletbinding()]

param (
	[string]$domain = "simonquasar.net",
	[string]$subdomain = "shinigami",
	[string]$domainIP = "66.45.227.43",
	[string]$fullDomain = "$subdomain.$domain",
	[string]$ttl = "300",
	[string]$recordType = "A"
)

#COLORS: Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White

Write-Host " "			
Write-Host "==== DDNS Updater for [" -ForegroundColor Yellow -BackgroundColor DarkBlue -NoNewline
Write-Host "$fullDomain" -ForegroundColor White -BackgroundColor DarkBlue -NoNewline
Write-Host "] ====" -ForegroundColor Yellow -BackgroundColor DarkBlue -NoNewLine; Write-Host " "			

# Current IP
$currentIP = (Invoke-RestMethod -Uri "http://ipinfo.io/ip").Trim()

Write-Host " "
Write-Host " Your IP: $currentIP " -ForegroundColor Yellow
Write-Host " "			

$whichIP = $(Write-Host " Use $currentIP ? (Or enter custom IP) " -ForegroundColor White -NoNewLine; Read-Host) 
if (-not ($whichIP -eq "" -or $whichIP -eq "Y" -or $whichIP -eq "y")) { 
	$new_ip = $whichIP 
} else { 
	$new_ip = $currentIP 
}
Write-Host " New IP for DDNS: $new_ip " -ForegroundColor Yellow

Write-Host " "
$useCloudflare = $(Write-Host " Update" -ForegroundColor White -NoNewLine) + $(Write-Host " Cloudflare? " -ForegroundColor DarkYellow -NoNewLine) + $(Write-Host "(Y/N) " -ForegroundColor White -NoNewLine; Read-Host) 
$useCPanel = $(Write-Host " Update" -ForegroundColor White -NoNewLine) + $(Write-Host " cPanel? " -ForegroundColor yellow -NoNewLine) + $(Write-Host "(Y/N) " -ForegroundColor White -NoNewLine; Read-Host) 

$useCloudflare = ($useCloudflare -eq "Y" -or $useCloudflare -eq "y")
$useCPanel = ($useCPanel -eq "Y" -or $useCPanel -eq "y")


if ($useCloudflare) {
	Write-Host " "			
	Write-Host "== Cloudflare DDNS Update" -ForegroundColor Black -BackgroundColor DarkYellow -NoNewline; Write-Host " "			
	
	$CFToken = "ouPO9rItEZaA7TkJQEPpq8zAtwieayQ1osFCSUyT"
	$email = "s@simonquasar.net"
	
	# Build the request headers.
	$headers = @{
		"X-Auth-Email"  = $($email)
		"Authorization" = "Bearer $($CFToken)"
		"Content-Type"  = "application/json"
	}

	## This block verifies that your API key is valid.
	Write-Host "API Token validation..." -ForegroundColor DarkYellow

	$uri = "https://api.cloudflare.com/client/v4/user/tokens/verify"

	$auth_result = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -SkipHttpErrorCheck
	if (-not($auth_result.result)) {
		Write-Host "API token validation failed. Error: $($auth_result.errors.message). Terminating script." -ForegroundColor Red
		return
	}
	Write-Host "$($auth_result.messages.message)." -ForegroundColor DarkYellow

	#Region Get Zone ID
	## Retrieves the domain's zone identifier based on the zone name.
	$uri = "https://api.cloudflare.com/client/v4/zones?name=$($domain)"
	$DnsZone = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -SkipHttpErrorCheck
	if (-not($DnsZone.result)) {
		Write-Host "Search for the DNS domain [$($domain)] return zero results. Terminating script." -ForegroundColor Red
		return
	}
	## Store the DNS zone ID
	$zone_id = $DnsZone.result.id
	
	Write-Host "Domain zone [" -ForegroundColor DarkYellow -NoNewline
		Write-Host "$($domain)" -ForegroundColor White -NoNewline
		Write-Host "] ID [" -ForegroundColor DarkYellow -NoNewline	   
		Write-Host "$($zone_id)" -ForegroundColor White  -NoNewline
		Write-Host "]" -ForegroundColor DarkYellow	 
		
	#Region Get DNS Record
	## Retrieve the existing DNS record details from Cloudflare.
	$uri = "https://api.cloudflare.com/client/v4/zones/$($zone_id)/dns_records?name=$($fullDomain)"
	$DnsRecord = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -SkipHttpErrorCheck
	if (-not($DnsRecord.result)) {
		Write-Host "Search for the DNS record [$($fullDomain)] return zero results. Terminating script." -ForegroundColor Red
		return
	}
	## Store the existing IP address in the DNS record
	$old_ip = $DnsRecord.result.content
	## Store the DNS records values
	$record_type = $DnsRecord.result.type
	$record_id = $DnsRecord.result.id
	$record_ttl = $DnsRecord.result.ttl
	$record_proxied = $DnsRecord.result.proxied
	Write-Host "DNS record [" -ForegroundColor DarkYellow -NoNewline
		Write-Host "$($fullDomain)" -ForegroundColor White -NoNewline
		Write-Host ", Type=" -ForegroundColor DarkYellow -NoNewline	   
		Write-Host "$($record_type)" -ForegroundColor White -NoNewline
		Write-Host ", TTL=" -ForegroundColor DarkYellow -NoNewline	   
		Write-Host "$($record_ttl)" -ForegroundColor White -NoNewline
		Write-Host ", IP=" -ForegroundColor DarkYellow -NoNewline	   
		Write-Host "$($old_ip)" -ForegroundColor White -NoNewline
		Write-Host "]" -ForegroundColor DarkYellow	   
		
	Write-Host "Public IP Address: OLD [" -ForegroundColor DarkYellow -NoNewline
		Write-Host "$($old_ip)" -ForegroundColor White -NoNewline
		Write-Host "] >> NEW [" -ForegroundColor DarkYellow -NoNewline	   
		Write-Host "$($new_ip)" -ForegroundColor White  -NoNewline
		Write-Host "]" -ForegroundColor DarkYellow	   
		
		
	#Region update Dynamic DNS Record
	## Compare current IP address with the DNS record
	## If the current IP address does not match the DNS record IP address, update the DNS record.
	
	if ($new_ip -ne $old_ip) {
		Write-Host "Attempt to update..."  -ForegroundColor DarkYellow
		## Update the DNS record with the new IP address
		$uri = "https://api.cloudflare.com/client/v4/zones/$($zone_id)/dns_records/$($record_id)"
		$body = @{
			type    = $record_type
			name    = $fullDomain
			content = $new_ip
			ttl     = $record_ttl
			proxied = $record_proxied
		} | ConvertTo-Json

		$Update = Invoke-RestMethod -Method PUT -Uri $uri -Headers $headers -SkipHttpErrorCheck -Body $body
		if (($Update.errors)) {
			Write-Host "Cloudflare DNS record update" -ForegroundColor DarkYellow -NoNewline
			Write-Host " failed." -ForegroundColor red
			Write-Host "ERROR: $($Update[0].errors.message)" -ForegroundColor Red -BackgroundColor DarkGray -NoNewLine; Write-Host " ";
			## Exit script
		}

		Write-Host "Cloudflare DNS record update" -ForegroundColor DarkYellow -NoNewline
		Write-Host " successful." -ForegroundColor Green
		#Write-Host $Update.result
	}
	else {
		Write-Host "Cloudflare DNS record " -ForegroundColor DarkYellow -NoNewline
		Write-Host "no need to update." -ForegroundColor Green
	}

	Write-Host "== Cloudflare Done."  -ForegroundColor Black -BackgroundColor DarkYellow -NoNewline; Write-Host " "
	#EndRegion
}

if ($useCPanel) {
	Write-Host " "			
    Write-Host "== cPanel DDNS Update" -ForegroundColor Black -BackgroundColor Yellow -NoNewline; Write-Host " "

    #region Update Dynamic DNS Record on cPanel	
		$DDNSid = "exzaxceynwfkkxiflvjrbllzxnfcmhtb"
		$serial = "2318283295"
		
		###########################################################################################
		# THE FOLLOWING WEBCALL RESETS TO 127.0.0.1
		##########################################################################################
		#$dns_ip = Invoke-RestMethod -Uri "https://simonquasar.net/cpanelwebcall/$DDNSid"
		#$dns_ip = $dns_ip.Substring(6)
		#Write-Host "cPanel Zone DNS IP: [" -ForegroundColor Yellow -NoNewline
		#Write-Host "$($dns_ip)" -ForegroundColor White -NoNewline
		#Write-Host "]" -ForegroundColor Yellow	
		
		# API credentials
		$apiKey = "TGBCP5728KYRQTQD9SAJKPRLG96I0ZLV"
		$apiUser = "simonqua"

		# Construct the headers and content type
		$headers = @{
			Authorization = "cpanel $($apiUser):$($apiKey)"
		}

		Write-Host "API Domain: ["  -ForegroundColor Yellow -NoNewline
		Write-Host "$($domain)" -ForegroundColor White -NoNewline
		Write-Host "]" -ForegroundColor Yellow	
		Write-Host "API Server IP: ["  -ForegroundColor Yellow -NoNewline
		Write-Host "$($domainIP)" -ForegroundColor White -NoNewline
		Write-Host "]" -ForegroundColor Yellow	
		Write-Host "API Subdomain: ["  -ForegroundColor Yellow -NoNewline
		Write-Host "$($subdomain)" -ForegroundColor White -NoNewline
		Write-Host "]" -ForegroundColor Yellow	

		#DNS PARSER
		$parse_url = "https://$($domain):2083/execute/DNS/parse_zone?zone=simonquasar.net"

		Write-Host "Parsing DNS @ [" -ForegroundColor Yellow -NoNewline
		Write-Host "$($domain)" -ForegroundColor White -NoNewline
		Write-Host "] .." -ForegroundColor Yellow	
		
		$parsed =Invoke-RestMethod -Uri $parse_url -Headers $headers -Method GET
		
		#logging
		foreach ($data in $parsed.data) {			
			foreach ($text_b64 in $data.text_b64) {
				$decodedText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($text_b64))
#log			 Write-Host "$decodedText" -ForegroundColor Cyan -NoNewLine
			}
			foreach ($dname_b64 in $data.dname_b64) {
				$decodedDname = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($dname_b64))
#log				Write-Host "$decodedDname" -ForegroundColor Cyan -NoNewLine
				if ($decodedDname -eq $subdomain) {
					$lineIndex = $data.line_index
					Write-Host "[" -ForegroundColor Yellow -NoNewline
					Write-Host "$($decodedDname)" -ForegroundColor White -NoNewline
					Write-Host "] record @ Line Index ["  -ForegroundColor Yellow -NoNewline
					Write-Host "$($lineIndex)" -ForegroundColor White -NoNewline
					Write-Host "]" -ForegroundColor Yellow	
					$old_ip = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($data.data_b64))
#log				Write-Host "$($old_ip)" -ForegroundColor Blue
				} 
			}
			
#log			 Write-Host "$data" -ForegroundColor Blue
		}
		
		#Write-Host "$($parsed)" -ForegroundColor Cyan -BackgroundColor DarkGray -NoNewline; Write-Host " "
		
		if ($parsed){
			Write-Host "Public IP Address: OLD [" -ForegroundColor Yellow -NoNewline
			Write-Host "$($old_ip)" -ForegroundColor White -NoNewline
			Write-Host "] >> NEW [" -ForegroundColor Yellow -NoNewline	   
			Write-Host "$($new_ip)" -ForegroundColor White  -NoNewline
			Write-Host "]" -ForegroundColor Yellow	
		} else {
			Write-Host "Parse Error." -ForegroundColor Red
			return
		}

		if ($new_ip -ne $old_ip) {
		
			# Query the SOA record using nslookup
			
			Write-Host "Querying the SOA record.." -ForegroundColor Yellow

			$soaOutput = nslookup -type=SOA $fullDomain
			$soaSerial = $soaOutput | Select-String "Serial" | ForEach-Object { $_.Line -replace "[^\d]", "" }

			if ($soaSerial) {
	#log		Write-Output "$soaOutput" -ForegroundColor Blue
				$serial = $soaSerial;
				Write-Host "SOA Serial for ["  -ForegroundColor Yellow -NoNewline
						Write-Host "$($fullDomain)" -ForegroundColor White -NoNewline
						Write-Host "] is [" -ForegroundColor Yellow	-NoNewline
						Write-Host "$($serial)" -ForegroundColor White -NoNewline
						Write-Host "]" -ForegroundColor Yellow
			} else {
				Write-Output "SOA serial not found for $fullDomain." -ForegroundColor Red
				return
			}
			
			
			Write-Host "Construct the API request.." -ForegroundColor Yellow

			$module = "DNS"
			$function = "mass_edit_zone"
			
			$jsonParams = @{
				"line_index" = $lineIndex
				"dname" = $subdomain
				"ttl" = $ttl
				"record_type" = $recordType
				"data" = @($new_ip)
			}

			$jsonString = $jsonParams | ConvertTo-Json -Compress

			$queryParams = @{
				"zone" = "simonquasar.net"
				"serial" = $serial
				"edit" = $jsonString
			}
			
			$queryString = ($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=" + [Uri]::EscapeDataString($_.Value) }) -join "&"
			
			$url = "https://$($domain):2083/execute/$Module/$($function)?$($queryString)"
					
			Write-Host "Trying with found SOA Serial.." -ForegroundColor Yellow -NoNewLine

				$firstResponse =Invoke-RestMethod -Uri $url -Headers $headers -Method GET
		#		Write-Host "$($firstResponse)" -ForegroundColor Cyan
				
				foreach ($error in $firstResponse.errors) {			
					# Find all matches of the pattern in the input string
					$pattern = "\((\d+)\)"
					$matches = [regex]::Matches($error, $pattern)
					if ($matches.Count -ge 2) {
						# Extract the second match's group value (digits)
						$newSerial = $matches[1].Groups[1].Value
						$serial = $newSerial
						Write-Host " corrected."  -ForegroundColor Green

					} else {
						Write-Host " No Serial found."  -ForegroundColor Red
						return
					}
				}
			
			Write-Host "SOA Serial: ["  -ForegroundColor Yellow -NoNewline
			Write-Host "$($serial)" -ForegroundColor White -NoNewline
			Write-Host "]" -ForegroundColor Yellow	
		
			# Construct the API request data

			$queryParams = @{
				"zone" = $domain
				"serial" = $serial
				"edit" = $jsonString
			}

			$queryString = ($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=" + [Uri]::EscapeDataString($_.Value) }) -join "&"
			
			$url = "https://$($domain):2083/execute/$Module/$($function)?$($queryString)"
			
	#		Write-Host "URL Endpoint: [" -ForegroundColor Yellow -NoNewline
	#		Write-Host "$($url)" -ForegroundColor White -NoNewline
	#		Write-Host "]" -ForegroundColor Yellow	

			Write-Host "Requesting update.." -ForegroundColor Yellow

			# Send the API request
			$response =Invoke-RestMethod -Uri $url -Headers $headers -Method GET

			Write-Host "cPanel DNS record update " -ForegroundColor Yellow -NoNewline

			# Display the response
			if ($response.errors) {
				
				# Display errors, if any
				foreach ($error in $response.errors) {
					Write-Host "Error: $error" -ForegroundColor Red
				}

				# Display warnings, if any
				foreach ($warning in $response.warnings) {
					Write-Host "Warning: $warning" -ForegroundColor DarkYellow
				}

				Write-Host "$($response)" -ForegroundColor Red -BackgroundColor DarkGray -NoNewline; Write-Host " "

			} elseif ($response){
				Write-Host "successful." -ForegroundColor Green
				foreach ($data in $response.data) {
				
					Write-Host "$data" -ForegroundColor DarkGray
					
					foreach ($data_b64 in $response.data.data_b64) {
						$data_b64 = [System.Convert]::FromBase64String($data_b64)
						$data_b64 = [System.Text.Encoding]::UTF8.GetString($data_b64)
						#Write-Host "$data_b64" -ForegroundColor Cyan
					}
				}
	#			Write-Host "$($response)" -ForegroundColor Green -BackgroundColor DarkGray -NoNewline; Write-Host " "
			}
			else {
				Write-Host "Error: Code exception :(" -ForegroundColor Magenta
			}
		}
		else {
			Write-Host "cPanel DNS record " -ForegroundColor Yellow -NoNewline
			Write-Host "no need to update." -ForegroundColor Green
		}

	Write-Host "== cPanel Done." -ForegroundColor Black -BackgroundColor Yellow -NoNewline; Write-Host " "	
    #endregion
	
}

Write-Host " "
Write-Host "==== DDNS Updater End." -ForegroundColor Yellow -BackgroundColor DarkBlue -NoNewLine	
Write-Host " "		
Write-Host " "	