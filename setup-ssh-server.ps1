# Based on: https://github.com/illudium/ssh_install_and_secure_config_for_windows

$port = $Env:SSHD_LISTEN_PORT_NUMBER

try {
    # OPTIONAL but recommended:
    Set-Service -Name sshd -StartupType 'Automatic'
} catch {
    Write-Host "SSH service not found. Skipping."
    Write-Error $_.Exception
}

try {
    # Install ssh client from PowerShell
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

    # Install sshd server from PowerShell
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # OPTIONAL but recommended:
    Set-Service -Name sshd -StartupType 'Automatic'

    # Authenticate to the proxy using the following command
    [System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials

    # To be able to use SSH keys to authenticate, install the following module:
    # Install-Module -Force OpenSSHUtils -Scope AllUsers -Confirm:$false

    # Start the sshd service and agent
    Set-Service -Name ssh-agent -StartupType Automatic
    Start-Service ssh-agent
    Set-Service -Name sshd -StartupType Automatic
    Start-Service sshd
} catch {
    Write-Error $_.Exception -ErrorAction Stop
}

#Set Shell to powershell
Write-Host "Setting default shell to powershell"
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force -ErrorAction Stop | Out-Null

Write-Host "Installation completed successfully"
