$sshPubKey = $Env:SSHD_PUB_KEY
$sshHome = "$HOME\.ssh"
$sshHomeAuthKeys = "$sshHome\authorized_keys"

## Setup ssh key-based authentication.
# ADJUST AS NEEDED based on the account-name in question on your endpoints, "localadmin" here is a suggestion.
# You ALSO MUST of course, replace the item below 'Place the... (etc) with the content of your desired pub key portion of your ssh key.
# Ed25519 is recommended and works from macOS (Mojave, Catalina) to Windows. See https://medium.com/risan/upgrade-your-ssh-key-to-ed25519-c6e8d60d3c54

Write-Host "Setting up ssh key-based authentication"

if (!(Test-Path $sshHome)) {
    Write-Host "Creating directory $sshHome"
    New-Item -Path $sshHome -ItemType Directory
} else {
    Write-Host "Found directory $sshHome"
}

if (!(Test-Path $sshHomeAuthKeys)) {
    Write-Host "Creating file $sshHomeAuthKeys"
    New-Item -Path $sshHomeAuthKeys -ItemType File
} else {
    Write-Host "Found file $sshHomeAuthKeys"
}

Write-Host "Updating file to add the pub key"
Add-Content -Path $sshHomeAuthKeys -Value $sshPubKey

$portNumber = $Env:SSHD_LISTEN_PORT_NUMBER
# Update port number
Write-Output "Port number: $portNumber"
$sshdConfigPath = 'C:\ProgramData\ssh\sshd_config'
(Get-Content $sshdConfigPath) -replace "#Port 22", "Port 22" | Set-Content $sshdConfigPath
(Get-Content $sshdConfigPath) -replace "Port 22", "Port $portNumber" | Set-Content $sshdConfigPath

(Get-Content $sshdConfigPath) -replace "#MaxAuthTries 6", "MaxAuthTries 10" | Set-Content $sshdConfigPath

## Restart sshd to implement the changes made
Write-Host "Restarting sshd service"
Restart-Service sshd
