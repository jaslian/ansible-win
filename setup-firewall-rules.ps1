$portNumber = $Env:SSHD_LISTEN_PORT_NUMBER
Write-Host "Setting up firewall rules"
$firewallRuleName = "OpenSSH-Server-In-TCP"
$firewallRuleDisplayName = "Allow OpenSSH-Server to listen on TCP port 22"

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name $firewallRuleName -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule $firewallRuleName does not exist, creating it..."
    New-NetFirewallRule -Name $firewallRuleName -DisplayName $firewallRuleDisplayName -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort $portNumber
}
else {
    Write-Output "Firewall rule $firewallRuleName has been created and exists."
    Set-NetFirewallRule -Name $firewallRuleName -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort $portNumber
}

Pause
