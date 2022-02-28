#at top of script
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

function Install-Chocolatey {
    Install-PackageProvider Chocolatey -scope CurrentUser
    Set-PackageSource -name Chocolatey -trusted
}

function Install-ChocolateyBase {
    try {
        $testchoco = choco -v
        # Install Chocolatey if not found
        if ((-not($testchoco)) -or ($testchoco.length -gt 10)) {
            Install-Chocolatey
        }
        else {
            Write-Output "Chocolatey Version $testchoco is already installed"
        }
    }
    catch {
        Write-Error $_.Exception
    }
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Set-ExecutionPolicy AllSigned

# Install-Scoop
Install-ChocolateyBase

Write-Output "Installing Chocolatey packages"

# The following enables allowGlobalConfirmation - install without confirmation prompts.
choco feature enable -n=allowGlobalConfirmation

# Basic
choco install 7zip.install -y
choco install 7zip.commandline -y
choco install git.install -y
choco install dotnet4.0 -y
choco install vscode -y
choco install msiafterburner -y
choco install open-shell --pre -y

# Browsers
# choco install googlechrome -y
# choco install firefox -y

# Runtime and SDK
# choco install dotnet4.5 -y
# choco install dotnet4.7 -y
# choco install dotnetfx -y
# choco install VCredist-All -y
# choco install JavaRuntime -y
# choco install cygwin -y
# choco install oraclejdk -y
# choco install python3 --pre -y
# choco install pip -y
# choco install anaconda3 -y
# choco install nodejs -y
# choco install golang -y
# choco install postman -y

# IDEs
# choco install jetbrainstoolbox -y
# choco install goland -y
# choco install intellijidea-ultimate -y
# choco install androidstudio -y
# choco install android-sdk -y
# choco install dart-sdk
# choco install flutter -y

# IM and meeting
# choco install telegram.install -y
# choco install skype -y
# choco install discord -y
# choco install steam -y
# choco install zoom -y
# choco install microsoft-teams -y
# choco install slack -y

# Audio and Video
# choco install vlc -y
# choco install spotify -y
# choco install obs-studio -y
# choco install audacity -y

# DevOps tools
# choco install docker-desktop -y
# choco install terraform -y
# choco install kubernetes-cli -y
# choco install kubernetes-helm -y
# choco install minikube -y

# Other tools
# choco install Rufus -y
# choco install Putty -y
# choco install winscp -y
# choco install NotepadPlusPlus.install -y
# choco install adobereader -y
# choco install xnviewmp -y
# choco install expressvpn -y
# choco install virtualbox -y


Pause
Write-Output "Completing setup......"
