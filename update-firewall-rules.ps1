Write-Host "Updating IP based firewall rules"

# Start setting up the firewall rule for OpenSSH
$fwRule = Get-NetFirewallrule -Name "OpenSSH-Server-In-TCP"

# !!! ADJUST THESE !!! Modify accordingly for the desired remote IPs you want to permit to access the host in question.
$ips = @($Env:ALLOWED_IPV4_ADDRESS, $Env:ALLOWED_IPV4_ADDRESS_RANGE)

foreach ($r in $fwRule) { Set-NetFirewallRule -Name $r.Name -RemoteAddress $ips }

## Restart sshd to implement the changes made
Write-Host "Restarting sshd service"
Restart-Service sshd
Pause
