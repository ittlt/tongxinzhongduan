# CLAUDE.md — DDS信号发生器项目

## 项目概述

基于FPGA的DDS（直接数字频率合成）信号发生器，支持正弦波/方波/三角波生成，频率可通过按键或UART串口控制。

**目标平台**：DE2开发板（Cyclone II FPGA），50MHz晶振，8位DAC输出
**仿真工具**：ModelSim 2020.4（Windows，通过WSL调用）

## 目录结构

```
├── rtl/                        # RTL源码
│   ├── DDS_Core.v              # DDS核心：相位累加器 + 正弦LUT + 方波/三角波生成
│   ├── Key_Control.v           # 按键消抖（延时消抖） + 频率/波形控制
│   ├── UART_Parse.v            # UART接收（9600bps） + 指令解析 → FCW
│   └── DDS_Signal_Generator.v  # 系统顶层：PLL + 按键 + UART + DDS + 频率选择
├── tb/
│   └── tb_DDS_Signal_Generator.v  # 仿真测试台（含行为级PLL模型）
├── sim/
│   ├── run_sim.sh              # WSL一键仿真脚本（推荐）
│   └── run_sim_win.do          # ModelSim GUI脚本（Windows直接用）
├── DDS_top.v                   # 原始单文件（历史参考，不参与编译）
└── .gitignore
```

## 模块层次

```
DDS_Signal_Generator (顶层)
├── pll_50m_to_100m      (Quartus PLL IP，仿真中用行为模型替代)
├── Key_Control           (按键消抖 + FCW/wave_sel)
├── UART_Parse            (UART接收 + FCW计算)
└── DDS_Core              (相位累加 + 波形查找表 + 输出选择)
```

## 关键参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 系统时钟 | 100MHz（PLL倍频自50MHz） | 相位累加器时钟 |
| 相位累加器 | 32位 | 频率精度 = 100MHz/2^32 ≈ 0.023Hz |
| DAC输出 | 8位（0~255） | 正弦波LUT 256点 |
| 默认FCW | 10737418 | 对应100kHz |
| FCW步进 | 107374 | 对应1kHz（按键Freq+/-） |
| UART波特率 | 9600bps, 8N1 | 指令格式：'F'+6位ASCII频率(Hz) |
| 消抖时间 | 10ms (1_000_000周期@100MHz) | 4个按键独立消抖 |

## 仿真方法

### WSL下运行（推荐）

```bash
bash sim/run_sim.sh
```

自动完成：编译RTL → 编译TB → 启动仿真 → 打印测试结果。输出到stdout。

### Windows ModelSim GUI

```cmd
D:\modelsim2020\modeltech64_2020.4\win64\vsim.exe -do sim\run_sim_win.do
```

打开波形窗口，可手动添加信号、缩放查看。

### 测试用例

| 测试 | 内容 | 验证点 |
|------|------|--------|
| TEST1 | 默认正弦波 | phase_acc递增，sin_lut正确，dds_out≈128±127 |
| TEST2 | 按键切换方波 | wave_sel=01，dds_out=0或255 |
| TEST3 | 按键切换三角波 | wave_sel=10，dds_out线性递增/递减 |
| TEST4 | Freq+增加频率 | FCW从10737418增加到10844792 |
| TEST5 | UART F200000 | fcw_uart=8589934，fcw_sel锁定 |
| TEST6 | 复位 | FCW恢复10737418，wave_sel恢复00 |

## UART指令格式

```
格式：'F' + 6位ASCII数字（频率单位Hz）
示例：F200000 → 200kHz, F001000 → 1kHz, F000500 → 500Hz
范围：0 ~ 999999 Hz
```

字节序列（十六进制）：`46 3x 3x 3x 3x 3x 3x`（3x为ASCII数字0-9）

## 开发注意事项

### RTL编码规范
- 时钟沿触发统一用 `posedge clk or negedge rst_n`
- 非阻塞赋值（`<=`）用于时序逻辑，阻塞赋值（`=`）仅用于组合逻辑
- 同一always块中对同一reg多次非阻塞赋值时，**最后一个生效**（易引发隐式覆盖bug）
- 正弦LUT用 `initial` 块初始化（综合工具会转为ROM）

### 已知设计限制
- UART指令中十位和个位使用同一字节（uart_data），对非整十频率有微小误差
- PLL IP核（pll_50m_to_100m）需在Quartus中生成，仿真用行为模型替代
- 按键消抖时间10ms，仿真中需等待>10ms才能触发第二次按键

### Git工作流
- `main`：主分支，稳定版本
- `dev-dds-refactor`：开发分支
- 提交前运行仿真确认全部通过
- 推送到 https://github.com/ittlt/-.git

## FCW计算公式

```
FCW = freq × 2^32 / 100_000_000
```

UART解析中的权重（6位数字 d0~d5）：
```
d0(十万位) × 4294967 + d1(万位) × 429497 + d2(千位) × 42950
+ d3(百位) × 4295 + d4(十位) × 429 + d5(个位) × 43
```

## 快速上手

```bash
# 克隆仓库
git clone https://github.com/ittlt/-.git
cd -

# 运行仿真（WSL）
bash sim/run_sim.sh

# 查看波形（如有GTKWave）
gtkwave wave.vcd
```
