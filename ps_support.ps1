Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
function ThrowOnNativeFailure {
    if (-not $?) {
        Pause
        throw 'Native Failure'
    }
}
