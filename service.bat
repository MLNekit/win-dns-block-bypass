@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: ========================================================
:: win-dns-block-bypass
:: ========================================================

if "%~1"=="admin" (
    call :check_command chcp
    call :check_command findstr
    call :check_command sc
    call :check_command ipconfig
    call :check_command powershell

    cd /d "%~dp0"
    echo Started with admin rights
) else (
    call :check_extracted
    call :check_command powershell

    echo Requesting admin rights...
    powershell -NoProfile -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs"
    exit /b
)

set "VERSION=1.0.2"
set "AGH_DIR=%~dp0src"
set "AGH_EXE=%~dp0src\AdGuardHome.exe"
set "AGH_YAML=%~dp0src\AdGuardHome.yaml"
title DNS-Block-Bypass v%VERSION%
mode con cols=92 lines=45 >nul 2>&1
color 0B

:menu
cls
set "SVC_STATUS=НЕ УСТАНОВЛЕНА"
set "SVC_ICON=[ ]"
sc query "AdGuardHome" >nul 2>&1
if errorlevel 1 goto menu_dns_status
sc query "AdGuardHome" | findstr /I "RUNNING" >nul 2>&1
if errorlevel 1 (set "SVC_STATUS=ОСТАНОВЛЕНА"&set "SVC_ICON=[!]" ) else (set "SVC_STATUS=РАБОТАЕТ"&set "SVC_ICON=[+]" )

:menu_dns_status
set "DNS_PORT_STATUS=НЕДОСТУПЕН"
set "DNS_ICON=[ ]"
powershell -NoProfile -Command "$x=Get-NetTCPConnection -LocalPort 53 -State Listen -ErrorAction SilentlyContinue; if($x){exit 0}else{exit 1}" >nul 2>&1
if not errorlevel 1 set "DNS_PORT_STATUS=АКТИВЕН • TCP 53"&set "DNS_ICON=[+]"

echo.
echo   ╔════════════════════════════════════════════════════════════════════════════╗
echo   ║                          DNS-Block-Bypass                                  ║
echo   ║                              v%VERSION%                                        ║
echo   ╚════════════════════════════════════════════════════════════════════════════╝
echo.
echo   ┌─ СОСТОЯНИЕ ────────────────────────────────────────────────────────────────┐
echo   │  %SVC_ICON% Служба : %SVC_STATUS%   %DNS_ICON% DNS : %DNS_PORT_STATUS% │
powershell -NoProfile -Command "$p=$env:AGH_YAML; $addr=''; $sec=''; if(Test-Path -LiteralPath $p){foreach($l in Get-Content -LiteralPath $p){if($l -match '^http:\s*$'){$sec='http';continue}; if($l -match '^tls:\s*$'){$sec='';continue}; if($l -match '^\S' -and $l -notmatch '^http:\s*$'){$sec=''}; if($sec -eq 'http' -and $l -match '^\s{2}address:\s*(.+)$'){$addr=$matches[1].Trim().Trim([char]34);break}}}; if($addr){$port=($addr -replace '.*:', ''); Write-Host ('   │  [i] Веб-панель: http://127.0.0.1:'+$port+' ') -ForegroundColor Cyan} else { if(Test-Path -LiteralPath $p){Write-Host '   │  [i] Веб-панель: порт читается из AdGuardHome.yaml' -ForegroundColor DarkGray} else {Write-Host '   │  [i] Веб-панель: http://127.0.0.1:3000/install.html (Мастер настройки) ' -ForegroundColor Yellow} }"
echo   └────────────────────────────────────────────────────────────────────────────┘
echo.
echo   ┌─ DNS 127.0.0.1 ────────────────────────────────────────────────────────────┐
powershell -NoProfile -Command "$a=@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | Sort-Object InterfaceIndex); $found=0; foreach($x in $a){$d=(Get-DnsClientServerAddress -InterfaceIndex $x.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses; if($d -contains '127.0.0.1'){Write-Host ('   │  [+] '+$x.InterfaceAlias) -ForegroundColor Green; $found++}}; if($found -eq 0){Write-Host '   │  [ ] Нет адаптеров с DNS 127.0.0.1' -ForegroundColor DarkGray}"
echo   └────────────────────────────────────────────────────────────────────────────┘
echo.
echo   ┌─ СЛУЖБА ───────────────────────────────────────────────────────────────────┐
echo   │  [1]  Установить + настроить DNS                                           │
echo   │  [2]  Удалить + вернуть DNS в DHCP                                         │
echo   │  [3]  Запустить службу                                                     │
echo   │  [4]  Остановить службу                                                    │
echo   │  [5]  Перезапустить службу                                                 │
echo   └────────────────────────────────────────────────────────────────────────────┘
echo.
echo   ┌─ DNS ──────────────────────────────────────────────────────────────────────┐
echo   │  [6]  Выбрать адаптеры → 127.0.0.1                                         │
echo   │  [7]  Сбросить выбранные адаптеры → DHCP                                   │
echo   └────────────────────────────────────────────────────────────────────────────┘
echo.
echo   ┌─ ИНСТРУМЕНТЫ ──────────────────────────────────────────────────────────────┐
echo   │  [8]  Открыть веб-панель                                                   │
echo   │  [9]  Очистить DNS-кэш Windows                                             │
echo   │  [10] Тестирование резолва youtube.com                                     │
echo   └────────────────────────────────────────────────────────────────────────────┘
echo.
echo                           [0] Выход

echo   ─────────────────────────────────────────────────────────────────────────────
set "MENU_CHOICE="
set /p "MENU_CHOICE=   Ваш выбор [0-10]: "
if "%MENU_CHOICE%"=="1" goto service_install
if "%MENU_CHOICE%"=="2" goto service_remove
if "%MENU_CHOICE%"=="3" goto service_start
if "%MENU_CHOICE%"=="4" goto service_stop
if "%MENU_CHOICE%"=="5" goto service_restart
if "%MENU_CHOICE%"=="6" goto dns_set
if "%MENU_CHOICE%"=="7" goto dns_reset
if "%MENU_CHOICE%"=="8" goto open_web
if "%MENU_CHOICE%"=="9" goto flush_dns
if "%MENU_CHOICE%"=="10" goto test_youtube
if "%MENU_CHOICE%"=="0" exit /b
goto menu

:action_header
cls
echo.
echo   ╔══════════════════════════════════════════════════════════════════════════════╗
echo   ║  %~1
echo   ╚══════════════════════════════════════════════════════════════════════════════╝
echo   %~2
echo.
exit /b

:: ========================================================
:: УСТАНОВКА СЛУЖБЫ + ПЕРВИЧНАЯ НАСТРОЙКА + ВЫБОР DNS
:: ========================================================
:service_install
call :action_header "УСТАНОВКА ADGUARD HOME" "Служба будет установлена, запущена, затем выберем DNS."
if not exist "%AGH_EXE%" goto install_no_exe

sc query "AdGuardHome" >nul 2>&1
if not errorlevel 1 goto install_start

echo   [1/3] Установка службы...
"%AGH_EXE%" -w "%AGH_DIR%" -c "%AGH_YAML%" -s install
if errorlevel 1 (
    echo   [X] Ошибка установки службы.
    echo.
    pause
    goto menu
)

:install_start
echo.
echo   [2/3] Запуск службы...
"%AGH_EXE%" -w "%AGH_DIR%" -c "%AGH_YAML%" -s start
powershell -NoProfile -Command "Start-Sleep -Seconds 2"
sc query "AdGuardHome" | findstr /I "RUNNING" >nul 2>&1
if errorlevel 1 (
    echo   [X] Служба не перешла в состояние RUNNING.
    echo     DNS 127.0.0.1 устанавливать не будем.
    echo.
    pause
    goto menu
)

if not exist "%AGH_YAML%" goto install_first_time
goto install_step_3

:install_first_time
echo.
echo   [!] Обнаружена первая установка (AdGuardHome.yaml не найден).
echo   [+] Автоматическое открытие мастера настройки в браузере...
start http://127.0.0.1:3000/install.html
echo.

:wait_yaml_step
echo   Пройдите настройку в браузере, затем нажмите Enter...
pause >nul

if exist "%AGH_YAML%" goto wait_yaml_ok

echo.
echo   [X] Файл AdGuardHome.yaml отсутствует!
echo       Возможно, настройка еще не завершена, или возникли другие проблемы.
echo.
goto wait_yaml_step

:wait_yaml_ok
echo.
echo   [OK] Настройка завершена, файл AdGuardHome.yaml обнаружен!
echo.

:install_step_3
echo   [3/3] Выберите адаптеры для DNS 127.0.0.1.
goto dns_set

:install_no_exe
echo   [X] src\AdGuardHome.exe не найден.
echo.
pause
goto menu

:: ========================================================
:: УДАЛЕНИЕ СЛУЖБЫ + ВОЗВРАТ DNS В DHCP
:: ========================================================
:service_remove
call :action_header "УДАЛЕНИЕ ADGUARD HOME" "DNS для 127.0.0.1 будет возвращён в автоматический режим."

echo [1/3] Возврат DNS в автоматический режим...
powershell -NoProfile -Command "$a=@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | Sort-Object InterfaceIndex | Where-Object {$d=(Get-DnsClientServerAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses; $d -contains '127.0.0.1'}); if($a.Count -eq 0){Write-Host '    [i] Активных адаптеров с DNS 127.0.0.1 не найдено.' -ForegroundColor Yellow}else{foreach($x in $a){try{Set-DnsClientServerAddress -InterfaceIndex $x.ifIndex -ResetServerAddresses -ErrorAction Stop; Write-Host ('    [+] DHCP DNS: '+$x.InterfaceAlias) -ForegroundColor Green}catch{Write-Host ('    [-] Не удалось сбросить DNS: '+$x.InterfaceAlias) -ForegroundColor Red}}}"

echo.
echo [!] Очистка кэша DNS Windows...
ipconfig /flushdns >nul 2>&1
echo   [+] Кэш DNS сброшен.

echo.
echo [2/3] Остановка службы...
if exist "%AGH_EXE%" "%AGH_EXE%" -w "%AGH_DIR%" -c "%AGH_YAML%" -s stop >nul 2>&1
powershell -NoProfile -Command "Start-Sleep -Seconds 1"

echo [3/3] Удаление службы...
if exist "%AGH_EXE%" "%AGH_EXE%" -w "%AGH_DIR%" -c "%AGH_YAML%" -s uninstall
if errorlevel 1 echo   [X] Команда удаления службы завершилась с ошибкой.
if not errorlevel 1 echo   [OK] Служба AdGuard Home удалена.
echo.
pause
goto menu

:: ========================================================
:: START / STOP / RESTART
:: ========================================================
:service_start
cls
echo   [!] Запуск службы AdGuard Home...
echo.
if not exist "%AGH_EXE%" goto action_no_exe
"%AGH_EXE%" -w "%AGH_DIR%" -c "%AGH_YAML%" -s start
echo.
pause
goto menu

:service_stop
cls
echo   [!] Остановка службы AdGuard Home...
echo.
if not exist "%AGH_EXE%" goto action_no_exe
"%AGH_EXE%" -w "%AGH_DIR%" -c "%AGH_YAML%" -s stop
echo.
pause
goto menu

:service_restart
cls
echo   [!] Перезапуск службы AdGuard Home...
echo.
if not exist "%AGH_EXE%" goto action_no_exe
"%AGH_EXE%" -w "%AGH_DIR%" -c "%AGH_YAML%" -s restart
echo.
pause
goto menu

:action_no_exe
echo   [X] src\AdGuardHome.exe не найден.
echo.
pause
goto menu

:: ========================================================
:: ВЫБОР АДАПТЕРОВ ДЛЯ DNS 127.0.0.1
:: ========================================================
:dns_set
call :action_header "НАСТРОЙКА DNS" "Выберите адаптеры, на которых AdGuard Home будет принимать DNS."
echo  Только стандартные Wi-Fi и Ethernet отмечаются как рекомендуемые.
echo  Виртуальные VPN/TAP/Radmin и прочие адаптеры - без рекомендации.
echo.

powershell -NoProfile -Command "$a=@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | Sort-Object InterfaceIndex); if($a.Count -eq 0){Write-Host '  [Нет активных сетевых адаптеров]' -ForegroundColor Yellow; exit 0}; $i=1; foreach($x in $a){$rec=($x.InterfaceAlias -eq 'Wi-Fi' -or $x.InterfaceAlias -eq 'Ethernet' -or $x.Name -eq 'Wi-Fi' -or $x.Name -eq 'Ethernet'); $tag=if($rec){' [РЕКОМЕНДУЕТСЯ]'}else{''}; $d=(Get-DnsClientServerAddress -InterfaceIndex $x.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses; $dns=if($d){$d -join ', '}else{'автоматически'}; Write-Host (' {0}. {1} (Статус: {2}; DNS: {3}){4}' -f $i,$x.InterfaceAlias,$x.Status,$dns,$tag); $i++}"

echo.
echo  Введите номер адаптера. Для нескольких: 2,3
echo  0 - отмена
echo.
set "DNS_SELECTION="
set /p "DNS_SELECTION=Введите номер(а) адаптера: "
if not defined DNS_SELECTION goto dns_set
if "%DNS_SELECTION%"=="0" goto menu

powershell -NoProfile -Command "$raw=$env:DNS_SELECTION; $a=@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | Sort-Object InterfaceIndex); if($a.Count -eq 0){Write-Host '[-] Нет активных сетевых адаптеров.' -ForegroundColor Red; exit 2}; $nums=$raw -split '[,; ]+' | Where-Object {$_}; $sel=@(); foreach($n in $nums){$v=0; if(-not [int]::TryParse($n,[ref]$v)){Write-Host ('[-] Неверный номер: '+$n) -ForegroundColor Red; exit 3}; if($v -lt 1 -or $v -gt $a.Count){Write-Host ('[-] Неверный номер: '+$n) -ForegroundColor Red; exit 3}; $sel += $a[$v-1]}; $sel=$sel | Sort-Object InterfaceIndex -Unique; foreach($x in $sel){try{Set-DnsClientServerAddress -InterfaceIndex $x.ifIndex -ServerAddresses '127.0.0.1' -ErrorAction Stop; Write-Host ('[+] DNS 127.0.0.1 установлен: '+$x.InterfaceAlias) -ForegroundColor Green}catch{Write-Host ('[-] Не удалось установить DNS: '+$x.InterfaceAlias) -ForegroundColor Red; exit 4}}"
if errorlevel 1 goto dns_set_failed

echo.
echo   [!] Очистка кэша DNS Windows...
ipconfig /flushdns >nul 2>&1
echo   [+] Кэш DNS сброшен.
echo.
echo   [OK] DNS настроен.
echo.
pause
goto menu

:dns_set_failed
echo.
echo   [X] Не удалось применить DNS.
echo.
pause
goto menu

:: ========================================================
:: СБРОС DNS В DHCP
:: ========================================================
:dns_reset
call :action_header "СБРОС DNS → DHCP" "Выберите адаптеры для возврата автоматических DNS."

powershell -NoProfile -Command "$a=@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | Sort-Object InterfaceIndex | Where-Object {$d=(Get-DnsClientServerAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses; $d -contains '127.0.0.1'}); if($a.Count -eq 0){Write-Host '  [Нет активных адаптеров с DNS 127.0.0.1]' -ForegroundColor Yellow; exit 0}; $i=1; foreach($x in $a){Write-Host (' {0}. {1}' -f $i,$x.InterfaceAlias); $i++}"

echo.
echo  Можно выбрать несколько: например 1,2
echo  A = все найденные; 0 = отмена
echo.
set "RESET_SELECTION="
set /p "RESET_SELECTION=Введите выбор: "
if not defined RESET_SELECTION goto dns_reset
if /I "%RESET_SELECTION%"=="A" goto dns_reset_all
if "%RESET_SELECTION%"=="0" goto menu

powershell -NoProfile -Command "$raw=$env:RESET_SELECTION; $a=@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | Sort-Object InterfaceIndex | Where-Object {$d=(Get-DnsClientServerAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses; $d -contains '127.0.0.1'}); if($a.Count -eq 0){Write-Host '[-] Нет адаптеров с DNS 127.0.0.1.' -ForegroundColor Yellow; exit 2}; $nums=$raw -split '[,; ]+' | Where-Object {$_}; $sel=@(); foreach($n in $nums){$v=0; if(-not [int]::TryParse($n,[ref]$v)){Write-Host ('[-] Неверный номер: '+$n) -ForegroundColor Red; exit 3}; if($v -lt 1 -or $v -gt $a.Count){Write-Host ('[-] Неверный номер: '+$n) -ForegroundColor Red; exit 3}; $sel += $a[$v-1]}; $sel=$sel | Sort-Object InterfaceIndex -Unique; foreach($x in $sel){try{Set-DnsClientServerAddress -InterfaceIndex $x.ifIndex -ResetServerAddresses -ErrorAction Stop; Write-Host ('[+] DNS сброшен в DHCP: '+$x.InterfaceAlias) -ForegroundColor Green}catch{Write-Host ('[-] Не удалось сбросить DNS: '+$x.InterfaceAlias) -ForegroundColor Red; exit 4}}"
if errorlevel 1 goto dns_reset_failed

echo.
echo   [!] Очистка кэша DNS Windows...
ipconfig /flushdns >nul 2>&1
echo   [+] Кэш DNS сброшен.
echo.
echo   [OK] DNS сброшен в автоматический режим.
echo.
pause
goto menu

:dns_reset_all
powershell -NoProfile -Command "$a=@(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | Sort-Object InterfaceIndex | Where-Object {$d=(Get-DnsClientServerAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses; $d -contains '127.0.0.1'}); foreach($x in $a){try{Set-DnsClientServerAddress -InterfaceIndex $x.ifIndex -ResetServerAddresses -ErrorAction Stop; Write-Host ('[+] DNS сброшен в DHCP: '+$x.InterfaceAlias) -ForegroundColor Green}catch{Write-Host ('[-] Не удалось сбросить DNS: '+$x.InterfaceAlias) -ForegroundColor Red}}"

echo.
echo   [!] Очистка кэша DNS Windows...
ipconfig /flushdns >nul 2>&1
echo   [+] Кэш DNS сброшен.
echo.
echo   [OK] DNS сброшен в автоматический режим.
echo.
pause
goto menu

:dns_reset_failed
echo.
echo   [X] Не удалось выполнить сброс DNS.
echo.
pause
goto menu

:: ========================================================
:: WEB DASHBOARD - ПОРТ ИЗ AdGuardHome.yaml (ИЛИ 3000/install.html ЕСЛИ ЕЩЕ НЕТ)
:: ========================================================
:open_web
call :action_header "ВЕБ-ПАНЕЛЬ ADGUARD HOME" "Адрес и порт читаются из AdGuardHome.yaml."

if not exist "%AGH_YAML%" (
    echo   [!] AdGuardHome.yaml еще не создан.
    echo   [+] Запуск мастера первичной настройки: http://127.0.0.1:3000/install.html
    start http://127.0.0.1:3000/install.html
    echo.
    pause
    goto menu
)

powershell -NoProfile -Command "$p=$env:AGH_YAML; $section=''; $httpAddr=''; $tlsEnabled=$false; $forceHttps=$false; $httpsPort=443; foreach($l in Get-Content -LiteralPath $p){if($l -match '^http:\s*$'){$section='http'; continue}; if($l -match '^tls:\s*$'){$section='tls'; continue}; if($l -match '^\S' -and $l -notmatch '^(http|tls):\s*$'){$section=''}; if($section -eq 'http' -and $l -match '^\s{2}address:\s*(.+)$'){$httpAddr=$matches[1].Trim().Trim([char]34)}}; $section=''; foreach($l in Get-Content -LiteralPath $p){if($l -match '^tls:\s*$'){$section='tls'; continue}; if($l -match '^\S' -and $l -notmatch '^tls:\s*$'){$section=''}; if($section -eq 'tls' -and $l -match '^\s{2}enabled:\s*(true|false)\s*$'){$tlsEnabled=($matches[1] -eq 'true')}; if($section -eq 'tls' -and $l -match '^\s{2}force_https:\s*(true|false)\s*$'){$forceHttps=($matches[1] -eq 'true')}; if($section -eq 'tls' -and $l -match '^\s{2}port_https:\s*(\d+)\s*$'){$httpsPort=[int]$matches[1]}}; if($tlsEnabled -and $forceHttps){$url='https://127.0.0.1:'+$httpsPort}else{if($httpAddr -match '^(\[.*\]|[^:]+)?:?(\d+)\s*$'){$port=$matches[2]; $url='http://127.0.0.1:'+$port}else{$url=''}}; if([string]::IsNullOrWhiteSpace($url)){Write-Host '[-] Не удалось определить веб-порт из AdGuardHome.yaml.' -ForegroundColor Red; exit 2}; Write-Host ('[+] URL: '+$url) -ForegroundColor Green; Start-Process $url"

echo.
pause
goto menu

:: ========================================================
:: FLUSH DNS
:: ========================================================
:flush_dns
cls
echo   [!] Очистка кэша DNS Windows...
echo.
ipconfig /flushdns
echo.
pause
goto menu

:: ========================================================
:: ТЕСТИРОВАНИЕ РЕЗОЛВА YOUTUBE.COM
:: ========================================================
:test_youtube
call :action_header "ТЕСТИРОВАНИЕ РЕЗОЛВА YOUTUBE.COM" "Проверка разрешения домена через системный DNS и напрямую через AdGuard Home."

powershell -NoProfile -Command "$domain='youtube.com'; Write-Host '[1/2] Запрос к системному DNS Windows...' -ForegroundColor Cyan; try { $r = Resolve-DnsName -Name $domain -ErrorAction Stop; Write-Host '[+] Системный DNS успешно вернул ответы:' -ForegroundColor Green; $r | Where-Object {$_.IPAddress} | Select-Object @{N='Domain';E={$_.Name}}, @{N='Type';E={$_.Type}}, @{N='IP Address';E={$_.IPAddress}} | Format-Table -AutoSize } catch { Write-Host ('[-] Ошибка системного DNS: ' + $_.Exception.Message) -ForegroundColor Red }; Write-Host ''; Write-Host '[2/2] Прямой запрос к AdGuard Home (127.0.0.1:53)...' -ForegroundColor Cyan; try { $rL = Resolve-DnsName -Name $domain -Server '127.0.0.1' -QuickTimeout -ErrorAction Stop; Write-Host '[+] AdGuard Home (127.0.0.1) успешно вернул ответы:' -ForegroundColor Green; $rL | Where-Object {$_.IPAddress} | Select-Object @{N='Domain';E={$_.Name}}, @{N='Type';E={$_.Type}}, @{N='IP Address';E={$_.IPAddress}} | Format-Table -AutoSize } catch { Write-Host ('[-] Ошибка запроса к 127.0.0.1: ' + $_.Exception.Message) -ForegroundColor Red }"

echo.
pause
goto menu

:: ========================================================
:: ВСПОМОГАТЕЛЬНЫЕ ПРОВЕРКИ
:: ========================================================
:check_command
where %1 >nul 2>&1
if %errorLevel% neq 0 (
    echo [ОШИБКА] Команда %1 не найдена в системной переменной PATH.
    pause
    exit /b 1
)
exit /b 0

:check_extracted
if not exist "%~dp0src\" (
    echo [ОШИБКА] Папка "src" не найдена!
    echo Распакуйте архив полностью перед запуском файла.
    pause
    exit /b 1
)
exit /b 0
