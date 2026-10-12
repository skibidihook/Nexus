param([string]$Filter = "*")

$Root = Split-Path $PSScriptRoot -Parent
$Luau = "C:\Users\skibidihook\Downloads\Prometheus-master (1)\Prometheus-master\LuauBinaries\luau.exe"

& (Join-Path $Root "build.ps1")
if (-not $?) { exit 1 }

$Failed = 0
Push-Location $PSScriptRoot
try {
    foreach ($Spec in Get-ChildItem $PSScriptRoot -Filter "$Filter.spec.lua" | Sort-Object Name) {
        & $Luau -O2 $Spec.Name
        if ($LASTEXITCODE -ne 0) {
            $Failed++
            Write-Host "FAILED: $($Spec.Name)" -ForegroundColor Red
        }
    }
}
finally {
    Pop-Location
}

if ($Failed -gt 0) {
    Write-Host "$Failed spec file(s) failed" -ForegroundColor Red
    exit 1
}
Write-Host "All specs passed" -ForegroundColor Green
