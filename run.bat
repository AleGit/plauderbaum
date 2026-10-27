@echo off
setlocal
cd /d "%~dp0"
title Plauderbaum

set "WITH_CURSOR=0"
if /i "%~1"=="--with-cursor" set "WITH_CURSOR=1"
if not "%~1"=="" if not "%WITH_CURSOR%"=="1" (
    echo Unknown option: %~1
    echo Usage: run.bat [--with-cursor]
    pause
    exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
    echo First start: setting up. This takes a minute...
    py -3 -m venv .venv
    if errorlevel 1 goto fail
)

rem Install the dependencies on first start and whenever requirements.txt has changed.
fc /b requirements.txt ".venv\requirements.installed" >nul 2>&1
if errorlevel 1 (
    echo Installing dependencies...
    ".venv\Scripts\python.exe" -m pip install --quiet --disable-pip-version-check --require-hashes -r requirements.txt
    if errorlevel 1 goto fail
    copy /y requirements.txt ".venv\requirements.installed" >nul
)

if "%WITH_CURSOR%"=="1" (
    if not exist ".venv" mkdir ".venv"
    type nul > ".venv\cursor.enabled"
)

rem Optional Cursor agent: installed only when enabled, never by the default start.
if exist ".venv\cursor.enabled" (
    fc /b requirements-cursor.txt ".venv\requirements-cursor.installed" >nul 2>&1
    if errorlevel 1 (
        echo Installing optional Cursor support...
        ".venv\Scripts\python.exe" -m pip install --quiet --disable-pip-version-check --require-hashes -r requirements.txt -r requirements-cursor.txt
        if errorlevel 1 goto cursor_fail
        copy /y requirements-cursor.txt ".venv\requirements-cursor.installed" >nul
    )
)

".venv\Scripts\python.exe" -m tutor
if errorlevel 1 pause
exit /b

:fail
echo.
echo Setup failed. Delete the .venv folder and try again.
pause
exit /b 1

:cursor_fail
echo.
echo Could not install Cursor support. Delete the .venv folder and try again,
echo or start without --with-cursor.
pause
exit /b 1
