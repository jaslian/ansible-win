# Function to get formatted timestamp
function Get-FormattedTimestamp {
    return Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
}

# Function to create directory tree
function Get-DirectoryTree {
    param (
        [string]$Path = ".",
        [string]$IndentChar = "    ",
        [int]$Level = 0,
        [int]$MaxLevel = 5
    )

    # Define directories to ignore
    $ignoreDirs = @('.history', '.idea', '.ssh', 'logs')

    # Return if we've reached max level
    if ($Level -gt $MaxLevel) {
        return "$($IndentChar * $Level)├── ..."
    }

    # Get the directory info
    $dir = Get-Item $Path

    # Skip if this is an ignored directory
    if ($Level -gt 0 -and $ignoreDirs -contains $dir.Name) {
        return
    }

    # Create indentation based on level
    $indent = $IndentChar * $Level

    # Output the current directory name
    if ($Level -eq 0) {
        "$($dir.FullName)"
    } else {
        "$indent├── $($dir.Name)"
    }

    # Get all items in the current directory, excluding ignored directories
    $items = Get-ChildItem $Path |
        Where-Object { -not ($_.PSIsContainer -and $ignoreDirs -contains $_.Name) } |
        Sort-Object Name

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            # If item is a directory, recurse into it
            Get-DirectoryTree -Path $item.FullName -IndentChar $IndentChar -Level ($Level + 1) -MaxLevel $MaxLevel
        } else {
            # If item is a file, print it
            "$($indent)$($IndentChar)├── $($item.Name)"
        }
    }
}

# Main execution
try {
    # Get current directory
    $currentPath = Get-Location
    $timestamp = Get-FormattedTimestamp

    # Create logs directory if it doesn't exist
    $logsDir = Join-Path $currentPath "logs"
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir | Out-Null
    }

    # Create log file name with directory name
    $dirName = Split-Path $currentPath -Leaf
    $outputFile = Join-Path $logsDir "directory_tree_${dirName}_$timestamp.log"

    Write-Host "Generating directory tree for: $currentPath"
    Write-Host "Maximum depth level: 5"
    Write-Host "Ignoring directories: .history, .idea, .ssh, logs"
    Write-Host "Saving to: $outputFile"
    Write-Host "`nDirectory Tree:`n"

    # Generate and display tree
    $tree = Get-DirectoryTree -Path $currentPath -MaxLevel 5
    $tree | Tee-Object -FilePath $outputFile

    Write-Host "`nDirectory tree has been saved to: $outputFile"
}
catch {
    Write-Error "Error generating directory tree: $_"
}
