@echo off
REM ============================================================
REM run_xsct.bat - 生成 FSBL + BOOT.BIN 并烧录 Flash
REM 用法：在 Windows CMD 中直接双击或运行此脚本
REM ============================================================

set VITIS_BIN=D:\tools\Vitis\2019.2\bin
set PROJ_DIR=D:\FPGAmoudle\--main\--main\vivado_project
set XSA_FILE=%PROJ_DIR%\DDS_Signal_Generator_wrapper.xsa
set BIT_FILE=%PROJ_DIR%\DDS_Signal_Generator.runs\impl_1\DDS_Signal_Generator_top.bit
set WORKSPACE=%PROJ_DIR%\vitis_workspace

echo ============================================================
echo Phase 1: 清理旧工作空间
echo ============================================================
if exist "%WORKSPACE%" rmdir /s /q "%WORKSPACE%"

echo ============================================================
echo Phase 2: 用 xsct 生成硬件平台和 FSBL
echo ============================================================

REM 创建 xsct TCL 脚本
echo setws %WORKSPACE% > %PROJ_DIR%\xsct_temp.tcl
echo platform create -name "hw_platform" -hw %XSA_FILE% >> %PROJ_DIR%\xsct_temp.tcl
echo platform generate >> %PROJ_DIR%\xsct_temp.tcl
echo app create -name "fsbl" -hw hw_platform -proc ps7_cortexa9_0 -os standalone -lang c -template "Zynq FSBL" >> %PROJ_DIR%\xsct_temp.tcl
echo bsp regenerate >> %PROJ_DIR%\xsct_temp.tcl
echo app build -name "fsbl" >> %PROJ_DIR%\xsct_temp.tcl
echo puts "INFO: FSBL build complete" >> %PROJ_DIR%\xsct_temp.tcl

echo 正在运行 xsct...
"%VITIS_BIN%\xsct.bat" %PROJ_DIR%\xsct_temp.tcl
if errorlevel 1 (
    echo ERROR: xsct 执行失败
    pause
    exit /b 1
)

echo ============================================================
echo Phase 3: 用 bootgen 生成 BOOT.BIN
echo ============================================================

REM 创建 BIF 文件
echo the_ROM_image: > %PROJ_DIR%\boot_auto.bif
echo { >> %PROJ_DIR%\boot_auto.bif
echo     [bootloader] %WORKSPACE%\hw_platform\zynq_fsbl\Debug\fsbl.elf >> %PROJ_DIR%\boot_auto.bif
echo     %BIT_FILE% >> %PROJ_DIR%\boot_auto.bif
echo } >> %PROJ_DIR%\boot_auto.bif

echo 正在生成 BOOT.BIN...
"%VITIS_BIN%\bootgen.bat" -w -arch zynq -o %PROJ_DIR%\BOOT.BIN -bif %PROJ_DIR%\boot_auto.bif
if errorlevel 1 (
    echo ERROR: bootgen 失败
    pause
    exit /b 1
)

if not exist "%PROJ_DIR%\BOOT.BIN" (
    echo ERROR: BOOT.BIN 未生成
    pause
    exit /b 1
)

echo BOOT.BIN 生成成功: %PROJ_DIR%\BOOT.BIN

echo ============================================================
echo Phase 4: 烧录 Flash（通过 xsct）
echo ============================================================

REM 创建烧录脚本
echo connect > %PROJ_DIR%\flash_temp.tcl
echo targets -filter {name =~ "xc7z*"} >> %PROJ_DIR%\flash_temp.tcl
echo fpga -filter {name =~ "xc7z*"} %BIT_FILE% >> %PROJ_DIR%\flash_temp.tcl
echo con >> %PROJ_DIR%\flash_temp.tcl
echo after 2000 >> %PROJ_DIR%\flash_temp.tcl
echo stop >> %PROJ_DIR%\flash_temp.tcl
echo targets -set -nocase -filter {name =~ "*QSPI*"} >> %PROJ_DIR%\flash_temp.tcl
echo spi_flash -auto_detect >> %PROJ_DIR%\flash_temp.tcl
echo program_flash -file %PROJ_DIR%\BOOT.BIN -offset 0 -force >> %PROJ_DIR%\flash_temp.tcl
echo disconnect >> %PROJ_DIR%\flash_temp.tcl
echo exit >> %PROJ_DIR%\flash_temp.tcl

echo 正在烧录 Flash...
"%VITIS_BIN%\xsct.bat" %PROJ_DIR%\flash_temp.tcl

echo ============================================================
echo 完成！请断开 JTAG，重新上电验证
echo ============================================================
pause
