@REM Start.bat — Главное меню Odysseus Portable
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title Odysseus Portable — Главное меню
pushd %~dp0

REM ============================================================================
REM Пути (относительно Start.bat)
REM ============================================================================
for %%F in ("%~dp0") do set "ROOT_DIR=%%~fF"
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"
set "REPO_DIR=%ROOT_DIR%\repo"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
set "DATA_DIR=%ROOT_DIR%\data"

REM ============================================================================
REM Изоляция данных (ничего в систему!)
REM ============================================================================
set "TEMP=%DATA_DIR%\temp"
set "TMP=%DATA_DIR%\temp"
set "APPDATA=%DATA_DIR%\appdata"
set "LOCALAPPDATA=%DATA_DIR%\localappdata"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"
set "PYTHONUSERBASE=%DATA_DIR%\python-userbase"
set "PYTHONPATH="
set "PYTHONHOME="
set "PYTHONSTARTUP="
set "PYTHONIOENCODING=utf-8"
set "PIP_NO_CACHE_DIR=1"
set "HF_HOME=%DATA_DIR%\huggingface"
set "HF_HUB_DISABLE_SYMLINKS=1"
set "HF_HUB_DISABLE_SYMLINKS_WARNING=1"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%APPDATA%" mkdir "%APPDATA%" 2>nul
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul
if not exist "%HOME%\Desktop" mkdir "%HOME%\Desktop" 2>nul
if not exist "%PYTHONUSERBASE%" mkdir "%PYTHONUSERBASE%" 2>nul
if not exist "%HF_HOME%" mkdir "%HF_HOME%" 2>nul

REM ============================================================================
REM PowerShell wrapper (изоляция)
REM ============================================================================
set "PS_WRAPPER=%TEMP%\ps_wrapper.bat"
(
 echo @echo off
 echo set "LOCALAPPDATA=%DATA_DIR%\localappdata"
 echo set "APPDATA=%DATA_DIR%\appdata"
 echo set "TEMP=%TEMP%"
 echo set "TMP=%TMP%"
 echo set "HOME=%HOME%"
 echo set "USERPROFILE=%USERPROFILE%"
 echo powershell -NoProfile -NonInteractive %%*
) > "%PS_WRAPPER%"

for /f "usebackq" %%a in (`%PS_WRAPPER% -Command "Write-Host ([char]27) -NoNewline"`) do set "ESC=%%a"

REM ============================================================================
REM Проверка глобального Git (ОБЯЗАТЕЛЬНО!)
REM ============================================================================
set "GIT_FOUND=0"
git --version >nul 2>nul
if !errorlevel! equ 0 (
 for /f "tokens=*" %%a in ('git --version 2^>nul') do set "GIT_VER=%%a"
 set "GIT_FOUND=1"
)

if !GIT_FOUND! equ 0 (
 cls
 echo.
 echo %ESC%[1;31m################################################################################%ESC%[0m
 echo %ESC%[1;31m##                                                                            ##%ESC%[0m
 echo %ESC%[1;31m##%ESC%[0m %ESC%[1;37mGit не найден в системе%ESC%[0m %ESC%[1;31m##%ESC%[0m
 echo %ESC%[1;31m##                                                                            ##%ESC%[0m
 echo %ESC%[1;31m################################################################################%ESC%[0m
 echo.
 echo %ESC%[1;31m[ОШИБКА] Git не установлен или не добавлен в PATH.%ESC%[0m
 echo.
 echo %ESC%[1;33mДля работы со скриптами требуется глобальный Git.%ESC%[0m
 echo.
 echo %ESC%[1;37mСкачайте и установите Git for Windows:%ESC%[0m
 echo %ESC%[1;36mhttps://git-scm.com/download/win%ESC%[0m
 echo.
 echo %ESC%[2mПосле установки перезапустите Start.bat%ESC%[0m
 echo.
 pause
 popd
 exit /b 1
)

REM ============================================================================
REM Авто-создание / обновление Config.ini
REM ============================================================================
set "CONFIG_NEED_CREATE=0"
if not exist "%CONFIG_FILE%" (
 set "CONFIG_NEED_CREATE=1"
) else (
 REM Проверяем наличие ключевых параметров
 findstr /B /C:"LLM_BACKEND=" "%CONFIG_FILE%" >nul 2>nul
 if !errorlevel! neq 0 set "CONFIG_NEED_CREATE=1"
 findstr /B /C:"OLLAMA_URL=" "%CONFIG_FILE%" >nul 2>nul
 if !errorlevel! neq 0 set "CONFIG_NEED_CREATE=1"
 findstr /B /C:"CHROMADB_PORT=" "%CONFIG_FILE%" >nul 2>nul
 if !errorlevel! neq 0 set "CONFIG_NEED_CREATE=1"
)

if "!CONFIG_NEED_CREATE!"=="1" (
 if exist "%CONFIG_FILE%" (
 echo %ESC%[1;33m⚠  Config.ini устарел. Обновление с сохранением настроек...%ESC%[0m

 set "OLD_LLM_BACKEND="
 set "OLD_OLLAMA_URL="
 set "OLD_AUTH_ENABLED="
 set "OLD_ADMIN_PASSWORD="
 set "OLD_APP_PORT="
 set "OLD_AUTO_OPEN_BROWSER="
 set "OLD_SEARXNG_ENABLED="
 set "OLD_SEARCH_API="
 set "OLD_SEARCH_API_KEY="

 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_BACKEND=" "%CONFIG_FILE%"') do set "OLD_LLM_BACKEND=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"OLLAMA_URL=" "%CONFIG_FILE%"') do set "OLD_OLLAMA_URL=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTH_ENABLED=" "%CONFIG_FILE%"') do set "OLD_AUTH_ENABLED=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"ADMIN_PASSWORD=" "%CONFIG_FILE%"') do set "OLD_ADMIN_PASSWORD=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"APP_PORT=" "%CONFIG_FILE%"') do set "OLD_APP_PORT=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "OLD_AUTO_OPEN_BROWSER=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARXNG_ENABLED=" "%CONFIG_FILE%"') do set "OLD_SEARXNG_ENABLED=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API=" "%CONFIG_FILE%"') do set "OLD_SEARCH_API=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API_KEY=" "%CONFIG_FILE%"') do set "OLD_SEARCH_API_KEY=%%b"

 set "OLD_LLM_BACKEND=%OLD_LLM_BACKEND: =%"
 set "OLD_OLLAMA_URL=%OLD_OLLAMA_URL: =%"
 set "OLD_AUTH_ENABLED=%OLD_AUTH_ENABLED: =%"
 set "OLD_ADMIN_PASSWORD=%OLD_ADMIN_PASSWORD: =%"
 set "OLD_APP_PORT=%OLD_APP_PORT: =%"
 set "OLD_AUTO_OPEN_BROWSER=%OLD_AUTO_OPEN_BROWSER: =%"
 set "OLD_SEARXNG_ENABLED=%OLD_SEARXNG_ENABLED: =%"
 set "OLD_SEARCH_API=%OLD_SEARCH_API: =%"
 set "OLD_SEARCH_API_KEY=%OLD_SEARCH_API_KEY: =%"

 if "!OLD_LLM_BACKEND!"=="" set "OLD_LLM_BACKEND=ollama"
 if "!OLD_OLLAMA_URL!"=="" set "OLD_OLLAMA_URL=http://127.0.0.1:11434/v1"
 if "!OLD_AUTH_ENABLED!"=="" set "OLD_AUTH_ENABLED=true"
 if "!OLD_ADMIN_PASSWORD!"=="" set "OLD_ADMIN_PASSWORD=admin"
 if "!OLD_APP_PORT!"=="" set "OLD_APP_PORT=7000"
 if "!OLD_AUTO_OPEN_BROWSER!"=="" set "OLD_AUTO_OPEN_BROWSER=1"
 if "!OLD_SEARXNG_ENABLED!"=="" set "OLD_SEARXNG_ENABLED=0"
 if "!OLD_SEARCH_API!"=="" set "OLD_SEARCH_API=none"
 if "!OLD_SEARCH_API_KEY!"=="" set "OLD_SEARCH_API_KEY="

 call "%SCRIPTS_DIR%\CreateConfig.bat" "!OLD_LLM_BACKEND!" "!OLD_OLLAMA_URL!" "!OLD_AUTH_ENABLED!" "!OLD_ADMIN_PASSWORD!" "!OLD_APP_PORT!" "!OLD_AUTO_OPEN_BROWSER!" "!OLD_SEARXNG_ENABLED!" "!OLD_SEARCH_API!" "!OLD_SEARCH_API_KEY!"

 ) else (
 echo %ESC%[1;33m-%ESC%[0m %ESC%[1mСоздание Config.ini...%ESC%[0m
 call "%SCRIPTS_DIR%\CreateConfig.bat" 
 )
 echo %ESC%[1;32m + Config.ini готов.%ESC%[0m
 echo.
)

REM ============================================================================
REM Чтение Config.ini
REM ============================================================================
set "LLM_BACKEND=ollama"
set "OLLAMA_URL=http://127.0.0.1:11434/v1"
set "AUTH_ENABLED=true"
set "ADMIN_PASSWORD=admin"
set "APP_PORT=7000"
set "AUTO_OPEN_BROWSER=1"
set "SEARXNG_ENABLED=0"
set "SEARCH_API=none"
set "SEARCH_API_KEY="

if exist "%CONFIG_FILE%" (
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_BACKEND=" "%CONFIG_FILE%"') do set "LLM_BACKEND=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"OLLAMA_URL=" "%CONFIG_FILE%"') do set "OLLAMA_URL=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTH_ENABLED=" "%CONFIG_FILE%"') do set "AUTH_ENABLED=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"ADMIN_PASSWORD=" "%CONFIG_FILE%"') do set "ADMIN_PASSWORD=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"APP_PORT=" "%CONFIG_FILE%"') do set "APP_PORT=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARXNG_ENABLED=" "%CONFIG_FILE%"') do set "SEARXNG_ENABLED=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API=" "%CONFIG_FILE%"') do set "SEARCH_API=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API_KEY=" "%CONFIG_FILE%"') do set "SEARCH_API_KEY=%%b"
)

set "LLM_BACKEND=%LLM_BACKEND: =%"
set "OLLAMA_URL=%OLLAMA_URL: =%"
set "AUTH_ENABLED=%AUTH_ENABLED: =%"
set "ADMIN_PASSWORD=%ADMIN_PASSWORD: =%"
set "APP_PORT=%APP_PORT: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "SEARXNG_ENABLED=%SEARXNG_ENABLED: =%"
set "SEARCH_API=%SEARCH_API: =%"
set "SEARCH_API_KEY=%SEARCH_API_KEY: =%"

:menu
REM Перечитываем Config.ini (мог измениться)
if exist "%CONFIG_FILE%" (
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_BACKEND=" "%CONFIG_FILE%"') do set "LLM_BACKEND=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"OLLAMA_URL=" "%CONFIG_FILE%"') do set "OLLAMA_URL=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTH_ENABLED=" "%CONFIG_FILE%"') do set "AUTH_ENABLED=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"ADMIN_PASSWORD=" "%CONFIG_FILE%"') do set "ADMIN_PASSWORD=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"APP_PORT=" "%CONFIG_FILE%"') do set "APP_PORT=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARXNG_ENABLED=" "%CONFIG_FILE%"') do set "SEARXNG_ENABLED=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API=" "%CONFIG_FILE%"') do set "SEARCH_API=%%b"
 for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API_KEY=" "%CONFIG_FILE%"') do set "SEARCH_API_KEY=%%b"
)

set "LLM_BACKEND=%LLM_BACKEND: =%"
set "OLLAMA_URL=%OLLAMA_URL: =%"
set "AUTH_ENABLED=%AUTH_ENABLED: =%"
set "ADMIN_PASSWORD=%ADMIN_PASSWORD: =%"
set "APP_PORT=%APP_PORT: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "SEARXNG_ENABLED=%SEARXNG_ENABLED: =%"
set "SEARCH_API=%SEARCH_API: =%"
set "SEARCH_API_KEY=%SEARCH_API_KEY: =%"

cls
echo.
echo %ESC%[1;36m################################################################################%ESC%[0m
echo %ESC%[1;36m##                                                                            ##%ESC%[0m
echo %ESC%[1;36m##%ESC%[0m %ESC%[1;37m                         Odysseus%ESC%[0m — %ESC%[1;33mГлавное меню%ESC%[0m                           %ESC%[1;36m##%ESC%[0m
echo %ESC%[1;36m##%ESC%[0m %ESC%[2m                   Self-hosted AI Workspace (Portable)%ESC%[0m                     %ESC%[1;36m##%ESC%[0m
echo %ESC%[1;36m##                                                                            ##%ESC%[0m
echo %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM Проверка статуса компонентов
REM ============================================================================
echo %ESC%[1;33mСтатус компонентов:%ESC%[0m

REM Python
set "PYTHON_INSTALLED=0"
if exist "%PYTHON_DIR%\python.exe" (
 for /f "tokens=1,2" %%a in ('"%PYTHON_DIR%\python.exe" --version 2^>nul') do set "PYTHON_VER=%%b"
 echo %ESC%[1;32m+ %ESC%[0m Python !PYTHON_VER!
 set "PYTHON_INSTALLED=1"
) else (
 echo %ESC%[1;31m- %ESC%[0m Python — не установлен
)

REM Репозиторий
set "REPO_INSTALLED=0"
set "REPO_BRANCH="
if exist "%REPO_DIR%\.git" (
 cd /d "%REPO_DIR%" 2>nul
 for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "REPO_BRANCH=%%a"
 cd /d "%ROOT_DIR%" 2>nul
 if "!REPO_BRANCH!"=="dev" (
 echo %ESC%[1;32m+ %ESC%[0m Репозиторий Odysseus %ESC%[2m^(dev^)%ESC%[0m
 ) else (
 echo %ESC%[1;33m. %ESC%[0m Репозиторий Odysseus %ESC%[2m^(!REPO_BRANCH!, ожидается dev^)%ESC%[0m
 )
 set "REPO_INSTALLED=1"
) else (
 echo %ESC%[1;31m- %ESC%[0m Репозиторий — не клонирован
)

REM Зависимости Python
set "DEPS_INSTALLED=0"
if exist "%PYTHON_DIR%\python.exe" (
 "%PYTHON_DIR%\python.exe" -c "import fastapi, uvicorn, sqlalchemy, chromadb, fastembed, bcrypt, pydantic" >nul 2>nul
 if !errorlevel! equ 0 (
 echo %ESC%[1;32m+ %ESC%[0m Python зависимости
 set "DEPS_INSTALLED=1"
 ) else (
 echo %ESC%[1;31m- %ESC%[0m Python зависимости — не установлены
 )
) else (
 echo %ESC%[1;31m- %ESC%[0m Python зависимости — Python не установлен
)

REM Node.js (portable)
set "NODE_INSTALLED=0"
set "NODE_DIR=%ROOT_DIR%\node-dist"
if exist "%NODE_DIR%\node.exe" (
    for /f "tokens=*" %%a in ('"%NODE_DIR%\node.exe" --version 2^>nul') do set "NODE_VER=%%a"
    echo %ESC%[1;32m+ %ESC%[0m Node.js %NODE_VER%
    set "NODE_INSTALLED=1"
    REM Добавляем в PATH для текущей сессии
    set "PATH=%NODE_DIR%;%PATH%"
) else (
    echo %ESC%[1;33m. %ESC%[0m Node.js — не установлен %ESC%[2m^(Browser MCP будет недоступен^)%ESC%[0m
)

REM ChromaDB (проверяем порт)
set "CHROMADB_RUNNING=0"
for /f "tokens=*" %%a in ('%PS_WRAPPER% -Command "try { $c = New-Object System.Net.Sockets.TcpClient; $c.Connect('127.0.0.1', 8100); $c.Close(); Write-Host 'OK' } catch { Write-Host 'NO' }"') do set "CHROMADB_CHK=%%a"
if "!CHROMADB_CHK!"=="OK" (
 echo %ESC%[1;32m+ %ESC%[0m ChromaDB %ESC%[2m^(порт 8100^)%ESC%[0m
 set "CHROMADB_RUNNING=1"
) else (
 echo %ESC%[1;33m. %ESC%[0m ChromaDB %ESC%[2m^(не запущен, будет запущен автоматически^)%ESC%[0m
)

REM Ollama (проверяем порт 11434)
set "OLLAMA_RUNNING=0"
for /f "tokens=*" %%a in ('%PS_WRAPPER% -Command "try { $c = New-Object System.Net.Sockets.TcpClient; $c.Connect('127.0.0.1', 11434); $c.Close(); Write-Host 'OK' } catch { Write-Host 'NO' }"') do set "OLLAMA_CHK=%%a"
if "!OLLAMA_CHK!"=="OK" (
 echo %ESC%[1;32m+ %ESC%[0m Ollama %ESC%[2m^(порт 11434^)%ESC%[0m
 set "OLLAMA_RUNNING=1"
) else (
 echo %ESC%[1;33m. %ESC%[0m Ollama %ESC%[2m^(не запущен, проверьте Ollama^)%ESC%[0m
)

REM Подсчёт — 4 компонента (Python, Repo, Deps, Node)
set /a "INSTALLED_COUNT=!PYTHON_INSTALLED!+!REPO_INSTALLED!+!DEPS_INSTALLED!+!NODE_INSTALLED!"

echo.
echo %ESC%[1;33mLLM%ESC%[0m%ESC%[2m^:%ESC%[0m %ESC%[1;33m%LLM_BACKEND%%ESC%[0m %ESC%[2m^|%ESC%[0m %ESC%[1;33m%OLLAMA_URL%%ESC%[0m
echo %ESC%[1;33mAuth%ESC%[0m%ESC%[2m^:%ESC%[0m %ESC%[1;33m%AUTH_ENABLED%%ESC%[0m %ESC%[2m^|%ESC%[0m %ESC%[1;33mПорт%ESC%[0m%ESC%[2m^:%ESC%[0m %ESC%[1;33m%APP_PORT%%ESC%[0m %ESC%[2m^|%ESC%[0m %ESC%[1;33mSearch%ESC%[0m%ESC%[2m^:%ESC%[0m %ESC%[1;33m%SEARCH_API%%ESC%[0m
echo.

echo %ESC%[1;37m[1]%ESC%[0m %ESC%[1mУстановка / Обновление компонентов%ESC%[0m
echo %ESC%[1;37m[2]%ESC%[0m %ESC%[1mНастройки%ESC%[0m %ESC%[2m(LLM, порт, auth, поиск)%ESC%[0m
echo %ESC%[1;37m[3]%ESC%[0m %ESC%[1mИнструменты разработчика%ESC%[0m %ESC%[2m(Git, обновление, очистка)%ESC%[0m
echo.

if "!INSTALLED_COUNT!"=="4" (
 echo %ESC%[1;37m[*]%ESC%[0m %ESC%[1mЗапуск Odysseus%ESC%[0m %ESC%[2m^(http://127.0.0.1:%APP_PORT%^)%ESC%[0m
) else (
 echo %ESC%[1;30m[*]%ESC%[0m %ESC%[1;30mЗапуск Odysseus%ESC%[0m %ESC%[2m^(не все компоненты установлены^)%ESC%[0m
)

echo.
echo %ESC%[1;37m[0]%ESC%[0m %ESC%[1mВыход%ESC%[0m
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите действие (0-3, Enter для запуска): %ESC%[0m"

if not defined choice goto Odysseus
set "choice=%choice: =%"
if "%choice%"=="" goto Odysseus
if "%choice%"=="*" goto Odysseus
if "%choice%"=="1" goto setup
if "%choice%"=="2" goto settings
if "%choice%"=="3" goto dev_tools
if "%choice%"=="0" goto exit
goto menu

:setup
call "%SCRIPTS_DIR%\InstallOrUpdate.bat"
goto menu

:settings
call "%SCRIPTS_DIR%\Settings.bat"
goto menu

:dev_tools
call "%SCRIPTS_DIR%\DevTools.bat"
goto menu

:Odysseus
if "!INSTALLED_COUNT!"=="4" (
    cls
    echo.
    echo %ESC%[1;33m-%ESC%[0m %ESC%[1mЗапуск Odysseus...%ESC%[0m
    echo.
    call "%SCRIPTS_DIR%\Start-Odysseus.bat"
    pause
    goto menu
) else (
    cls
    echo.
    echo %ESC%[1;31m[ОШИБКА] Не все компоненты установлены.%ESC%[0m
    echo %ESC%[33m Запустите установку через пункт меню [1]%ESC%[0m
    echo.
    pause
    goto menu
)

:exit
popd
exit /b 0
