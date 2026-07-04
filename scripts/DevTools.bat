REM scripts\DevTools.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
set "REPO_DIR=%ROOT_DIR%\repo"
set "DATA_DIR=%ROOT_DIR%\data"

set "PS_WRAPPER=%TEMP%\ps_wrapper.bat"
(
    echo @echo off
    echo powershell -NoProfile -NonInteractive %%*
) > "%PS_WRAPPER%"

for /f "usebackq" %%a in (`%PS_WRAPPER% -Command "Write-Host ([char]27) -NoNewline"`) do set "ESC=%%a"

:dev_menu
cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m %ESC%[1;37mOdysseus — Инструменты разработчика%ESC%[0m %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

echo   %ESC%[1;37m[1]%ESC%[0m Обновить репозиторий (git pull origin dev)
echo   %ESC%[1;37m[2]%ESC%[0m Переустановить Python зависимости
echo   %ESC%[1;37m[3]%ESC%[0m Очистить данные (data, logs, кэш)
echo   %ESC%[1;37m[4]%ESC%[0m Сбросить базу данных (SQLite)
echo   %ESC%[1;37m[5]%ESC%[0m Проверить статус компонентов
echo   %ESC%[1;37m[6]%ESC%[0m Открыть папку репозитория
echo   %ESC%[1;37m[7]%ESC%[0m Открыть папку данных
echo   %ESC%[1;37m[8]%ESC%[0m Просмотр логов
echo.
echo   %ESC%[1;37m[0]%ESC%[0m Назад в главное меню
echo.
set "choice="
set /p "choice=%ESC%[33mВыберите действие (0-8): %ESC%[0m"
set "choice=%choice: =%"

if "%choice%"=="0" exit /b 0
if "%choice%"=="1" goto update_repo
if "%choice%"=="2" goto reinstall_deps
if "%choice%"=="3" goto clean_data
if "%choice%"=="4" goto reset_db
if "%choice%"=="5" goto check_status
if "%choice%"=="6" goto open_repo
if "%choice%"=="7" goto open_data
if "%choice%"=="8" goto view_logs

goto dev_menu

:update_repo
cls
echo.
echo   %ESC%[1;33mОбновление репозитория...%ESC%[0m
if not exist "%REPO_DIR%\.git" (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не клонирован!%ESC%[0m
    pause
    goto dev_menu
)
cd /d "%REPO_DIR%"
git fetch origin dev
git reset --hard origin/dev
cd /d "%ROOT_DIR%"
echo   %ESC%[1;32m  +   Репозиторий обновлён до dev%ESC%[0m
echo   %ESC%[1;33m  Внимание: если requirements.txt изменился, переустановите зависимости [2]%ESC%[0m
pause
goto dev_menu

:reinstall_deps
cls
echo.
echo   %ESC%[1;33mПереустановка Python зависимостей...%ESC%[0m
if not exist "%PYTHON_DIR%\python.exe" (
    echo   %ESC%[1;31m[ОШИБКА] Python не установлен!%ESC%[0m
    pause
    goto dev_menu
)
set "REQ_FIXED=%REPO_DIR%\requirements-fixed.txt"
if not exist "%REQ_FIXED%" (
    echo   %ESC%[1;31m[ОШИБКА] requirements-fixed.txt не найден!%ESC%[0m
    echo   %ESC%[33m  Запустите сначала установку [1] в главном меню.%ESC%[0m
    pause
    goto dev_menu
)
"%PYTHON_DIR%\python.exe" -m pip install -r "%REQ_FIXED%" --force-reinstall --no-warn-script-location
echo   %ESC%[1;32m  +   Зависимости переустановлены%ESC%[0m
pause
goto dev_menu

:clean_data
cls
echo.
echo   %ESC%[1;31mВНИМАНИЕ: Это удалит ВСЕ данные Odysseus!%ESC%[0m
echo   %ESC%[1;31mБаза данных, логи, загрузки, кэш HuggingFace — всё будет стёрто.%ESC%[0m
echo.
set "confirm="
set /p "confirm=%ESC%[31mВведите DELETE для подтверждения: %ESC%[0m"
if /I not "%confirm%"=="DELETE" (
    echo   %ESC%[1;33mОтменено.%ESC%[0m
    timeout /t 2 /nobreak >nul
    goto dev_menu
)

echo   %ESC%[1;33mОчистка...%ESC%[0m
if exist "%DATA_DIR%\app.db" del /f /q "%DATA_DIR%\app.db" 2>nul
if exist "%DATA_DIR%\logs" rmdir /s /q "%DATA_DIR%\logs" 2>nul
if exist "%DATA_DIR%\huggingface" rmdir /s /q "%DATA_DIR%\huggingface" 2>nul
if exist "%DATA_DIR%\fastembed" rmdir /s /q "%DATA_DIR%\fastembed" 2>nul
if exist "%DATA_DIR%\chromadb" rmdir /s /q "%DATA_DIR%\chromadb" 2>nul
if exist "%DATA_DIR%\temp" rmdir /s /q "%DATA_DIR%\temp" 2>nul
if exist "%DATA_DIR%\appdata" rmdir /s /q "%DATA_DIR%\appdata" 2>nul
if exist "%DATA_DIR%\localappdata" rmdir /s /q "%DATA_DIR%\localappdata" 2>nul
if exist "%DATA_DIR%\home" rmdir /s /q "%DATA_DIR%\home" 2>nul
if exist "%DATA_DIR%\python-userbase" rmdir /s /q "%DATA_DIR%\python-userbase" 2>nul

REM Пересоздаём структуру
if not exist "%DATA_DIR%\temp" mkdir "%DATA_DIR%\temp" 2>nul
if not exist "%DATA_DIR%\appdata" mkdir "%DATA_DIR%\appdata" 2>nul
if not exist "%DATA_DIR%\localappdata" mkdir "%DATA_DIR%\localappdata" 2>nul
if not exist "%DATA_DIR%\home" mkdir "%DATA_DIR%\home" 2>nul
if not exist "%DATA_DIR%\home\Desktop" mkdir "%DATA_DIR%\home\Desktop" 2>nul
if not exist "%DATA_DIR%\python-userbase" mkdir "%DATA_DIR%\python-userbase" 2>nul
if not exist "%DATA_DIR%\huggingface" mkdir "%DATA_DIR%\huggingface" 2>nul

echo   %ESC%[1;32m  +   Данные очищены. При следующем запуске будет first-time setup.%ESC%[0m
pause
goto dev_menu

:reset_db
cls
echo.
echo   %ESC%[1;31mВНИМАНИЕ: Это удалит базу данных SQLite!%ESC%[0m
echo   %ESC%[1;31mВсе сессии, сообщения, настройки пользователей будут потеряны.%ESC%[0m
echo.
set "confirm="
set /p "confirm=%ESC%[31mВведите RESET для подтверждения: %ESC%[0m"
if /I not "%confirm%"=="RESET" (
    echo   %ESC%[1;33mОтменено.%ESC%[0m
    timeout /t 2 /nobreak >nul
    goto dev_menu
)

if exist "%DATA_DIR%\app.db" (
    del /f /q "%DATA_DIR%\app.db" 2>nul
    echo   %ESC%[1;32m  +   База данных удалена. При следующем запуске будет first-time setup.%ESC%[0m
) else (
    echo   %ESC%[1;33m  .   База данных не найдена%ESC%[0m
)
pause
goto dev_menu

:check_status
cls
echo.
echo   %ESC%[1;36mСтатус компонентов:%ESC%[0m
echo.

REM Python
if exist "%PYTHON_DIR%\python.exe" (
    for /f "tokens=1,2" %%a in ('"%PYTHON_DIR%\python.exe" --version 2^>nul') do echo   %ESC%[1;32m[OK]%ESC%[0m  Python %%b
) else (
    echo   %ESC%[1;31m[NO]%ESC%[0m  Python — не установлен
)

REM Git
git --version >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('git --version 2^>nul') do echo   %ESC%[1;32m[OK]%ESC%[0m  %%a
) else (
    echo   %ESC%[1;31m[NO]%ESC%[0m  Git — не найден
)

REM Node.js
where node >nul 2>nul
if !errorlevel! equ 0 (
    for /f "tokens=*" %%a in ('node --version 2^>nul') do echo   %ESC%[1;32m[OK]%ESC%[0m  Node.js %%a
) else (
    echo   %ESC%[1;31m[NO]%ESC%[0m  Node.js — не установлен
)

REM Repo
if exist "%REPO_DIR%\.git" (
    cd /d "%REPO_DIR%" 2>nul
    for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do echo   %ESC%[1;32m[OK]%ESC%[0m  Репозиторий (ветка: %%a)
    cd /d "%ROOT_DIR%" 2>nul
) else (
    echo   %ESC%[1;31m[NO]%ESC%[0m  Репозиторий — не клонирован
)

REM Deps
if exist "%PYTHON_DIR%\python.exe" (
    "%PYTHON_DIR%\python.exe" -c "import fastapi, uvicorn, sqlalchemy, chromadb, fastembed, bcrypt, pydantic" >nul 2>nul
    if !errorlevel! equ 0 (
        echo   %ESC%[1;32m[OK]%ESC%[0m  Python зависимости
    ) else (
        echo   %ESC%[1;31m[NO]%ESC%[0m  Python зависимости — не все установлены
    )
) else (
    echo   %ESC%[1;31m[NO]%ESC%[0m  Python зависимости — Python не установлен
)

REM ChromaDB
for /f "tokens=*" %%a in ('%PS_WRAPPER% -Command "try { $c = New-Object System.Net.Sockets.TcpClient; $c.Connect('127.0.0.1', 8100); $c.Close(); Write-Host 'OK' } catch { Write-Host 'NO' }"') do set "CHROMADB_CHK=%%a"
if "!CHROMADB_CHK!"=="OK" (
    echo   %ESC%[1;32m[OK]%ESC%[0m  ChromaDB (порт 8100)
) else (
    echo   %ESC%[1;31m[NO]%ESC%[0m  ChromaDB (порт 8100) — не запущена
)

REM Ollama
for /f "tokens=*" %%a in ('%PS_WRAPPER% -Command "try { $c = New-Object System.Net.Sockets.TcpClient; $c.Connect('127.0.0.1', 11434); $c.Close(); Write-Host 'OK' } catch { Write-Host 'NO' }"') do set "OLLAMA_CHK=%%a"
if "!OLLAMA_CHK!"=="OK" (
    echo   %ESC%[1;32m[OK]%ESC%[0m  Ollama (порт 11434)
) else (
    echo   %ESC%[1;33m[--]%ESC%[0m  Ollama (порт 11434) — не запущена (не критично)
)

REM .env
if exist "%REPO_DIR%\.env" (
    echo   %ESC%[1;32m[OK]%ESC%[0m  .env файл
) else (
    echo   %ESC%[1;31m[NO]%ESC%[0m  .env файл — не создан
)

echo.
pause
goto dev_menu

:open_repo
start explorer "%REPO_DIR%"
goto dev_menu

:open_data
start explorer "%DATA_DIR%"
goto dev_menu

:view_logs
cls
echo.
if exist "%DATA_DIR%\logs\app.log" (
    echo   %ESC%[1;33mПоследние 50 строк лога:%ESC%[0m
    echo   %ESC%[2m--------------------------------------------------%ESC%[0m
    %PS_WRAPPER% -Command "Get-Content '%DATA_DIR%\logs\app.log' -Tail 50"
    echo   %ESC%[2m--------------------------------------------------%ESC%[0m
) else (
    echo   %ESC%[1;33mЛог-файл не найден. Запустите Odysseus для создания логов.%ESC%[0m
)
pause
goto dev_menu