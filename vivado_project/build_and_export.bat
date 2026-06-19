@echo off
REM build_and_export.bat
REM Run Vivado in batch mode to build and export XSA

cd /d D:\FPGAmoudle\--main\--main\vivado_project

echo ==========================================
echo DDS Signal Generator - Build ^& Export XSA
echo ==========================================

set VIVADO=D:\tools\vivado\2019.2\bin\vivado.bat

echo Opening Vivado project...
%VIVADO% -mode batch -source build_and_export.tcl

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo SUCCESS! Build and export complete.
    echo ==========================================
) else (
    echo.
    echo ==========================================
    echo FAILED! Check output for errors.
    echo ==========================================
)

pause
