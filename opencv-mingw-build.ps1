# OpenCV Build Script for MinGW on Windows with rollback support

# Script configuration
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFolder = Join-Path $scriptPath "logs"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $logFolder "opencv_build_$timestamp.log"
$backupFolder = Join-Path $scriptPath "backup"
$buildDir = Join-Path $scriptPath "build"
$installDir = Join-Path $scriptPath "install"

# Function to ensure directory exists
function Ensure-Directory {
    param([string]$path)
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
        Write-Host "Created directory: $path"
    }
}

# Function to log messages
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $message"
    Write-Host $logMessage
    Ensure-Directory (Split-Path $logFile)
    Add-Content -Path $logFile -Value $logMessage
}

# Function to verify MinGW setup
function Verify-MinGW {
    Write-Log "Verifying MinGW installation..."

    # Check for mingw32-make
    $mingwMake = Get-Command mingw32-make -ErrorAction SilentlyContinue
    if (-not $mingwMake) {
        throw "mingw32-make not found in PATH"
    }

    # Create 'make' copy if it doesn't exist
    $mingwPath = Split-Path $mingwMake.Source
    $makePath = Join-Path $mingwPath "make.exe"
    if (-not (Test-Path $makePath)) {
        Write-Log "Creating make.exe copy from mingw32-make.exe"
        Copy-Item $mingwMake.Source $makePath
    }

    # Verify g++ and gcc
    $gpp = Get-Command g++ -ErrorAction SilentlyContinue
    $gcc = Get-Command gcc -ErrorAction SilentlyContinue

    if (-not ($gpp -and $gcc)) {
        throw "g++ or gcc not found in PATH"
    }

    Write-Log "MinGW verification completed successfully"
    return $mingwPath
}

# Function to handle errors and rollback
function Start-Rollback {
    param([string]$errorMessage)
    Write-Log "ERROR: $errorMessage"
    Write-Log "Starting rollback procedure..."

    if (Test-Path $buildDir) {
        Write-Log "Removing build directory: $buildDir"
        Remove-Item -Path $buildDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $backupFolder) {
        Write-Log "Restoring from backup..."
        Get-ChildItem -Path $backupFolder | ForEach-Object {
            $destPath = Join-Path $scriptPath ($_.FullName.Substring($backupFolder.Length))
            Copy-Item -Path $_.FullName -Destination $destPath -Force -Recurse -ErrorAction SilentlyContinue
        }
    }

    Write-Log "Rollback completed"
    exit 1
}

# Add this new function after existing functions
function Update-OpenCVEnvironment {
    param (
        [string]$installPath,
        [string]$opencvVersion
    )

    Write-Log "Configuring OpenCV environment variables..."

    try {
        # Define the paths we need to add
        $binPath = Join-Path $installPath "bin"
        $libPath = Join-Path $installPath "lib"
        $includePath = Join-Path $installPath "include"

        # Verify directories exist
        if (-not (Test-Path $binPath) -or -not (Test-Path $libPath) -or -not (Test-Path $includePath)) {
            throw "Required OpenCV directories not found in installation path"
        }

        # Update PATH
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        $userPath = ($userPath -split ';' | Where-Object { $_ -notmatch 'opencv|OpenCV' }) -join ';'
        $newUserPath = "$userPath;$binPath"
        [Environment]::SetEnvironmentVariable("PATH", $newUserPath, "User")
        Write-Log "Updated User PATH with OpenCV bin directory"

        # Set OpenCV environment variables
        $opencvVars = @{
            "OPENCV_DIR"       = $installPath
            "OPENCV_BIN_DIR"   = $binPath
            "OPENCV_LIB_DIR"   = $libPath
            "OPENCV_INCLUDE_DIR" = $includePath
            "OPENCV_VERSION"   = $opencvVersion
        }

        foreach ($var in $opencvVars.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "User")
            Write-Log "Set environment variable: $($var.Key) = $($var.Value)"
        }

        # Configure pkg-config
        $pkgConfigPath = Join-Path $libPath "pkgconfig"
        if (Test-Path $pkgConfigPath) {
            $pkgConfigVar = [Environment]::GetEnvironmentVariable("PKG_CONFIG_PATH", "User")
            if (-not $pkgConfigVar) {
                $pkgConfigVar = $pkgConfigPath
            } elseif ($pkgConfigVar -notmatch [regex]::Escape($pkgConfigPath)) {
                $pkgConfigVar += ";$pkgConfigPath"
            }
            [Environment]::SetEnvironmentVariable("PKG_CONFIG_PATH", $pkgConfigVar, "User")
            Write-Log "Updated PKG_CONFIG_PATH with OpenCV pkgconfig directory"
        }

        # Create verification batch file
        $testBatchPath = Join-Path $installPath "opencv_env_test.bat"
        @"
@echo off
echo Testing OpenCV Environment Configuration
echo.
echo PATH entries:
echo %PATH%
echo.
echo OpenCV Environment Variables:
echo OPENCV_DIR = %OPENCV_DIR%
echo OPENCV_BIN_DIR = %OPENCV_BIN_DIR%
echo OPENCV_LIB_DIR = %OPENCV_LIB_DIR%
echo OPENCV_INCLUDE_DIR = %OPENCV_INCLUDE_DIR%
echo OPENCV_VERSION = %OPENCV_VERSION%
echo.
echo PKG_CONFIG_PATH = %PKG_CONFIG_PATH%
pause
"@ | Out-File -FilePath $testBatchPath -Encoding ASCII

        Write-Log "Created environment test batch file: $testBatchPath"
        return $true
    }
    catch {
        Write-Log "ERROR: Failed to configure OpenCV environment: $_"
        return $false
    }
}

try {
    Write-Log "Creating necessary directories..."
    Ensure-Directory $logFolder
    Ensure-Directory $backupFolder
    Ensure-Directory $buildDir

    # Verify MinGW installation
    $mingwPath = Verify-MinGW

    # Set environment variables for CMake
    $env:CMAKE_MAKE_PROGRAM = Join-Path $mingwPath "make.exe"
    $env:PATH = "$mingwPath;$env:PATH"

    Write-Log "Checking required tools..."
    $requiredTools = @{
        "cmake"        = "CMake"
        "mingw32-make" = "MinGW"
        "git"          = "Git"
    }

    foreach ($tool in $requiredTools.Keys) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Start-Rollback "$($requiredTools[$tool]) not found. Please install it and add to PATH"
        }
    }

    # Create backup of existing build
    Write-Log "Creating backup..."
    if (Test-Path $buildDir) {
        Get-ChildItem -Path $buildDir | Copy-Item -Destination $backupFolder -Recurse -Force
    }

    # Set up OpenCV build
    $opencvVersion = "4.8.0"
    $opencvSource = Join-Path $buildDir "opencv-$opencvVersion"

    # Download OpenCV source if not exists
    if (-not (Test-Path $opencvSource)) {
        Write-Log "Downloading OpenCV source..."
        Set-Location $buildDir
        git clone -b $opencvVersion --depth 1 https://github.com/opencv/opencv.git "opencv-$opencvVersion"
    }

    # Create and enter build subdirectory
    $buildSubDir = Join-Path $buildDir "build"
    Ensure-Directory $buildSubDir
    Set-Location $buildSubDir

    # Configure CMake with explicit generator specification
    Write-Log "Configuring OpenCV build with CMake..."
    $cmakeArgs = @(
        "-G", """MinGW Makefiles""",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_INSTALL_PREFIX=""$installDir""",
        "-DCMAKE_INSTALL_BINDIR=bin",
        "-DCMAKE_INSTALL_LIBDIR=lib",
        "-DBUILD_SHARED_LIBS=ON",
        "-DBUILD_EXAMPLES=OFF",
        "-DBUILD_TESTS=OFF",
        "-DBUILD_PERF_TESTS=OFF",
        "-DWITH_QT=OFF",
        "-DWITH_OPENGL=ON",
        "-DWITH_FFMPEG=ON",
        "-DOPENCV_GENERATE_PKGCONFIG=ON",
        "-DOPENCV_ENABLE_ALLOCATOR_STATS=OFF",
        "-DWITH_MSMF=OFF",
        "-DWITH_OBSENSOR=OFF",
        "-DCMAKE_MAKE_PROGRAM=""$env:CMAKE_MAKE_PROGRAM""",
        $opencvSource
    )

    $cmakeProcess = Start-Process cmake -ArgumentList $cmakeArgs -NoNewWindow -Wait -PassThru
    if ($cmakeProcess.ExitCode -ne 0) {
        Start-Rollback "CMake configuration failed"
    }

    # Build OpenCV
    Write-Log "Building OpenCV..."
    $buildResult = Start-Process mingw32-make -ArgumentList "-j4" -NoNewWindow -Wait -PassThru
    if ($buildResult.ExitCode -ne 0) {
        Start-Rollback "Build failed"
    }

    # Install OpenCV
    Write-Log "Installing OpenCV..."
    $installResult = Start-Process mingw32-make -ArgumentList "install" -NoNewWindow -Wait -PassThru
    if ($installResult.ExitCode -ne 0) {
        Start-Rollback "Installation failed"
    }

    # Configure environment variables and paths
    if (-not (Update-OpenCVEnvironment -installPath $installDir -opencvVersion $opencvVersion)) {
        Write-Log "WARNING: Environment configuration failed, but build was successful"
        Write-Log "Please configure environment variables manually if needed"
    }

    Write-Log "Build completed successfully"
    Write-Log "OpenCV installation directory: $installDir"
    Write-Log "To verify the installation, run the test batch file: $(Join-Path $installDir 'opencv_env_test.bat')"
    Write-Log "Remember to restart your development environment or system for changes to take effect"
}
catch {
    Start-Rollback $_.Exception.Message
}
finally {
    Set-Location $scriptPath
    Write-Log "Script execution completed"
}
