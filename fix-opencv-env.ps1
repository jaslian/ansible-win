# Function to log messages with timestamp
function Write-Log {
    param(
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message" -ForegroundColor $(
        switch ($type) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

try {
    $installBase = "I:\onedrive\repo\ansible-win\install"

    # Define required environment variables
    $envVars = @{
        "OPENCV_DIR"         = $installBase
        "OPENCV_BIN_DIR"     = Join-Path $installBase "x64\mingw\bin"
        "OPENCV_LIB_DIR"     = Join-Path $installBase "x64\mingw\lib"
        "OPENCV_INCLUDE_DIR" = Join-Path $installBase "include"
        "OPENCV_VERSION"     = "4.8.0"
        "PKG_CONFIG_PATH"    = Join-Path $installBase "x64\mingw\lib\pkgconfig"
    }

    # Set environment variables
    foreach ($var in $envVars.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "User")
        Write-Log "Set ${var.Key} = $($var.Value)" "SUCCESS"
    }

    # Update PATH
    $binPath = $envVars["OPENCV_BIN_DIR"]
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notmatch [regex]::Escape($binPath)) {
        $newPath = "$userPath;$binPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Log "Added OpenCV bin directory to PATH" "SUCCESS"
    }

    Write-Log "Environment configuration completed successfully" "SUCCESS"
    Write-Log "Please restart your terminal/IDE for changes to take effect" "WARNING"
}
catch {
    Write-Log "Error configuring environment: $_" "ERROR"
}
