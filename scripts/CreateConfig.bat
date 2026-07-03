@REM CreateConfig.bat — Создание Config.ini для Odysseus Portable
@echo off
setlocal enabledelayedexpansion

for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "SCRIPTS_DIR=%ROOT_DIR%\scripts"
set "CONFIG_FILE=%SCRIPTS_DIR%\Config.ini"

REM ============================================================================
REM   Параметры с дефолтами (9 параметров максимум в batch)
REM ============================================================================
set "LLM_BACKEND=%~1"
set "OLLAMA_URL=%~2"
set "AUTH_ENABLED=%~3"
set "ADMIN_PASSWORD=%~4"
set "APP_PORT=%~5"
set "AUTO_OPEN_BROWSER=%~6"
set "SEARXNG_ENABLED=%~7"
set "SEARCH_API=%~8"
set "SEARCH_API_KEY=%~9"

if "!LLM_BACKEND!"=="" set "LLM_BACKEND=ollama"
if "!OLLAMA_URL!"=="" set "OLLAMA_URL=http://127.0.0.1:11434/v1"
if "!AUTH_ENABLED!"=="" set "AUTH_ENABLED=true"
if "!ADMIN_PASSWORD!"=="" set "ADMIN_PASSWORD=admin"
if "!APP_PORT!"=="" set "APP_PORT=7000"
if "!AUTO_OPEN_BROWSER!"=="" set "AUTO_OPEN_BROWSER=1"
if "!SEARXNG_ENABLED!"=="" set "SEARXNG_ENABLED=0"
if "!SEARCH_API!"=="" set "SEARCH_API=none"
if "!SEARCH_API_KEY!"=="" set "SEARCH_API_KEY="

REM Очищаем файл если существует
if exist "%CONFIG_FILE%" del /f /q "%CONFIG_FILE%" 2>nul

REM ============================================================================
REM   Пишем Config.ini построчно (вне блока, чтобы скобки не ломали)
REM ============================================================================
>> "%CONFIG_FILE%" echo ; Odysseus Portable — Configuration
>> "%CONFIG_FILE%" echo ; ================================
>> "%CONFIG_FILE%" echo ; Редактируйте через меню [2] Settings или вручную
>> "%CONFIG_FILE%" echo.
>> "%CONFIG_FILE%" echo ; --- LLM Configuration ---
>> "%CONFIG_FILE%" echo LLM_BACKEND=!LLM_BACKEND!
>> "%CONFIG_FILE%" echo OLLAMA_URL=!OLLAMA_URL!
>> "%CONFIG_FILE%" echo.
>> "%CONFIG_FILE%" echo ; --- Auth ^& Security ---
>> "%CONFIG_FILE%" echo AUTH_ENABLED=!AUTH_ENABLED!
>> "%CONFIG_FILE%" echo ADMIN_PASSWORD=!ADMIN_PASSWORD!
>> "%CONFIG_FILE%" echo APP_PORT=!APP_PORT!
>> "%CONFIG_FILE%" echo AUTO_OPEN_BROWSER=!AUTO_OPEN_BROWSER!
>> "%CONFIG_FILE%" echo.
>> "%CONFIG_FILE%" echo ; --- Web Search ---
>> "%CONFIG_FILE%" echo SEARXNG_ENABLED=!SEARXNG_ENABLED!
>> "%CONFIG_FILE%" echo SEARCH_API=!SEARCH_API!
>> "%CONFIG_FILE%" echo SEARCH_API_KEY=!SEARCH_API_KEY!
>> "%CONFIG_FILE%" echo.
>> "%CONFIG_FILE%" echo ; --- Internal (не менять вручную) ---
>> "%CONFIG_FILE%" echo CHROMADB_HOST=127.0.0.1
>> "%CONFIG_FILE%" echo CHROMADB_PORT=8100

exit /b 0