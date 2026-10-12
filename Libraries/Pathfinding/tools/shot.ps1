param([string]$Out = (Join-Path $env:TEMP "roblox_shot.png"))
Add-Type -AssemblyName System.Drawing
if (-not ("FG2" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class FG2 {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, uint f, UIntPtr e);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  public struct RECT { public int L, T, R, B; }
}
"@
}
[void][FG2]::SetProcessDPIAware()
$Proc = Get-Process -Name RobloxPlayerBeta -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
if (-not $Proc) { "no roblox window"; exit }
$H = $Proc.MainWindowHandle
$Prev = [FG2]::GetForegroundWindow()
$WasMin = [FG2]::IsIconic($H)
if ($WasMin) { [void][FG2]::ShowWindow($H, 9) }
[FG2]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
[FG2]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
[void][FG2]::SetForegroundWindow($H)
Start-Sleep -Milliseconds 450
$R = New-Object FG2+RECT
[void][FG2]::GetWindowRect($H, [ref]$R)
$W = [Math]::Max(1, $R.R - $R.L); $Hh = [Math]::Max(1, $R.B - $R.T)
$Bmp = New-Object System.Drawing.Bitmap $W, $Hh
$G = [System.Drawing.Graphics]::FromImage($Bmp)
$G.CopyFromScreen($R.L, $R.T, 0, 0, $Bmp.Size)
if ($WasMin) { [void][FG2]::ShowWindow($H, 6) }
[FG2]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
[FG2]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
[void][FG2]::SetForegroundWindow($Prev)
$Scale = [Math]::Min(1.0, 1280.0 / $W)
$Small = New-Object System.Drawing.Bitmap $Bmp, ([int]($W * $Scale)), ([int]($Hh * $Scale))
$Small.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$G.Dispose(); $Bmp.Dispose(); $Small.Dispose()
"$Out ${W}x${Hh}"
