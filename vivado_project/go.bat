@echo off
set VITIS=D:\tools\Vitis\2019.2\bin
set DIR=D:\FPGAmoudle\--main\--main\vivado_project

echo Phase 1: Clean workspace
if exist "%DIR%\vitis_workspace" rmdir /s /q "%DIR%\vitis_workspace"

echo Phase 2: Run xsct to build FSBL
"%VITIS%\xsct.bat" %DIR%\go_xsct.tcl
if errorlevel 1 goto :err

echo Phase 3: Generate BOOT.BIN
"%VITIS%\bootgen.bat" -w -arch zynq -o %DIR%\BOOT.BIN -bif %DIR%\boot_auto.bif
if errorlevel 1 goto :err
if not exist "%DIR%\BOOT.BIN" goto :err

echo Phase 4: Flash programming
"%VITIS%\xsct.bat" %DIR%\go_flash.tcl

echo DONE
pause
exit /b 0

:err
echo FAILED
pause
exit /b 1
