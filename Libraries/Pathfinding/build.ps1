param(
    [string]$Out = "$PSScriptRoot\Pathfinding.lua",
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Source = Join-Path $PSScriptRoot "src"
$Files = Get-ChildItem $Source -Filter *.lua | Sort-Object Name

$Builder = New-Object System.Text.StringBuilder
[void]$Builder.Append("--!nocheck`n--!nolint UnknownGlobal, DeprecatedGlobal, BuiltinGlobalWrite`n--!optimize 2`n")
[void]$Builder.Append("local Modules, Loaded = {}, {}`n")
[void]$Builder.Append("local function Require(Name)`n`tlocal Value = Loaded[Name]`n`tif Value == nil then`n`t`tValue = Modules[Name](Require)`n`t`tLoaded[Name] = Value`n`tend`n`treturn Value`nend`n")

foreach ($File in $Files) {
    $Name = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $Text = [System.IO.File]::ReadAllText($File.FullName).Replace("`r`n", "`n")
    if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) { $Text = $Text.Substring(1) }
    $Lines = $Text.Split("`n") | Where-Object { $_ -notmatch '^--!' }
    [void]$Builder.Append("Modules.$Name = function(Require)`n")
    [void]$Builder.Append((($Lines -join "`n").Trim()) + "`n")
    [void]$Builder.Append("end`n")
}

[void]$Builder.Append("return Require(`"Init`")`n")
$Bundle = $Builder.ToString().Replace("`n", "`r`n")
[System.IO.File]::WriteAllText($Out, $Bundle, $Utf8)
Write-Host "Built $Out ($($Files.Count) modules, $([math]::Round($Bundle.Length / 1024, 1)) KB)"

if ($Deploy) {
    $Workspace = "C:\Users\skibidihook\AppData\Local\Potassium\workspace"
    Copy-Item $Out (Join-Path $Workspace "Pathfinding.lua") -Force
    Write-Host "Copied to $Workspace"
}
