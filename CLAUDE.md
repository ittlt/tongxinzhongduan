# DDS Signal Generator - Zynq-7010

## 项目概述

基于 Xilinx Zynq-7010 (xc7z010clg400-1) 的 DDS 信号发生器项目，支持正弦波、方波、三角波生成，通过 UART 接口接收频率控制字，使用 8 位 DAC 输出。

## 硬件平台

- **FPGA**: Xilinx Zynq-7010 (xc7z010clg400-1)
- **开发板**: 皓月 ZYNQ 开发板
- **Flash**: W25Q128JV QSPI (16MB)
- **DDR3**: 2x MT41K256M16 (1GB, 32-bit)
- **工具**: Vivado 2019.2 / Vitis 2019.2

## 项目结构

```
├── rtl/                              # RTL 源文件
│   ├── DDS_Core.v                   # DDS 核心（相位累加 + 波形查找表）
│   ├── DDS_Signal_Generator.v       # 主模块（纯 PL 版本，含 ILA）
│   ├── DDS_Signal_Generator_top.v   # PS+PL 顶层包装
│   ├── HMI_Recv.v                   # UART 接收模块
│   ├── HMI_UARTX.v                  # UART 发送模块
│   ├── HMI_UARX.v                   # UART 接收底层
│   └── Key_Control.v               # 按键控制（频率调节、波形切换）
├── vivado_project/                  # PS+PL 工程（用于固化到 Flash）
│   ├── DDS_Signal_Generator.xpr    # Vivado 工程文件
│   ├── create_ps_bd.tcl            # PS Block Design 创建脚本
│   ├── full_build.tcl              # 完整构建脚本
│   └── DDS_Signal_Generator_wrapper.xsa  # 硬件导出文件
├── vivado_project_pl_only/          # 纯 PL 工程（含 ILA 调试）
│   ├── DDS_Signal_Generator_PL/    # Vivado 工程目录
│   ├── rtl/                        # RTL 源文件副本
│   └── DDS_Signal_Generator.xdc   # 约束文件
└── CLAUDE.md                       # 本文件
```

## 功能模块

### DDS 核心 (DDS_Core.v)
- 32 位相位累加器
- 支持正弦波、方波、三角波
- 8 位 DAC 输出
- 100MHz 系统时钟（PLL 从 50MHz 生成）

### 键盘控制 (Key_Control.v)
- 3 个按键：频率增加、频率减少、波形切换
- 频率控制字 (FCW) 调节
- 波形选择：SIN(00) / SQU(01) / TRI(10)

### UART 接口 (HMI_Recv.v / HMI_UARTX.v)
- 波特率：115200
- 接收：32 位频率控制字
- 发送：当前波形类型 + 频率值（BCD 格式）

### PS Block Design (zynq_ps)
- DDR3 内存控制器
- QSPI Flash 控制器
- FCLK_CLK0 = 50MHz（提供给 PL）
- FCLK_RESET0_N（系统复位）

## 引脚分配

### PL 端引脚
| 引脚 | 端口 | 说明 |
|------|------|------|
| N18 | clk_50mhz | 50MHz 时钟（纯 PL 版本） |
| G19 | rst_n | 系统复位（纯 PL 版本） |
| U17 | dds_clk | DDS 输出时钟 |
| P15 | dds_out[7] | DAC 数据位 7 |
| P16 | dds_out[6] | DAC 数据位 6 |
| P14 | dds_out[5] | DAC 数据位 5 |
| R14 | dds_out[4] | DAC 数据位 4 |
| V16 | dds_out[3] | DAC 数据位 3 |
| W16 | dds_out[2] | DAC 数据位 2 |
| R16 | dds_out[1] | DAC 数据位 1 |
| R17 | dds_out[0] | DAC 数据位 0 |
| G20 | key_in[0] | 频率增加按键 |
| H15 | key_in[1] | 频率减少按键 |
| G15 | key_in[2] | 波形切换按键 |
| B20 | uart_rx | UART 接收 |
| C20 | uart_tx | UART 发送 |
| J14 | led_sys | 系统指示灯（PLL 锁定） |
| K19 | led_uart | UART 指示灯 |

## 构建流程

### PS+PL 版本（用于 Flash 固化）
```bash
# 完整构建（包含 PS Block Design）
cmd.exe /c "vivado_project\full_build.bat"
```

### 纯 PL 版本（用于 ILA 调试）
```bash
# 创建工程
cmd.exe /c "vivado_project_pl_only\create_pl_project.bat"

# 在 Vivado 中打开工程进行综合实现
# 工程文件：vivado_project_pl_only/DDS_Signal_Generator_PL/DDS_Signal_Generator_PL.xpr
```

## ILA 调试配置

纯 PL 版本包含 ILA 调试核心，监控以下信号：
| 探针 | 信号 | 位宽 | 说明 |
|------|------|------|------|
| probe0 | dds_out | 8-bit | DDS 输出数据 |
| probe1 | fcw_sel | 32-bit | 当前频率控制字 |
| probe2 | fcw_uart | 32-bit | UART 接收的频率控制字 |

## 固化到 Flash

1. 生成 XSA 文件：`vivado_project/DDS_Signal_Generator_wrapper.xsa`
2. 使用 Vitis 生成 FSBL
3. 使用 bootgen 生成 BOOT.BIN
4. 通过 Vivado Hardware Manager 或 XSCT 烧录到 QSPI Flash

## 技术要点

- **PLL 配置**: 50MHz → 100MHz（使用 clk_wiz IP）
- **QSPI 配置**: MIO 1..6，Quad-SPI 模式
- **DDR3 配置**: 1GB，32-bit 总线，MT41K256M16 RE-125
- **ILA 配置**: 4096 采样深度，3 个探针

## 常见问题

1. **PLL IP 缺失**: 运行 `add_pll_ip.tcl` 创建
2. **BD 名称冲突**: 删除旧的 BD 目录后重新创建
3. **QSPI 配置错误**: DDR3 参数必须在 QSPI 之前配置
4. **XSA 导出失败**: 确保综合实现完成后再导出
