# Function to log messages with timestamp and color
function Write-Log {
    param(
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($type) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] $message" -ForegroundColor $color
    Add-Content -Path "opencv_verify.log" -Value "[$timestamp] $message"
}

# Function to check if environment variable exists and matches expected value
function Test-EnvVariable {
    param(
        [string]$varName,
        [string]$expectedValue
    )

    $userValue = [Environment]::GetEnvironmentVariable($varName, "User")
    $systemValue = [Environment]::GetEnvironmentVariable($varName, "Machine")

    Write-Log "Checking ${varName}:" "INFO"
    Write-Log "  Expected: $expectedValue" "INFO"
    Write-Log "  User   : $userValue" $(if($userValue -eq $expectedValue){"SUCCESS"}else{"WARNING"})
    Write-Log "  System : $systemValue" $(if($systemValue -eq $expectedValue){"SUCCESS"}else{"WARNING"})

    return ($userValue -eq $expectedValue) -or ($systemValue -eq $expectedValue)
}

# Function to verify OpenCV installation
function Test-OpenCVInstallation {
    param([string]$installPath)

    Write-Log "Verifying OpenCV installation at: $installPath" "INFO"

    # Define required paths and files
    $paths = @{
        "Base Directory" = $installPath
        "Binary Directory" = Join-Path $installPath "x64\mingw\bin"
        "Library Directory" = Join-Path $installPath "x64\mingw\lib"
        "Include Directory" = Join-Path $installPath "include"
        "PKG Config Directory" = Join-Path $installPath "x64\mingw\lib\pkgconfig"
    }

    $files = @{
        "Core DLL" = Join-Path $paths["Binary Directory"] "libopencv_core480.dll"
        "FFMPEG DLL" = Join-Path $paths["Binary Directory"] "opencv_videoio_ffmpeg480_64.dll"
        "Core Headers" = Join-Path $paths["Include Directory"] "opencv2\core.hpp"
        "Core Library" = Join-Path $paths["Library Directory"] "libopencv_core480.dll.a"
        "PKG Config" = Join-Path $paths["PKG Config Directory"] "opencv4.pc"
    }

    # Check paths and files
    $allExist = $true
    foreach ($item in $paths.GetEnumerator()) {
        if (Test-Path $item.Value) {
            Write-Log "FOUND: $($item.Key)" "SUCCESS"
        } else {
            Write-Log "MISSING: $($item.Key)" "ERROR"
            $allExist = $false
        }
    }

    foreach ($item in $files.GetEnumerator()) {
        if (Test-Path $item.Value) {
            Write-Log "FOUND: $($item.Key)" "SUCCESS"
        } else {
            Write-Log "MISSING: $($item.Key)" "ERROR"
            $allExist = $false
        }
    }

    return $allExist
}

# Function to update OpenCV environment
function Update-OpenCVEnvironment {
    param([string]$installPath)

    Write-Log "Checking OpenCV environment variables" "INFO"

    $envVars = @{
        "OPENCV_DIR" = $installPath
        "OPENCV_BIN_DIR" = Join-Path $installPath "x64\mingw\bin"
        "OPENCV_LIB_DIR" = Join-Path $installPath "x64\mingw\lib"
        "OPENCV_INCLUDE_DIR" = Join-Path $installPath "include"
        "OPENCV_VERSION" = "4.8.0"
        "PKG_CONFIG_PATH" = Join-Path $installPath "x64\mingw\lib\pkgconfig"
    }

    $needsUpdate = $false
    foreach ($var in $envVars.GetEnumerator()) {
        if (-not (Test-EnvVariable -varName $var.Key -expectedValue $var.Value)) {
            Write-Log "Setting $($var.Key) = $($var.Value)" "INFO"
            [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "User")
            $needsUpdate = $true
        }
    }

    # Update PATH if needed
    $binPath = $envVars["OPENCV_BIN_DIR"]
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notmatch [regex]::Escape($binPath)) {
        Write-Log "Adding OpenCV to PATH" "INFO"
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$binPath", "User")
        $needsUpdate = $true
    }

    if ($needsUpdate) {
        Write-Log "Environment variables updated. Please restart your terminal." "WARNING"
    } else {
        Write-Log "Environment variables are correctly set" "SUCCESS"
    }

    return $true
}

# Function to show OpenCV diagnostics
function Show-OpenCVDiagnostics {
    Write-Log "OpenCV Diagnostics:" "INFO"
    Write-Log "PATH entries:" "INFO"
    $env:PATH -split ';' | ForEach-Object { Write-Log "  $_" "INFO" }

    Write-Log "`nOpenCV DLLs:" "INFO"
    Get-ChildItem $env:OPENCV_BIN_DIR -Filter "*.dll" | ForEach-Object {
        Write-Log "  $($_.Name)" "INFO"
    }

    Write-Log "`nCompiler version:" "INFO"
    $gppVersion = g++ --version 2>&1
    Write-Log $gppVersion "INFO"
}

# Function to test OpenCV compilation
function Test-OpenCVCompilation {
    # First check if g++ is available
    if (-not (Get-Command "g++" -ErrorAction SilentlyContinue)) {
        Write-Log "g++ compiler not found in PATH" "ERROR"
        return $false
    }

    # Check MinGW environment
    Write-Log "Checking MinGW environment..." "INFO"
    $mingwTools = @("g++", "mingw32-make")
    foreach ($tool in $mingwTools) {
        if (Get-Command $tool -ErrorAction SilentlyContinue) {
            $toolPath = (Get-Command $tool).Source
            Write-Log "Found $tool at: $toolPath" "SUCCESS"
        } else {
            Write-Log "Missing required tool: $tool" "ERROR"
            return $false
        }
    }

    # Simpler test code first
    $testCode = @"
#include <opencv2/core.hpp>
int main() {
    cv::Mat m(2,2, CV_8UC3, cv::Scalar(0,0,255));
    return 0;
}
"@

    try {
        $testDir = "opencv_test"
        New-Item -ItemType Directory -Force -Path $testDir | Out-Null
        Set-Location $testDir

        $testCode | Out-File -FilePath "test.cpp" -Encoding ASCII

        # Try different compilation approaches
        $compileCmds = @(
            # Attempt 1: Basic compilation
            'cmd /c "g++ test.cpp -o test.exe -I""$env:OPENCV_INCLUDE_DIR"" -L""$env:OPENCV_LIB_DIR"" -lopencv_core480"',
            # Attempt 2: With pkg-config
            'cmd /c "g++ test.cpp -o test.exe $(pkg-config --cflags --libs opencv4)"',
            # Attempt 3: With explicit paths and more libraries
            'cmd /c "g++ test.cpp -o test.exe -I""$env:OPENCV_INCLUDE_DIR"" -L""$env:OPENCV_LIB_DIR"" -lopencv_core480 -lopencv_imgproc480 -lopencv_highgui480"'
        )

        foreach ($cmd in $compileCmds) {
            Write-Log "Attempting compilation with: $cmd" "INFO"
            try {
                $compileResult = Invoke-Expression $cmd 2>&1

                if (Test-Path "test.exe") {
                    Write-Log "Compilation successful" "SUCCESS"

                    # Test execution
                    $env:PATH = "$env:OPENCV_BIN_DIR;$env:PATH"
                    $testResult = Start-Process .\test.exe -Wait -NoNewWindow -PassThru

                    if ($testResult.ExitCode -eq 0) {
                        Write-Log "Test execution successful" "SUCCESS"
                        return $true
                    }
                    Write-Log "Test execution failed with exit code: $($testResult.ExitCode)" "ERROR"
                }
            }
            catch {
                Write-Log "Compilation attempt failed: $_" "WARNING"
            }
            Remove-Item -Path "test.exe" -ErrorAction SilentlyContinue
        }

        Write-Log "All compilation attempts failed" "ERROR"
        Write-Log "Last error: $compileResult" "ERROR"
        return $false
    }
    catch {
        Write-Log "Test failed with error: $_" "ERROR"
        return $false
    }
    finally {
        Set-Location ..
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Main execution
try {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $installPath = Join-Path $scriptPath "install"

    Write-Log "Starting OpenCV MinGW verification" "INFO"

    $installOk = Test-OpenCVInstallation $installPath
    $envOk = Update-OpenCVEnvironment $installPath
    Show-OpenCVDiagnostics
    $testOk = Test-OpenCVCompilation

    Write-Log "`nVerification Summary:" "INFO"
    Write-Log "Installation Check: $(if($installOk){'PASS'}else{'FAIL'})" $(if($installOk){'SUCCESS'}else{'ERROR'})
    Write-Log "Environment Setup: $(if($envOk){'PASS'}else{'FAIL'})" $(if($envOk){'SUCCESS'}else{'ERROR'})
    Write-Log "Compilation Test: $(if($testOk){'PASS'}else{'FAIL'})" $(if($testOk){'SUCCESS'}else{'ERROR'})

    if ($installOk -and $envOk -and $testOk) {
        Write-Log "`nOpenCV is correctly installed and configured" "SUCCESS"
    } else {
        Write-Log "`nOpenCV installation needs attention" "ERROR"
    }
}
catch {
    Write-Log "Script execution failed: $_" "ERROR"
}
