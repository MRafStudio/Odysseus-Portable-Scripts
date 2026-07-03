REM scripts\InstallOrUpdate-Repo.bat
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "AUTOCLOSE=0"
if "%1"=="1" set "AUTOCLOSE=1"

title Odysseus — Клонирование / Обновление репозитория

REM ============================================================================
REM   Получение ESC через PowerShell
REM ============================================================================
for /f %%a in ('powershell -NoProfile -Command "Write-Host ([char]27) -NoNewline"') do set "ESC=%%a"

REM ============================================================================
REM   Определение путей
REM ============================================================================
for %%F in ("%~dp0..") do set "ROOT_DIR=%%~fF"
set "REPO_DIR=%ROOT_DIR%\repo"

REM ============================================================================
REM   Изоляция данных
REM ============================================================================
set "DATA_DIR=%ROOT_DIR%\data"
set "TEMP=%DATA_DIR%\temp"
set "HOME=%DATA_DIR%\home"
set "USERPROFILE=%DATA_DIR%\home"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" 2>nul
if not exist "%TEMP%" mkdir "%TEMP%" 2>nul
if not exist "%HOME%" mkdir "%HOME%" 2>nul
if not exist "%HOME%\Desktop" mkdir "%HOME%\Desktop" 2>nul

REM ============================================================================
REM   Проверка глобального Git (ОБЯЗАТЕЛЬНО!)
REM ============================================================================
git --version >nul 2>nul
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Git не найден. Установите Git сначала.%ESC%[0m
    echo   %ESC%[33m       https://git-scm.com/download/win%ESC%[0m
    if "%AUTOCLOSE%"=="0" pause
    exit /b 1
)

cls
echo.
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m##%ESC%[0m            %ESC%[1;37mOdysseus%ESC%[0m   —   %ESC%[1;33mКлонирование / Обновление репозитория%ESC%[0m            %ESC%[1;36m##%ESC%[0m
echo  %ESC%[1;36m##                                                                            ##%ESC%[0m
echo  %ESC%[1;36m################################################################################%ESC%[0m
echo.

REM ============================================================================
REM   Развилка: репозиторий есть или нет
REM ============================================================================
if exist "%REPO_DIR%\.git" goto update_repo
goto clone_repo

REM ============================================================================
REM   ОБНОВЛЕНИЕ СУЩЕСТВУЮЩЕГО РЕПОЗИТОРИЯ
REM ============================================================================
:update_repo
echo   %ESC%[1;33m-%ESC%[0m %ESC%[1mРепозиторий найден. Обновление...%ESC%[0m
echo.

cd /d "%REPO_DIR%"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось перейти в %REPO_DIR%%ESC%[0m
    goto error_exit
)

if not exist ".git" (
    echo   %ESC%[1;31m[ОШИБКА] Не найден .git в %REPO_DIR%%ESC%[0m
    goto error_exit
)

for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%a"
echo   %ESC%[2m       Текущая ветка: !CURRENT_BRANCH!%ESC%[0m

echo.
echo   %ESC%[1;33m[1/3]%ESC%[0m %ESC%[1mПолучение обновлений из origin...%ESC%[0m
git fetch origin
echo   %ESC%[1;32m  +   Обновления получены.%ESC%[0m

echo.
echo   %ESC%[1;33m[2/3]%ESC%[0m %ESC%[1mПереключение на dev...%ESC%[0m
git checkout dev
echo   %ESC%[1;32m  +   На ветке dev.%ESC%[0m

echo.
echo   %ESC%[1;33m[3/3]%ESC%[0m %ESC%[1mСлияние origin/dev → dev...%ESC%[0m
git reset --hard origin/dev

if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[КОНФЛИКТ] Требуется ручное разрешение.%ESC%[0m
    echo   %ESC%[33m       Откройте репозиторий в VS/VCode и разрешите конфликты.%ESC%[0m
    pause
    goto error_exit
)

echo   %ESC%[1;32m  +   Слияние завершено без конфликтов.%ESC%[0m

echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mРепозиторий обновлён.%ESC%[0m
echo   %ESC%[2m       Ветка: dev%ESC%[0m
echo   %ESC%[2m       origin/dev: актуален%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m

goto success_exit

REM ============================================================================
REM   КЛОНИРОВАНИЕ РЕПОЗИТОРИЯ
REM ============================================================================
:clone_repo
echo   %ESC%[1;33m[1/2]%ESC%[0m %ESC%[1mКлонирование pewdiepie-archdaemon/odysseus...%ESC%[0m
echo   %ESC%[2m       Ветка: dev (рабочая)%ESC%[0m
echo   %ESC%[2m       ~50 МБ (исходный код)%ESC%[0m

if exist "%REPO_DIR%" rmdir /s /q "%REPO_DIR%"
mkdir "%REPO_DIR%" 2>nul

git clone --branch dev --single-branch https://github.com/pewdiepie-archdaemon/odysseus.git "%REPO_DIR%"
if !errorlevel! neq 0 (
    echo   %ESC%[1;31m[ОШИБКА] Не удалось клонировать репозиторий.%ESC%[0m
    goto error_exit
)

echo   %ESC%[1;32m  +   Репозиторий клонирован.%ESC%[0m

cd /d "%REPO_DIR%"

echo.
echo   %ESC%[1;33m[2/2]%ESC%[0m %ESC%[1mПроверка ветки dev...%ESC%[0m

for /f "tokens=*" %%a in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%a"
echo   %ESC%[1;32m  +   Текущая ветка: !CURRENT_BRANCH!%ESC%[0m

echo   %ESC%[2m       origin:  https://github.com/pewdiepie-archdaemon/odysseus.git%ESC%[0m
echo   %ESC%[2m       Ветка: dev (рабочая)%ESC%[0m

echo.
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m
echo   %ESC%[1;32mКлонирование завершено.%ESC%[0m
echo   %ESC%[2m       Рабочая ветка: dev%ESC%[0m
echo   %ESC%[2m       Не забудьте: все правки коммить в dev.%ESC%[0m
echo  %ESC%[36m────────────────────────────────────────────────────────────────────────────────%ESC%[0m

goto success_exit

REM ============================================================================
REM   ВЫХОДЫ
REM ============================================================================
:error_exit
if "%AUTOCLOSE%"=="1" (
    call "%~dp0SmartPause.bat"
) else (
    pause
)
exit /b 1

:success_exit
if "%AUTOCLOSE%"=="1" (
    call "%~dp0SmartPause.bat"
) else (
    pause
)
exit /b 0