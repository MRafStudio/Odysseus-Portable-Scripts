REM scripts\Settings.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"

REM ============================================================================
REM   PowerShell wrapper (для ESC и чтения, НЕ для записи!)
REM ============================================================================
set "PS_WRAPPER=%TEMP%\ps_wrapper.bat"
(
    echo @echo off
    echo powershell -NoProfile -NonInteractive %%*
) > "%PS_WRAPPER%"

for /f "usebackq" %%a in (`%PS_WRAPPER% -Command "Write-Host ([char]27) -NoNewline"`) do set "ESC=%%a"

REM ============================================================================
REM   Проверка / создание Config.ini
REM ============================================================================
if not exist "%CONFIG_FILE%" (
    echo   %ESC%[1;33mConfig.ini не найден. Создание...%ESC%[0m
    call "%SCRIPTS_DIR%\CreateConfig.bat"
    echo   %ESC%[1;32m  +   Config.ini создан.%ESC%[0m
    timeout /t 1 /nobreak >nul
)

:settings_menu
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                             %ESC%[1;37mOdysseus — Настройки%ESC%[0m                           %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Читаем текущие значения из Config.ini
REM ============================================================================
set "CUR_LLM=ollama"
set "CUR_LLM_API=http://127.0.0.1:11434/v1"
set "CUR_AUTH=true"
set "CUR_PASS=admin"
set "CUR_PORT=7000"
set "CUR_BROWSER=1"
set "CUR_SEARXNG=0"
set "CUR_SEARCH=none"
set "CUR_SEARCH_KEY="

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_BACKEND=" "%CONFIG_FILE%"') do set "CUR_LLM=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_API_URL=" "%CONFIG_FILE%"') do set "CUR_LLM_API=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTH_ENABLED=" "%CONFIG_FILE%"') do set "CUR_AUTH=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"ADMIN_PASSWORD=" "%CONFIG_FILE%"') do set "CUR_PASS=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"APP_PORT=" "%CONFIG_FILE%"') do set "CUR_PORT=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "CUR_BROWSER=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARXNG_ENABLED=" "%CONFIG_FILE%"') do set "CUR_SEARXNG=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API=" "%CONFIG_FILE%"') do set "CUR_SEARCH=%%b"
    for /f "tokens=1,* delims==" %%a in ('findstr /B /C:"SEARCH_API_KEY=" "%CONFIG_FILE%"') do set "SEARCH_API_KEY=%%b"
)

set "CUR_LLM=%CUR_LLM: =%"
set "CUR_LLM_API=%CUR_LLM_API: =%"
set "CUR_AUTH=%CUR_AUTH: =%"
set "CUR_PASS=%CUR_PASS: =%"
set "CUR_PORT=%CUR_PORT: =%"
set "CUR_BROWSER=%CUR_BROWSER: =%"
set "CUR_SEARXNG=%CUR_SEARXNG: =%"
set "CUR_SEARCH=%CUR_SEARCH: =%"
set "CUR_SEARCH_KEY=%CUR_SEARCH_KEY: =%"

REM Дефолты если пусто
if "!CUR_LLM!"=="" set "CUR_LLM=ollama"
if "!CUR_LLM_API!"=="" set "CUR_LLM_API=http://127.0.0.1:11434/v1"
if "!CUR_AUTH!"=="" set "CUR_AUTH=true"
if "!CUR_PASS!"=="" set "CUR_PASS=admin"
if "!CUR_PORT!"=="" set "CUR_PORT=7000"
if "!CUR_BROWSER!"=="" set "CUR_BROWSER=1"
if "!CUR_SEARXNG!"=="" set "CUR_SEARXNG=0"
if "!CUR_SEARCH!"=="" set "CUR_SEARCH=none"
if "!CUR_SEARCH_KEY!"==" =" set "CUR_SEARCH_KEY="
if "!CUR_SEARCH_KEY!"=="" set "CUR_SEARCH_KEY="

echo   %ESC%[1;33mТекущие настройки:%ESC%[0m
echo     LLM Backend:    %ESC%[1;33m%CUR_LLM%%ESC%[0m
echo     LLM API URL:    %ESC%[1;33m%CUR_LLM_API%%ESC%[0m
echo     Auth:           %ESC%[1;33m%CUR_AUTH%%ESC%[0m
echo     Admin пароль:   %ESC%[1;33m%CUR_PASS%%ESC%[0m
echo     Порт:           %ESC%[1;33m%CUR_PORT%%ESC%[0m
echo     Auto-browser:   %ESC%[1;33m%CUR_BROWSER%%ESC%[0m
echo     SearXNG:        %ESC%[1;33m%CUR_SEARXNG%%ESC%[0m
echo     Search API:     %ESC%[1;33m%CUR_SEARCH%%ESC%[0m
if "!CUR_SEARCH_KEY!"=="" (
    echo     Search API Key: %ESC%[1;30m^(не задан^)%ESC%[0m
) else (
    echo     Search API Key: %ESC%[1;33m%CUR_SEARCH_KEY%%ESC%[0m
)
echo.

echo   %ESC%[1;37m[1]%ESC%[0m LLM Backend
echo   %ESC%[1;37m[2]%ESC%[0m LLM API URL
echo   %ESC%[1;37m[3]%ESC%[0m Auth (вкл/выкл)
echo   %ESC%[1;37m[4]%ESC%[0m Admin пароль
echo   %ESC%[1;37m[5]%ESC%[0m Порт приложения
echo   %ESC%[1;37m[6]%ESC%[0m Auto-open browser
echo   %ESC%[1;37m[7]%ESC%[0m Web Search API
echo.
echo   %ESC%[1;37m[0]%ESC%[0m Назад в главное меню
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите параметр (0-7): %ESC%[0m"
set "choice=%choice: =%"

if "%choice%"=="0" exit /b 0
if "%choice%"=="1" goto set_llm
if "%choice%"=="2" goto set_llm_api
if "%choice%"=="3" goto set_auth
if "%choice%"=="4" goto set_pass
if "%choice%"=="5" goto set_port
if "%choice%"=="6" goto set_browser
if "%choice%"=="7" goto set_search

goto settings_menu

REM ============================================================================
REM   set_llm — изменяем backend и URL
REM ============================================================================
:set_llm
cls
echo.
echo   %ESC%[1;33mLLM Backend:%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m Ollama (локальная, порт 11434)
echo   %ESC%[1;37m[2]%ESC%[0m LM Studio (порт 1234)
echo   %ESC%[1;37m[3]%ESC%[0m KoboldCPP (OpenAI-compatible, порт 5001)
echo   %ESC%[1;37m[4]%ESC%[0m OpenAI API (облачный)
echo   %ESC%[1;37m[5]%ESC%[0m Другой (custom URL)
echo.

set "llm_choice="
set /p "llm_choice=%ESC%[33mВыберите (1-5): %ESC%[0m"
set "llm_choice=%llm_choice: =%"

if "%llm_choice%"=="1" (
    set "NEW_LLM=ollama"
    set "NEW_LLM_API=http://127.0.0.1:11434/v1"
    goto save_llm
)
if "%llm_choice%"=="2" (
    set "NEW_LLM=lmstudio"
    set "NEW_LLM_API=http://127.0.0.1:1234/v1"
    goto save_llm
)
if "%llm_choice%"=="3" (
    set "NEW_LLM=koboldcpp"
    set "NEW_LLM_API=http://127.0.0.1:5001/v1"
    goto save_llm
)
if "%llm_choice%"=="4" (
    set "NEW_LLM=openai"
    set /p "NEW_LLM_API=%ESC%[33mВведите OpenAI API URL (или Enter для https://api.openai.com/v1): %ESC%[0m"
    if "!NEW_LLM_API!"=="" set "NEW_LLM_API=https://api.openai.com/v1"
    set /p "OPENAI_KEY=%ESC%[33mВведите OpenAI API Key: %ESC%[0m"
    goto save_llm
)
if "%llm_choice%"=="5" (
    set "NEW_LLM=custom"
    set /p "NEW_LLM_API=%ESC%[33mВведите URL endpoint (например http://192.168.1.100:8000/v1): %ESC%[0m"
    goto save_llm
)

echo   %ESC%[1;33mОтменено.%ESC%[0m
timeout /t 1 /nobreak >nul
goto settings_menu

:save_llm
if not defined NEW_LLM goto settings_menu

echo %SCRIPTS_DIR%
pause

call "%SCRIPTS_DIR%\CreateConfig.bat" "!NEW_LLM!" "!NEW_LLM_API!" "!CUR_AUTH!" "!CUR_PASS!" "!CUR_PORT!" "!CUR_BROWSER!" "!CUR_SEARXNG!" "!CUR_SEARCH!" "!CUR_SEARCH_KEY!"

echo   %ESC%[1;32m  +   LLM Backend обновлён: !NEW_LLM! (!NEW_LLM_API!)%ESC%[0m

timeout /t 2 /nobreak >nul
goto settings_menu

REM ============================================================================
REM   set_llm_api — изменяем только URL
REM ============================================================================
:set_llm_api
cls
echo.
set /p "NEW_LLM_API=%ESC%[33mВведите LLM API URL (например http://127.0.0.1:11434/v1): %ESC%[0m"
set "NEW_LLM_API=%NEW_LLM_API: =%"
if "!NEW_LLM_API!"=="" goto settings_menu

call "%SCRIPTS_DIR%\CreateConfig.bat" "!CUR_LLM!" "!NEW_LLM_API!" "!CUR_AUTH!" "!CUR_PASS!" "!CUR_PORT!" "!CUR_BROWSER!" "!CUR_SEARXNG!" "!CUR_SEARCH!" "!CUR_SEARCH_KEY!"

echo   %ESC%[1;32m  +   LLM API URL обновлён: !NEW_LLM_API!%ESC%[0m

timeout /t 2 /nobreak >nul
goto settings_menu

REM ============================================================================
REM   set_auth — вкл/выкл авторизацию
REM ============================================================================
:set_auth
cls
echo.
if /I "%CUR_AUTH%"=="true" (
    echo   %ESC%[1;33mAuth сейчас: ВКЛЮЧЕН%ESC%[0m
    echo   %ESC%[1;37m[1]%ESC%[0m Выключить (небезопасно!)
) else (
    echo   %ESC%[1;33mAuth сейчас: ВЫКЛЮЧЕН%ESC%[0m
    echo   %ESC%[1;37m[1]%ESC%[0m Включить
)
echo   %ESC%[1;37m[0]%ESC%[0m Отмена
echo.
set "auth_choice="
set /p "auth_choice=%ESC%[33mВыберите: %ESC%[0m"

if "%auth_choice%"=="1" (
    if /I "%CUR_AUTH%"=="true" (
        set "NEW_AUTH=false"
    ) else (
        set "NEW_AUTH=true"
    )
    
    call "%SCRIPTS_DIR%\CreateConfig.bat" "!CUR_LLM!" "!CUR_LLM_API!" "!NEW_AUTH!" "!CUR_PASS!" "!CUR_PORT!" "!CUR_BROWSER!" "!CUR_SEARXNG!" "!CUR_SEARCH!" "!CUR_SEARCH_KEY!"
    
    echo   %ESC%[1;32m  +   Auth: !NEW_AUTH!%ESC%[0m
) else (
    echo   %ESC%[1;33mОтменено.%ESC%[0m
)
timeout /t 2 /nobreak >nul
goto settings_menu

REM ============================================================================
REM   set_pass — изменить пароль админа
REM ============================================================================
:set_pass
cls
echo.
set /p "NEW_PASS=%ESC%[33mВведите новый admin пароль: %ESC%[0m"
if "!NEW_PASS!"=="" goto settings_menu

call "%SCRIPTS_DIR%\CreateConfig.bat" "!CUR_LLM!" "!CUR_LLM_API!" "!CUR_AUTH!" "!NEW_PASS!" "!CUR_PORT!" "!CUR_BROWSER!" "!CUR_SEARXNG!" "!CUR_SEARCH!" "!CUR_SEARCH_KEY!"

echo   %ESC%[1;32m  +   Admin пароль обновлён%ESC%[0m

timeout /t 2 /nobreak >nul
goto settings_menu

REM ============================================================================
REM   set_port — изменить порт приложения
REM ============================================================================
:set_port
cls
echo.
set /p "NEW_PORT=%ESC%[33mВведите порт (текущий: %CUR_PORT%): %ESC%[0m"
set "NEW_PORT=%NEW_PORT: =%"
if "!NEW_PORT!"=="" goto settings_menu

call "%SCRIPTS_DIR%\CreateConfig.bat" "!CUR_LLM!" "!CUR_LLM_API!" "!CUR_AUTH!" "!CUR_PASS!" "!NEW_PORT!" "!CUR_BROWSER!" "!CUR_SEARXNG!" "!CUR_SEARCH!" "!CUR_SEARCH_KEY!"

echo   %ESC%[1;32m  +   Порт обновлён: !NEW_PORT!%ESC%[0m

timeout /t 2 /nobreak >nul
goto settings_menu

REM ============================================================================
REM   set_browser — вкл/выкл авто-открытие браузера
REM ============================================================================
:set_browser
cls
echo.
if "%CUR_BROWSER%"=="1" (
    echo   %ESC%[1;33mAuto-browser сейчас: ВКЛЮЧЕН%ESC%[0m
    echo   %ESC%[1;37m[1]%ESC%[0m Выключить
) else (
    echo   %ESC%[1;33mAuto-browser сейчас: ВЫКЛЮЧЕН%ESC%[0m
    echo   %ESC%[1;37m[1]%ESC%[0m Включить
)
echo   %ESC%[1;37m[0]%ESC%[0m Отмена
echo.
set "br_choice="
set /p "br_choice=%ESC%[33mВыберите: %ESC%[0m"

if "%br_choice%"=="1" (
    if "%CUR_BROWSER%"=="1" (
        set "NEW_BR=0"
    ) else (
        set "NEW_BR=1"
    )
    
    call "%SCRIPTS_DIR%\CreateConfig.bat" "!CUR_LLM!" "!CUR_LLM_API!" "!CUR_AUTH!" "!CUR_PASS!" "!CUR_PORT!" "!NEW_BR!" "!CUR_SEARXNG!" "!CUR_SEARCH!" "!CUR_SEARCH_KEY!"
    
    echo   %ESC%[1;32m  +   Auto-browser: !NEW_BR!%ESC%[0m
) else (
    echo   %ESC%[1;33mОтменено.%ESC%[0m
)
timeout /t 2 /nobreak >nul
goto settings_menu

REM ============================================================================
REM   set_search — настройка поискового API
REM ============================================================================
:set_search
cls
echo.
echo   %ESC%[1;33mWeb Search API:%ESC%[0m
echo   %ESC%[1;37m[1]%ESC%[0m Нет (none)
echo   %ESC%[1;37m[2]%ESC%[0m Brave Search API
echo   %ESC%[1;37m[3]%ESC%[0m Tavily API
echo   %ESC%[1;37m[4]%ESC%[0m Serper (Google)
echo   %ESC%[1;37m[5]%ESC%[0m Google Custom Search
echo.
set "search_choice="
set /p "search_choice=%ESC%[33mВыберите (1-5): %ESC%[0m"
set "search_choice=%search_choice: =%"

set "NEW_SEARCH="
set "NEW_KEY="

if "%search_choice%"=="1" set "NEW_SEARCH=none" & set "NEW_KEY=" & goto save_search
if "%search_choice%"=="2" set "NEW_SEARCH=brave" & set /p "NEW_KEY=%ESC%[33mBrave API Key: %ESC%[0m" & goto save_search
if "%search_choice%"=="3" set "NEW_SEARCH=tavily" & set /p "NEW_KEY=%ESC%[33mTavily API Key: %ESC%[0m" & goto save_search
if "%search_choice%"=="4" set "NEW_SEARCH=serper" & set /p "NEW_KEY=%ESC%[33mSerper API Key: %ESC%[0m" & goto save_search
if "%search_choice%"=="5" set "NEW_SEARCH=google" & set /p "NEW_KEY=%ESC%[33mGoogle API Key: %ESC%[0m" & goto save_search

echo   %ESC%[1;33mОтменено.%ESC%[0m
timeout /t 1 /nobreak >nul
goto settings_menu

:save_search
if not defined NEW_SEARCH goto settings_menu

call "%SCRIPTS_DIR%\CreateConfig.bat" "!CUR_LLM!" "!CUR_LLM_API!" "!CUR_AUTH!" "!CUR_PASS!" "!CUR_PORT!" "!CUR_BROWSER!" "!CUR_SEARXNG!" "!NEW_SEARCH!" "!NEW_KEY!"

echo   %ESC%[1;32m  +   Search API обновлён: !NEW_SEARCH!%ESC%[0m

timeout /t 2 /nobreak >nul
goto settings_menu