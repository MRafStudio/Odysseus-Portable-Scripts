REM scripts\InstallOrUpdate-Deps.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title Odysseus — Установка Python зависимостей

REM ============================================================================
REM   Получение ESC через PowerShell
REM ============================================================================
for /f %%a in ('powershell -NoProfile -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение путей
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "PYTHON_DIR=%ROOT_DIR%\python-3.12.10"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"
set "REPO_DIR=%ROOT_DIR%\repo"

REM ============================================================================
REM   Изоляция данных
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "TMP=%DATA_DIR%\temp"
set "APPDATA=%DATA_DIR%\appdata"
set "LOCALAPPDATA=%DATA_DIR%\localappdata"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"
set "PIP_CACHE_DIR=%DATA_DIR%\pip-cache"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%APPDATA%" mkdir "%APPDATA%" 2>nul
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul
if not exist "%PIP_CACHE_DIR%" mkdir "%PIP_CACHE_DIR%" 2>nul

REM ============================================================================
REM   Проверка Python
REM ============================================================================
if not exist "%PYTHON_EXE%" (
    echo   %ESC%[1;31m[ОШИБКА] Python не установлен! Сначала запустите установку Python.%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

REM Добавляем Python в PATH для текущей сессии
set "PATH=%PYTHON_DIR%;%PYTHON_DIR%\Scripts;%PATH%"

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m                %ESC%[1;37mOdysseus%ESC%[0m   %ESC%[1;33m—%ESC%[0m   %ESC%[1;33mУстановка Python зависимостей%ESC%[0m                %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Проверка репозитория
REM ============================================================================
if not exist "%REPO_DIR%\requirements.txt" (
    echo   %ESC%[1;31m[ОШИБКА] Репозиторий не клонирован или requirements.txt не найден!%ESC%[0m
    echo   %ESC%[33m       Сначала клонируйте репозиторий через меню [2].%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

REM ============================================================================
REM   Шаг 1: Фикс requirements.txt (с кэшированием по дате)
REM ============================================================================
echo   %ESC%[1;33m[1/4]%ESC%[0m %ESC%[1mИсправление requirements.txt...%ESC%[0m

set "REQ_ORIG=%REPO_DIR%\requirements.txt"
set "REQ_FIXED=%REPO_DIR%\requirements-fixed.txt"

REM Проверяем нужно ли пересоздавать (сравниваем дату модификации)
set "NEED_FIX=1"
if exist "%REQ_FIXED%" (
    for %%F in ("%REQ_ORIG%") do set "ORIG_TIME=%%~tF"
    for %%F in ("%REQ_FIXED%") do set "FIXED_TIME=%%~tF"
    if "!ORIG_TIME!"=="!FIXED_TIME!" set "NEED_FIX=0"
)

if "!NEED_FIX!"=="0" (
    echo   %ESC%[1;32m  +   requirements-fixed.txt актуален ^(кэш^)%ESC%[0m
    goto fix_done
)

REM Фиксим через PowerShell напрямую (без промежуточного файла)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$lines = Get-Content '%REQ_ORIG%'; $out = @(); foreach ($line in $lines) { $trim = $line.Trim(); if ($trim -eq 'httpx2') { continue }; if ($trim -eq 'chromadb-client') { $out += 'chromadb'; continue }; if ($trim -like 'qrcode*') { $out += 'qrcode[pil]'; continue }; $out += $line }; $out += 'python-magic-bin'; $out | Set-Content '%REQ_FIXED%' -Encoding UTF8"

if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось исправить requirements.txt%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

echo   %ESC%[1;32m  +   requirements.txt исправлен%ESC%[0m
echo   %ESC%[2m       Удалено: httpx2, chromadb-client%ESC%[0m
echo   %ESC%[2m       Добавлено: chromadb, python-magic-bin%ESC%[0m
echo   %ESC%[2m       Сохранено: qrcode[pil]%ESC%[0m

:fix_done

REM ============================================================================
REM   Шаг 2: Обновление pip/setuptools/wheel
REM ============================================================================
echo.
echo   %ESC%[1;33m[2/4]%ESC%[0m %ESC%[1mОбновление pip, setuptools, wheel...%ESC%[0m

"%PYTHON_EXE%" -m pip install --upgrade pip setuptools wheel --no-warn-script-location --cache-dir "%PIP_CACHE_DIR%"
if !errorlevel! neq 0 (
    echo   %ESC%[1;33m  .   Не удалось обновить pip. Пробуем продолжить...%ESC%[0m
) else (
    echo   %ESC%[1;32m  +   pip обновлён%ESC%[0m
)

REM ============================================================================
REM   Шаг 3: Установка зависимостей (ТОЛЬКО в консоль, без логов)
REM ============================================================================
echo.
echo   %ESC%[1;33m[3/4]%ESC%[0m %ESC%[1mУстановка зависимостей (это может занять 5-15 минут)...%ESC%[0m

"%PYTHON_EXE%" -m pip install -r "%REQ_FIXED%" --no-warn-script-location --cache-dir "%PIP_CACHE_DIR%"

if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось установить зависимости!%ESC%[0m
    echo.
    echo   %ESC%[1;33mЧастые причины ошибок:%ESC%[0m
    echo   %ESC%[33m  1. Нет MSVC Build Tools ^(C++ компилятор^)%ESC%[0m
    echo   %ESC%[33m  2. Старая версия pip ^(попробуйте обновить вручную^)%ESC%[0m
    echo   %ESC%[33m  3. Проблемы с сетью / прокси%ESC%[0m
    echo.
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

echo   %ESC%[1;32m  +   Зависимости установлены%ESC%[0m

REM ============================================================================
REM   Шаг 4: Создание .env (с абсолютными путями!)
REM ============================================================================
echo.
echo   %ESC%[1;33m[4/4]%ESC%[0m %ESC%[1mСоздание .env файла...%ESC%[0m

set "ENV_FILE=%REPO_DIR%\.env"
set "CONFIG_FILE=%ROOT_DIR%\scripts\Config.ini"

if exist "%ENV_FILE%" (
    echo   %ESC%[1;32m  +   .env уже существует ^(пропускаем^)%ESC%[0m
    goto deps_done
)

REM Читаем настройки из Config.ini
set "CFG_LLM_BACKEND=ollama"
set "CFG_OLLAMA_URL=http://127.0.0.1:11434/v1"
set "CFG_AUTH_ENABLED=true"
set "CFG_ADMIN_PASSWORD=admin"
set "CFG_APP_PORT=7000"
set "CFG_SEARXNG_ENABLED=0"
set "CFG_SEARCH_API=none"
set "CFG_SEARCH_API_KEY="

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_BACKEND=" "%CONFIG_FILE%"') do set "CFG_LLM_BACKEND=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"OLLAMA_URL=" "%CONFIG_FILE%"') do set "CFG_OLLAMA_URL=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTH_ENABLED=" "%CONFIG_FILE%"') do set "CFG_AUTH_ENABLED=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"ADMIN_PASSWORD=" "%CONFIG_FILE%"') do set "CFG_ADMIN_PASSWORD=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"APP_PORT=" "%CONFIG_FILE%"') do set "CFG_APP_PORT=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARXNG_ENABLED=" "%CONFIG_FILE%"') do set "CFG_SEARXNG_ENABLED=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API=" "%CONFIG_FILE%"') do set "CFG_SEARCH_API=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API_KEY=" "%CONFIG_FILE%"') do set "CFG_SEARCH_API_KEY=%%b"
)

set "CFG_LLM_BACKEND=%CFG_LLM_BACKEND: =%"
set "CFG_OLLAMA_URL=%CFG_OLLAMA_URL: =%"
set "CFG_AUTH_ENABLED=%CFG_AUTH_ENABLED: =%"
set "CFG_ADMIN_PASSWORD=%CFG_ADMIN_PASSWORD: =%"
set "CFG_APP_PORT=%CFG_APP_PORT: =%"
set "CFG_SEARXNG_ENABLED=%CFG_SEARXNG_ENABLED: =%"
set "CFG_SEARCH_API=%CFG_SEARCH_API: =%"
set "CFG_SEARCH_API_KEY=%CFG_SEARCH_API_KEY: =%"

if "!CFG_LLM_BACKEND!"=="" set "CFG_LLM_BACKEND=ollama"
if "!CFG_OLLAMA_URL!"=="" set "CFG_OLLAMA_URL=http://127.0.0.1:11434/v1"
if "!CFG_AUTH_ENABLED!"=="" set "CFG_AUTH_ENABLED=true"
if "!CFG_ADMIN_PASSWORD!"=="" set "CFG_ADMIN_PASSWORD=admin"
if "!CFG_APP_PORT!"=="" set "CFG_APP_PORT=7000"
if "!CFG_SEARXNG_ENABLED!"=="" set "CFG_SEARXNG_ENABLED=0"
if "!CFG_SEARCH_API!"=="" set "CFG_SEARCH_API=none"
if "!CFG_SEARCH_API_KEY!"=="" set "CFG_SEARCH_API_KEY="

REM Абсолютный путь к БД (Windows-формат с прямыми слэшами для SQLite)
set "DB_PATH=%DATA_DIR%\app.db"
set "DB_PATH=%DB_PATH:\=/%"

REM Создаём .env построчно
>> "%ENV_FILE%" echo # Odysseus Portable — Environment Configuration
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- LLM ---
>> "%ENV_FILE%" echo LLM_HOST=localhost
>> "%ENV_FILE%" echo OLLAMA_BASE_URL=!CFG_OLLAMA_URL!
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- Database ---
>> "%ENV_FILE%" echo DATABASE_URL=sqlite:///%DB_PATH%
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- Auth ---
>> "%ENV_FILE%" echo AUTH_ENABLED=!CFG_AUTH_ENABLED!
>> "%ENV_FILE%" echo ODYSSEUS_ADMIN_USER=admin
>> "%ENV_FILE%" echo ODYSSEUS_ADMIN_PASSWORD=!CFG_ADMIN_PASSWORD!
>> "%ENV_FILE%" echo LOCALHOST_BYPASS=false
>> "%ENV_FILE%" echo SECURE_COOKIES=false
>> "%ENV_FILE%" echo ALLOWED_ORIGINS=http://localhost,http://127.0.0.1
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- App ---
>> "%ENV_FILE%" echo APP_BIND=127.0.0.1
>> "%ENV_FILE%" echo APP_PORT=!CFG_APP_PORT!
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- ChromaDB ---
>> "%ENV_FILE%" echo CHROMADB_HOST=127.0.0.1
>> "%ENV_FILE%" echo CHROMADB_PORT=8100
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- Embeddings ---
>> "%ENV_FILE%" echo FASTEMBED_MODEL=sentence-transformers/all-MiniLM-L6-v2
>> "%ENV_FILE%" echo FASTEMBED_CACHE_PATH=%DATA_DIR%\fastembed
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- Search ---
if "!CFG_SEARXNG_ENABLED!"=="1" (
    >> "%ENV_FILE%" echo SEARXNG_INSTANCE=http://127.0.0.1:8080
) else (
    >> "%ENV_FILE%" echo # SEARXNG_INSTANCE=http://127.0.0.1:8080
)
if "!CFG_SEARCH_API!"=="brave" (
    >> "%ENV_FILE%" echo DATA_BRAVE_API_KEY=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # DATA_BRAVE_API_KEY=
)
if "!CFG_SEARCH_API!"=="tavily" (
    >> "%ENV_FILE%" echo TAVILY_API_KEY=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # TAVILY_API_KEY=
)
if "!CFG_SEARCH_API!"=="serper" (
    >> "%ENV_FILE%" echo SERPER_API_KEY=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # SERPER_API_KEY=
)
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- Misc ---
>> "%ENV_FILE%" echo CLEANUP_INTERVAL_HOURS=24
>> "%ENV_FILE%" echo ODYSSEUS_INPROCESS_POLLERS=1
>> "%ENV_FILE%" echo ODYSSEUS_INPROCESS_TASKS=1
>> "%ENV_FILE%" echo ODYSSEUS_SCRIPT_HOST=localhost
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # --- Upload limits ---
>> "%ENV_FILE%" echo ODYSSEUS_CHAT_UPLOAD_MAX_BYTES=10485760
>> "%ENV_FILE%" echo ODYSSEUS_GALLERY_UPLOAD_MAX_BYTES=104857600
>> "%ENV_FILE%" echo.

echo   %ESC%[1;32m  +   .env создан (абсолютные пути)%ESC%[0m

REM ============================================================================
REM   Шаг 5: Опциональные зависимости (ТОЛЬКО в консоль, без логов)
REM ============================================================================
echo.
echo   %ESC%[1;33m[5/5]%ESC%[0m %ESC%[1mУстановка опциональных зависимостей...%ESC%[0m
echo   %ESC%[2m       ddgs (DuckDuckGo поиск), PyMuPDF (PDF формы), markitdown (Office/EPUB)%ESC%[0m

"%PYTHON_EXE%" -m pip install ddgs PyMuPDF "markitdown[all]" --no-warn-script-location --cache-dir "%PIP_CACHE_DIR%"

if !errorlevel! neq 0 (
    echo   %ESC%[1;33m  .   Не все опциональные зависимости установились ^(не критично^).%ESC%[0m
) else (
    echo   %ESC%[1;32m  +   Опциональные зависимости установлены%ESC%[0m
)

:deps_done
echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mPython зависимости установлены!%ESC%[0m
echo   %ESC%[2m  Путь: %PYTHON_DIR%%ESC%[0m
echo   %ESC%[2m  requirements: %REQ_FIXED%%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m

if "%AUTOCLOSE%"=="1" (
    call "%~dp0SmartPause.bat" 5
) else (
    pause
)
exit /b 0