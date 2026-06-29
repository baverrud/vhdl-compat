@echo off
REM ============================================================================
REM run_all.bat — Run the full VHDL compatibility test suite across all tools
REM
REM Usage:  run_all.bat [--skip-synth]
REM
REM Options:
REM   --skip-synth   Skip Vivado synthesis tests (saves ~45 min)
REM
REM Runs Questa, ModelSim, and Vivado for all standards, then generates
REM the final MATRIX.md. Logs are saved to tmp/run_all_{timestamp}.log
REM ============================================================================
setlocal enabledelayedexpansion

set PROJECT_ROOT=%~dp0
cd /d "%PROJECT_ROOT%"

REM --- Timestamp ---
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list 2^>nul') do set DT=%%I
if defined DT (
    set TS=!DT:~0,8!_!DT:~8,6!
) else (
    set TS=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set TS=!TS: =0!
)
set LOGFILE=tmp\run_all_%TS%.log
if not exist tmp mkdir tmp

echo ============================================================================
echo VHDL Compatibility Test Suite - Full Run
echo Started: %date% %time%
echo Log:     %LOGFILE%
echo ============================================================================
echo.

REM --- Check prerequisites ---
if not exist ".venv\Scripts\python.exe" (
    echo ERROR: Python venv not found at .venv\Scripts\python.exe
    echo Run: python -m venv .venv ^&^& .venv\Scripts\pip install -e .
    exit /b 1
)

REM --- Detect installed tools ---
echo [1/6] Detecting installed tools...
.venv\Scripts\python.exe scripts/run_tests.py --detect 1>>"%LOGFILE%" 2>&1
if %ERRORLEVEL% neq 0 echo   WARNING: Tool detection had issues ^(see log^)
echo.

REM --- Questa Simulation (all installed versions) ---
echo [2/6] Questa simulation ^(all installed versions^)...
echo ===== Questa sim start ===== >> "%LOGFILE%"
for %%v in (2025.3) do (
    echo   Running Questa %%v sim...
    .venv\Scripts\python.exe scripts/run_tests.py --tool questa --version %%v --std 2000 --std 2002 --std 2008 --std 2019 --mode sim --verbose 1>>"%LOGFILE%" 2>&1
    if !ERRORLEVEL! neq 0 echo   WARNING: Questa %%v sim had failures ^(see log^)
)
echo.

REM --- ModelSim Simulation (all installed versions) ---
echo [3/6] ModelSim simulation ^(all installed versions^)...
echo ===== ModelSim sim start ===== >> "%LOGFILE%"
for %%v in (2020.1) do (
    echo   Running ModelSim %%v sim...
    .venv\Scripts\python.exe scripts/run_tests.py --tool modelsim --version %%v --std 2000 --std 2002 --std 2008 --std 2019 --mode sim --verbose 1>>"%LOGFILE%" 2>&1
    if !ERRORLEVEL! neq 0 echo   WARNING: ModelSim %%v sim had failures ^(see log^)
)
echo.

REM --- Vivado Simulation (all installed versions) ---
echo [4/6] Vivado simulation ^(all installed versions^)...
echo ===== Vivado sim start ===== >> "%LOGFILE%"
for %%v in (2023.2 2026.1) do (
    echo   Running Vivado %%v sim...
    .venv\Scripts\python.exe scripts/run_tests.py --tool vivado --version %%v --std 2000 --std 2002 --std 2008 --std 2019 --mode sim --verbose 1>>"%LOGFILE%" 2>&1
    if !ERRORLEVEL! neq 0 echo   WARNING: Vivado %%v sim had failures ^(see log^)
)
echo.

REM --- Vivado Synthesis (optional, all installed versions) ---
set SKIP_SYNTH=0
if "%1"=="--skip-synth" set SKIP_SYNTH=1

if "%SKIP_SYNTH%"=="0" (
    echo [5/6] Vivado synthesis ^(all installed versions^)...
    echo   NOTE: Each version takes ~30-45 minutes
    echo ===== Vivado synth start ===== >> "%LOGFILE%"
    for %%v in (2023.2 2026.1) do (
        echo   Running Vivado %%v synth...
        .venv\Scripts\python.exe scripts/run_tests.py --tool vivado --version %%v --std 2008 --std 2019 --mode synth --verbose 1>>"%LOGFILE%" 2>&1
        if !ERRORLEVEL! neq 0 echo   WARNING: Vivado %%v synth had failures ^(see log^)
    )
) else (
    echo [5/6] SKIPPING Vivado synthesis ^(--skip-synth^)
)
echo.

REM --- Generate Matrix ---
echo [6/6] Generating MATRIX.md...
echo ===== Matrix generation ===== >> "%LOGFILE%"
.venv\Scripts\python.exe scripts/generate_matrix.py 2>>"%LOGFILE%"
if %ERRORLEVEL% neq 0 echo   ERROR: Matrix generation failed^^!
echo.

REM --- Summary ---
echo ============================================================================
echo Complete^^!
echo Log:     %LOGFILE%
echo Matrix:  MATRIX.md
echo ============================================================================
echo.

REM Extract summary from log
echo Quick summary:
echo.
echo Questa sim results:
findstr /C:"Results:" "%LOGFILE%" | findstr /I "questa" 2>nul
echo.
echo ModelSim sim results:
findstr /C:"Results:" "%LOGFILE%" | findstr /I "modelsim" 2>nul
echo.
echo Vivado sim results:
findstr /C:"Results:" "%LOGFILE%" | findstr /I "vivado.*sim" 2>nul
echo.
echo Vivado synth results:
findstr /C:"Results:" "%LOGFILE%" | findstr /I "vivado.*synth" 2>nul
echo.
echo For full details: type "%LOGFILE%"
echo To skip synth next time: run_all.bat --skip-synth

endlocal
