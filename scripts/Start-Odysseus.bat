REM scripts\Start-Odysseus.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
set "REPO_DIR=%ROOT_DIR%\repo"
set "DATA_DIR=%ROOT_DIR%\data"
set "NODE_DIR=%ROOT_DIR%\node-dist"
set "NODE_EXE=%NODE_DIR%\node.exe"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"

REM ============================================================================
REM   Изоляция данных (ничего в систему!)
REM ============================================================================
set "TEMP=%DATA_DIR%\temp"
set "TMP=%DATA_DIR%\temp"
set "APPDATA=%DATA_DIR%\appdata"
set "LOCALAPPDATA=%DATA_DIR%\localappdata"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"
set "HF_HOME=%DATA_DIR%\huggingface"
set "PYTHONUSERBASE=%DATA_DIR%\python-userbase"
set "PYTHONIOENCODING=utf-8"
set "PIP_NO_CACHE_DIR=1"
set "HF_HUB_DISABLE_SYMLINKS=1"
set "HF_HUB_DISABLE_SYMLINKS_WARNING=1"

REM ============================================================================
REM   PYTHONPATH — добавляем REPO_DIR для импорта модулей
REM ============================================================================
set "PYTHONPATH=%REPO_DIR%;%PYTHONPATH%"

REM ============================================================================
REM   PowerShell wrapper (изоляция)
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

set "PYTHON=%PYTHON_DIR%\python.exe"
set "PIP=%PYTHON_DIR%\Scripts\pip.exe"

REM ============================================================================
REM   Читаем настройки из Config.ini
REM ============================================================================
set "APP_PORT=7000"
set "AUTO_OPEN_BROWSER=1"
set "CHROMADB_PORT=8100"
set "LLM_API_URL=http://127.0.0.1:11434/v1"

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"APP_PORT=" "%CONFIG_FILE%"') do set "APP_PORT=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTO_OPEN_BROWSER=" "%CONFIG_FILE%"') do set "AUTO_OPEN_BROWSER=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"CHROMADB_PORT=" "%CONFIG_FILE%"') do set "CHROMADB_PORT=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_API_URL=" "%CONFIG_FILE%"') do set "LLM_API_URL=%%b"
)

set "APP_PORT=%APP_PORT: =%"
set "AUTO_OPEN_BROWSER=%AUTO_OPEN_BROWSER: =%"
set "CHROMADB_PORT=%CHROMADB_PORT: =%"
set "LLM_API_URL=%LLM_API_URL: =%"

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m      %ESC%[1;37mOdysseus — Запуск%ESC%[0m     %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка / создание .env
REM ============================================================================
if not exist "%REPO_DIR%\.env" (
    echo   %ESC%[1;33m  .   Создание .env файла...%ESC%[0m
    call "%SCRIPTS_DIR%\CreateEnv.bat"
    if exist "%REPO_DIR%\.env" (
        echo   %ESC%[1;32m  +   .env создан%ESC%[0m
    ) else (
        echo   %ESC%[1;31m  [ПРЕДУПРЕЖДЕНИЕ] .env не создан%ESC%[0m
    )
    echo.
)

REM ============================================================================
REM   Проверка Ollama (или другого LLM backend)
REM ============================================================================
echo   %ESC%[1;33mПроверка LLM backend...%ESC%[0m

REM Парсим URL: http://host:port/v1 или https://host:port/v1
set "LLM_HOST=127.0.0.1"
set "LLM_PORT=11434"

REM Убираем протокол (http:// или https://)
set "LLM_URL_TMP=!LLM_API_URL:http://=!"
set "LLM_URL_TMP=!LLM_URL_TMP:https://=!"

REM Теперь формат: host:port/v1
for /f "tokens=1,2 delims=:/" %%a in ("!LLM_URL_TMP!") do (
    set "LLM_HOST=%%a"
    set "LLM_PORT=%%b"
)
set "LLM_PORT=!LLM_PORT:/v1=!"

REM Если порт не распарсился (например, для https://api.openai.com/v1), ставим дефолт
if "!LLM_PORT!"=="v1" set "LLM_PORT=443"
if "!LLM_PORT!"=="" set "LLM_PORT=80"
if "!LLM_API_URL:~0,5!"=="https" if "!LLM_PORT!"=="80" set "LLM_PORT=443"

for /f "tokens=*" %%a in ('%PS_WRAPPER% -Command "try { $c = New-Object System.Net.Sockets.TcpClient; $c.Connect('!LLM_HOST!', !LLM_PORT!); $c.Close(); Write-Host 'OK' } catch { Write-Host 'NO' }"') do set "LLM_CHK=%%a"

if "!LLM_CHK!"=="OK" (
    echo   %ESC%[1;32m  +   LLM backend отвечает ^(!LLM_HOST!:!LLM_PORT!^)%ESC%[0m
) else (
    echo   %ESC%[1;33m  .   LLM backend не отвечает ^(!LLM_HOST!:!LLM_PORT!^)%ESC%[0m
    echo   %ESC%[33m       Убедитесь, что Ollama/LM Studio запущены, или измените backend в настройках.%ESC%[0m
    echo.
)

REM ============================================================================
REM   Запуск ChromaDB (если не запущена)
REM ============================================================================
echo   %ESC%[1;33mПроверка ChromaDB...%ESC%[0m

for /f "tokens=*" %%a in ('%PS_WRAPPER% -Command "try { $c = New-Object System.Net.Sockets.TcpClient; $c.Connect('127.0.0.1', %CHROMADB_PORT%); $c.Close(); Write-Host 'OK' } catch { Write-Host 'NO' }"') do set "CHROMADB_CHK=%%a"

if "!CHROMADB_CHK!"=="OK" (
    echo   %ESC%[1;32m  +   ChromaDB уже запущена ^(порт %CHROMADB_PORT%^)%ESC%[0m
) else (
    echo   %ESC%[1;33m  -   Запуск ChromaDB...%ESC%[0m

    set "CHROMADB_DATA=%DATA_DIR%\chromadb"
    if not exist "!CHROMADB_DATA!" mkdir "!CHROMADB_DATA!"

    REM Запускаем ChromaDB через chroma.exe (не через python -m)
    if exist "%PYTHON_DIR%\Scripts\chroma.exe" (
        start "" /MIN "%PYTHON_DIR%\Scripts\chroma.exe" run --path "!CHROMADB_DATA!" --port %CHROMADB_PORT% --host 127.0.0.1
    ) else (
        start "" /MIN "%PYTHON%" -m chromadb run --path "!CHROMADB_DATA!" --port %CHROMADB_PORT% --host 127.0.0.1
    )

    REM Ждём запуска
    echo   %ESC%[1;33m  -   Ожидание ChromaDB...%ESC%[0m
    set /a "WAIT_COUNT=0"
    :wait_chroma
    timeout /t 1 /nobreak >nul
    for /f "tokens=*" %%a in ('%PS_WRAPPER% -Command "try { $c = New-Object System.Net.Sockets.TcpClient; $c.Connect('127.0.0.1', %CHROMADB_PORT%); $c.Close(); Write-Host 'OK' } catch { Write-Host 'NO' }"') do set "CHROMADB_CHK2=%%a"
    set /a "WAIT_COUNT+=1"
    if "!CHROMADB_CHK2!"=="NO" if !WAIT_COUNT! lss 30 goto wait_chroma

    if "!CHROMADB_CHK2!"=="OK" (
        echo   %ESC%[1;32m  +   ChromaDB запущена ^(порт %CHROMADB_PORT%^)%ESC%[0m
    ) else (
        echo   %ESC%[1;31m  [ПРЕДУПРЕЖДЕНИЕ] ChromaDB не запустилась. RAG будет недоступен.%ESC%[0m
    )
)

REM ============================================================================
REM   First-time setup (setup.py)
REM ============================================================================
echo.
echo   %ESC%[1;33mFirst-time setup...%ESC%[0m

if exist "%REPO_DIR%\setup.py" (
    cd /d "%REPO_DIR%"
    "%PYTHON%" setup.py > "%DATA_DIR%\logs\setup.log" 2>&1
    if !errorlevel! equ 0 (
        echo   %ESC%[1;32m  +   Готово%ESC%[0m
    ) else (
        echo   %ESC%[1;33m  .   setup.py завершился с предупреждением ^(не критично^)%ESC%[0m
        echo   %ESC%[2m       Лог: %DATA_DIR%\logs\setup.log%ESC%[0m
    )
    cd /d "%ROOT_DIR%"
) else (
    echo   %ESC%[1;33m  .   setup.py не найден, пропускаем%ESC%[0m
)

REM ============================================================================
REM   Запуск Odysseus
REM ============================================================================
echo.
echo   %ESC%[1;33mЗапуск Odysseus...%ESC%[0m
echo   %ESC%[2m       URL: http://127.0.0.1:%APP_PORT%%ESC%[0m
echo   %ESC%[2m       Для остановки нажмите Ctrl+C в этом окне%ESC%[0m
echo.

if "%AUTO_OPEN_BROWSER%"=="1" (
    start "" "http://127.0.0.1:%APP_PORT%"
)

REM Создаём лог-директорию если нет
if not exist "%DATA_DIR%\logs" mkdir "%DATA_DIR%\logs"

cd /d "%REPO_DIR%"

REM Запускаем uvicorn с корректной обработкой сигналов
"%PYTHON%" -m uvicorn app:app --host 127.0.0.1 --port %APP_PORT% --log-level info

cd /d "%ROOT_DIR%"

echo.
echo   %ESC%[1;33mOdysseus остановлен.%ESC%[0m
pause
exit /b 0