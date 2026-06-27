@echo off
REM create_pl_project.bat
REM Create pure PL Vivado project

cd /d D:\FPGAmoudle\--main\--main\vivado_project_pl_only

echo ==========================================
echo Creating Pure PL Project
echo ==========================================

set VIVADO=D:\tools\vivado\2019.2\bin\vivado.bat

%VIVADO% -mode batch -source create_pl_project.tcl

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo SUCCESS! Pure PL project created.
    echo ==========================================
    echo Project: DDS_Signal_Generator_PL.xpr
) else (
    echo.
    echo ==========================================
    echo FAILED! Check output for errors.
    echo ==========================================
)

pause
