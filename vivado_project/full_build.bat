@echo off
REM full_build.bat
REM Complete build: Add sources → PS BD → Synthesize → Implement → Bitstream → XSA

cd /d D:\FPGAmoudle\--main\--main\vivado_project

echo ==========================================
echo DDS Signal Generator - Full Build
echo ==========================================

set VIVADO=D:\tools\vivado\2019.2\bin\vivado.bat

echo Starting Vivado...
%VIVADO% -mode batch -source full_build.tcl

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo SUCCESS! Build complete.
    echo ==========================================
    echo XSA file: DDS_Signal_Generator_wrapper.xsa
) else (
    echo.
    echo ==========================================
    echo FAILED! Check output for errors.
    echo ==========================================
)

pause
