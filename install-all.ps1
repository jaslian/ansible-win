Start-Transcript -Append ".\log.txt"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

#install-all.ps1
if (!
    #current role
    (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
        #is admin?
    )).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {
    #elevate script and exit current non-elevated runtime
    Start-Process `
        -FilePath 'powershell' `
        -ArgumentList (
        #flatten to single array
        '-File', $MyInvocation.MyCommand.Source, $args `
        | % { $_ }
    ) `
        -Verb RunAs
    exit
}

# Detect Elevation:
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$UserPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)
$AdminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
$IsAdmin = $UserPrincipal.IsInRole($AdminRole)
if ($IsAdmin) {
    Write-Host "Script is running elevated."
}
else {
    throw "Script is not running elevated, which is required. Restart the script from an elevated prompt."
}

$hostName = [System.Net.Dns]::GetHostName()
$Env:WIN_NODE_HOST_NAME = $hostName

Write-Output "Initiate powershell installation on host $hostName"

# Install chocolatey
Write-Output "Installing chocolatey"
& "$PSScriptRoot\install-choco.ps1"

# Initial install of OpenSSH sshd server
Write-Output "Setting up OpenSSH sshd server"
& "$PSScriptRoot\setup-ssh-server.ps1"

# Set up firewall ruls
Write-Output "Setting up firewall ruls"
& "$PSScriptRoot\setup-firewall-rules.ps1"

# Update firewall rule IP addresses
Write-Output "Updating firewall rules for IP addresses"
& "$PSScriptRoot\update-firewall-rules.ps1"

# Disable password sshd_config
Write-Output "Disabling password authentication sshd_config"
& "$PSScriptRoot\disable-password-authentication.ps1"

# Update public keys for sshd_config
Write-Output "Updating public keys for sshd_config"

# Load public key based on the host name
$hostName = [System.Net.Dns]::GetHostName()
& "$PSScriptRoot\pubkeys\$hostName.ps1"

Write-Output "Updating public key for ssh on $hostName to:"
Write-Output $Env:SSHD_PUB_KEY

& "$PSScriptRoot\update-public-ssh-keys.ps1"
