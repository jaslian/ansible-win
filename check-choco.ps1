function CheckChoco {
    try {
        $testchoco = choco -v
        if ((-not($testchoco)) -or ($testchoco.length -gt 10)) {
            throw [System.IO.FileNotFoundException] "Chocolatey not found"
        }
        else {
            Write-Output "Chocolatey Version $testchoco is already installed"
        }
    } catch {
        Write-Error $_.Exception
    }
}

CheckChoco
