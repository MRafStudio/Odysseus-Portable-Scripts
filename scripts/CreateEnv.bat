REM scripts\CreateEnv.bat
@echo off
chcp 65001 >nul
REM Создаёт .env файл по шаблону из репозитория с актуальными значениями
setlocal enabledelayedexpansion

REM Путь к папке scripts (где лежит этот bat)
set "SCRIPTS_DIR=%~dp0"
if "%SCRIPTS_DIR:~-1%"=="\" set "SCRIPTS_DIR=%SCRIPTS_DIR:~0,-1%"

REM Корень проекта = папка выше scripts
for %%F in ("%SCRIPTS_DIR%\..") do set "ROOT_DIR=%%~fF"

set "REPO_DIR=%ROOT_DIR%\repo"
set "DATA_DIR=%ROOT_DIR%\data"
set "ENV_FILE=%REPO_DIR%\.env"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"

REM ============================================================================
REM   Проверка существования repo
REM ============================================================================
if not exist "%REPO_DIR%" (
    echo [ERROR] Репозиторий не найден: %REPO_DIR%
    echo [ERROR] Сначала клонируйте репозиторий через меню [1]
    pause
    exit /b 1
)

REM ============================================================================
REM   Читаем значения из Config.ini (если есть)
REM ============================================================================
set "CFG_LLM_BACKEND=ollama"
set "CFG_LLM_API_URL=http://127.0.0.1:11434/v1"
set "CFG_AUTH_ENABLED=true"
set "CFG_ADMIN_PASSWORD=admin"
set "CFG_APP_PORT=7000"
set "CFG_SEARXNG_ENABLED=0"
set "CFG_SEARCH_API=none"
set "CFG_SEARCH_API_KEY="

if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_BACKEND=" "%CONFIG_FILE%"') do set "CFG_LLM_BACKEND=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"LLM_API_URL=" "%CONFIG_FILE%"') do set "CFG_LLM_API_URL=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"AUTH_ENABLED=" "%CONFIG_FILE%"') do set "CFG_AUTH_ENABLED=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"ADMIN_PASSWORD=" "%CONFIG_FILE%"') do set "CFG_ADMIN_PASSWORD=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"APP_PORT=" "%CONFIG_FILE%"') do set "CFG_APP_PORT=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARXNG_ENABLED=" "%CONFIG_FILE%"') do set "CFG_SEARXNG_ENABLED=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API=" "%CONFIG_FILE%"') do set "CFG_SEARCH_API=%%b"
    for /f "tokens=1,2 delims==" %%a in ('findstr /B /C:"SEARCH_API_KEY=" "%CONFIG_FILE%"') do set "CFG_SEARCH_API_KEY=%%b"
)

set "CFG_LLM_API_URL=%CFG_LLM_API_URL: =%"
set "CFG_AUTH_ENABLED=%CFG_AUTH_ENABLED: =%"
set "CFG_ADMIN_PASSWORD=%CFG_ADMIN_PASSWORD: =%"
set "CFG_APP_PORT=%CFG_APP_PORT: =%"
set "CFG_SEARXNG_ENABLED=%CFG_SEARXNG_ENABLED: =%"
set "CFG_SEARCH_API=%CFG_SEARCH_API: =%"
set "CFG_SEARCH_API_KEY=%CFG_SEARCH_API_KEY: =%"

if "!CFG_LLM_API_URL!"=="" set "CFG_LLM_API_URL=http://127.0.0.1:11434/v1"
if "!CFG_AUTH_ENABLED!"=="" set "CFG_AUTH_ENABLED=true"
if "!CFG_ADMIN_PASSWORD!"=="" set "CFG_ADMIN_PASSWORD=admin"
if "!CFG_APP_PORT!"=="" set "CFG_APP_PORT=7000"
if "!CFG_SEARXNG_ENABLED!"=="" set "CFG_SEARXNG_ENABLED=0"
if "!CFG_SEARCH_API!"=="" set "CFG_SEARCH_API=none"

REM ============================================================================
REM   Абсолютный путь к БД
REM ============================================================================
set "DB_PATH=%DATA_DIR%\app.db"
set "DB_PATH=%DB_PATH:\=/%"

REM ============================================================================
REM   Создаём .env по шаблону из репозитория
REM ============================================================================
if exist "%ENV_FILE%" del /f /q "%ENV_FILE%" 2>nul

>> "%ENV_FILE%" echo # Odysseus Portable — Environment Configuration
>> "%ENV_FILE%" echo # Generated automatically. Edit via Settings menu or manually.
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # LLM Configuration
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo LLM_HOST=localhost
>> "%ENV_FILE%" echo.

REM OLLAMA_BASE_URL — только если backend ollama
if /I "!CFG_LLM_BACKEND!"=="ollama" (
    >> "%ENV_FILE%" echo OLLAMA_BASE_URL=!CFG_LLM_API_URL!
) else (
    >> "%ENV_FILE%" echo # OLLAMA_BASE_URL=!CFG_LLM_API_URL!
)

>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # LM_STUDIO_URL=http://host.docker.internal:1234
>> "%ENV_FILE%" echo # OPENAI_API_KEY=your_openai_api_key_here
>> "%ENV_FILE%" echo.

if /I "!CFG_LLM_BACKEND!"=="openai" (
    >> "%ENV_FILE%" echo OPENAI_API_KEY=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # OPENAI_API_KEY=
)

>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # Search ^& Web
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.

if "!CFG_SEARXNG_ENABLED!"=="1" (
    >> "%ENV_FILE%" echo SEARXNG_INSTANCE=http://127.0.0.1:8080
) else (
    >> "%ENV_FILE%" echo # SEARXNG_INSTANCE=http://localhost:8080
)

>> "%ENV_FILE%" echo # SEARXNG_SECRET=
>> "%ENV_FILE%" echo.

REM Search API keys
if /I "!CFG_SEARCH_API!"=="brave" (
    >> "%ENV_FILE%" echo DATA_BRAVE_API_KEY=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # DATA_BRAVE_API_KEY=
)

if /I "!CFG_SEARCH_API!"=="tavily" (
    >> "%ENV_FILE%" echo TAVILY_API_KEY=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # TAVILY_API_KEY=
)

if /I "!CFG_SEARCH_API!"=="serper" (
    >> "%ENV_FILE%" echo SERPER_API_KEY=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # SERPER_API_KEY=
)

if /I "!CFG_SEARCH_API!"=="google" (
    >> "%ENV_FILE%" echo GOOGLE_API_KEY=!CFG_SEARCH_API_KEY!
    >> "%ENV_FILE%" echo GOOGLE_PSE_CX=!CFG_SEARCH_API_KEY!
) else (
    >> "%ENV_FILE%" echo # GOOGLE_API_KEY=
    >> "%ENV_FILE%" echo # GOOGLE_PSE_CX=
)

>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # Database
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo DATABASE_URL=sqlite:///%DB_PATH%
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # Data directory
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo ODYSSEUS_DATA_DIR=%DATA_DIR%
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # Auth ^& Security
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo AUTH_ENABLED=!CFG_AUTH_ENABLED!
>> "%ENV_FILE%" echo ODYSSEUS_ADMIN_USER=admin
>> "%ENV_FILE%" echo ODYSSEUS_ADMIN_PASSWORD=!CFG_ADMIN_PASSWORD!
>> "%ENV_FILE%" echo LOCALHOST_BYPASS=false
>> "%ENV_FILE%" echo SECURE_COOKIES=false
>> "%ENV_FILE%" echo ALLOWED_ORIGINS=http://localhost,http://127.0.0.1
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo APP_BIND=127.0.0.1
>> "%ENV_FILE%" echo APP_PORT=!CFG_APP_PORT!
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # ChromaDB (vector store)
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo CHROMADB_HOST=127.0.0.1
>> "%ENV_FILE%" echo CHROMADB_PORT=8100
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # RAG / Embeddings
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # EMBEDDING_URL=http://localhost:11434/v1/embeddings
>> "%ENV_FILE%" echo # EMBEDDING_API_KEY=
>> "%ENV_FILE%" echo # EMBEDDING_MODEL=all-minilm:l6-v2
>> "%ENV_FILE%" echo FASTEMBED_MODEL=sentence-transformers/all-MiniLM-L6-v2
>> "%ENV_FILE%" echo FASTEMBED_CACHE_PATH=%DATA_DIR%\fastembed
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo # Misc
>> "%ENV_FILE%" echo # ============================================================
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo CLEANUP_INTERVAL_HOURS=24
>> "%ENV_FILE%" echo ODYSSEUS_INPROCESS_POLLERS=1
>> "%ENV_FILE%" echo ODYSSEUS_INPROCESS_TASKS=1
>> "%ENV_FILE%" echo ODYSSEUS_SCRIPT_HOST=localhost
>> "%ENV_FILE%" echo.
>> "%ENV_FILE%" echo ODYSSEUS_CHAT_UPLOAD_MAX_BYTES=10485760
>> "%ENV_FILE%" echo ODYSSEUS_GALLERY_UPLOAD_MAX_BYTES=104857600
>> "%ENV_FILE%" echo.
pause
exit /b 0