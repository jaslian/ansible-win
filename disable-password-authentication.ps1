### IMPORTANT, aka last but not least !
# To enable and restrict ssh connections to key-based authentication only,
# we need to comment out the files in C:\ProgramData\ssh\sshd_config
# namely as follows:

# Match Group administrators
#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
#
#and probably want to change to the following:
#PasswordAuthentication no
#
# SO, accomplishing this VIA powershell:

Pause
Write-Host "Disabling password authentication"
$sshdConfigPath = 'C:\ProgramData\ssh\sshd_config'

(Get-Content $sshdConfigPath) -replace "Match Group administrators", "# Match Group administrators" | Set-Content $sshdConfigPath

(Get-Content $sshdConfigPath) -replace "       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys", "#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys " | Set-Content $sshdConfigPath

(Get-Content $sshdConfigPath) -replace "PasswordAuthentication yes", "PasswordAuthentication no" | Set-Content $sshdConfigPath

# Covering both possibilities for thoroughness
(Get-Content $sshdConfigPath) -replace "#PasswordAuthentication no", "PasswordAuthentication no" | Set-Content $sshdConfigPath

# Enable Pubkey Authentication
(Get-Content $sshdConfigPath) -replace "#PubkeyAuthentication no", "PubkeyAuthentication yes" | Set-Content $sshdConfigPath

(Get-Content $sshdConfigPath) -replace "#PubkeyAuthentication yes", "PubkeyAuthentication yes" | Set-Content $sshdConfigPath

Pause
