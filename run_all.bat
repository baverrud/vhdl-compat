@echo off
REM run_all.bat — Thin wrapper around scripts/run_all.py
REM
REM Usage:  run_all.bat [--skip-synth] [--tool vivado]
REM
REM All logic is in scripts/run_all.py — this just calls it.
REM Logs are saved to tmp/run_all_{timestamp}.log
REM ============================================================================
setlocal enabledelayedexpansion

cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo ERROR: Python venv not found. Run: python -m venv .venv ^&^& .venv\Scripts\pip install -e .
    exit /b 1
)

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list 2^>nul') do set DT=%%I
if defined DT (set TS=!DT:~0,8!_!DT:~8,6!) else (set TS=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%& set TS=!TS: =0!)
if not exist tmp mkdir tmp
set LOGFILE=tmp\run_all_%TS%.log

.venv\Scripts\python.exe scripts/run_all.py %* 2>&1 | powershell -Command "Tee-Object -FilePath '%LOGFILE%'"
echo.
echo Log: %LOGFILE%
echo To skip synth: run_all.bat --skip-synth

endlocal
