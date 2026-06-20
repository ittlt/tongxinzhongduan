#!/usr/bin/env python3
"""Generate system block diagram for DDS Signal Generator."""

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Create figure
fig, ax = plt.subplots(1, 1, figsize=(12, 8))
ax.set_xlim(0, 12)
ax.set_ylim(0, 8)
ax.axis('off')

# Title
ax.text(6, 7.5, 'DDS Signal Generator System Block Diagram',
        fontsize=16, fontweight='bold', ha='center', va='center')

# Zynq SoC outer box
zynq_box = patches.FancyBboxPatch((0.5, 0.5), 11, 6.5,
                                   boxstyle="round,pad=0.1",
                                   linewidth=2, edgecolor='navy',
                                   facecolor='lightblue', alpha=0.3)
ax.add_patch(zynq_box)
ax.text(6, 6.8, 'Zynq-7010 SoC', fontsize=14, fontweight='bold',
        ha='center', va='center', color='navy')

# PS Box
ps_box = patches.FancyBboxPatch((1, 5.5), 10, 1.2,
                                 boxstyle="round,pad=0.1",
                                 linewidth=1.5, edgecolor='darkgreen',
                                 facecolor='lightgreen', alpha=0.5)
ax.add_patch(ps_box)
ax.text(6, 6.1, 'PS (Processing System) - Dual Core ARM Cortex-A9',
        fontsize=11, fontweight='bold', ha='center', va='center', color='darkgreen')
ax.text(6, 5.7, 'UART Communication Control | System Management',
        fontsize=9, ha='center', va='center', color='darkgreen')

# AXI Interface arrow
ax.annotate('', xy=(6, 5.5), xytext=(6, 5.3),
            arrowprops=dict(arrowstyle='<->', color='red', lw=2))
ax.text(7.5, 5.4, 'AXI Interface', fontsize=9, color='red', fontweight='bold')

# PL Box
pl_box = patches.FancyBboxPatch((1, 1), 10, 4.2,
                                 boxstyle="round,pad=0.1",
                                 linewidth=1.5, edgecolor='darkblue',
                                 facecolor='lightyellow', alpha=0.5)
ax.add_patch(pl_box)
ax.text(6, 4.9, 'PL (Programmable Logic)', fontsize=12, fontweight='bold',
        ha='center', va='center', color='darkblue')

# Key Control Box
key_box = patches.FancyBboxPatch((1.5, 3.2), 3, 1.3,
                                  boxstyle="round,pad=0.1",
                                  linewidth=1, edgecolor='purple',
                                  facecolor='lavender', alpha=0.7)
ax.add_patch(key_box)
ax.text(3, 3.95, 'Key Control', fontsize=10, fontweight='bold',
        ha='center', va='center', color='purple')
ax.text(3, 3.55, 'Debounce | Freq/Wave Control', fontsize=8,
        ha='center', va='center', color='purple')

# UART Parse Box
uart_box = patches.FancyBboxPatch((7.5, 3.2), 3, 1.3,
                                   boxstyle="round,pad=0.1",
                                   linewidth=1, edgecolor='brown',
                                   facecolor='peachpuff', alpha=0.7)
ax.add_patch(uart_box)
ax.text(9, 3.95, 'UART Parse', fontsize=10, fontweight='bold',
        ha='center', va='center', color='brown')
ax.text(9, 3.55, 'UART Rx | Instruction Parse', fontsize=8,
        ha='center', va='center', color='brown')

# DDS Core Box
dds_box = patches.FancyBboxPatch((3.5, 1.5), 5, 1.3,
                                  boxstyle="round,pad=0.1",
                                  linewidth=1.5, edgecolor='red',
                                  facecolor='mistyrose', alpha=0.7)
ax.add_patch(dds_box)
ax.text(6, 2.2, 'DDS Core', fontsize=11, fontweight='bold',
        ha='center', va='center', color='red')
ax.text(6, 1.8, 'Phase Accumulator + Waveform LUT + Wave Selection',
        fontsize=8, ha='center', va='center', color='red')

# Output Box
out_box = patches.FancyBboxPatch((7.5, 0.8), 3, 0.8,
                                  boxstyle="round,pad=0.1",
                                  linewidth=1, edgecolor='orange',
                                  facecolor='lightyellow', alpha=0.7)
ax.add_patch(out_box)
ax.text(9, 1.2, 'dds_out[7:0]', fontsize=10, fontweight='bold',
        ha='center', va='center', color='orange')

# Arrows
# Key to DDS
ax.annotate('', xy=(5, 2.15), xytext=(3.5, 3.2),
            arrowprops=dict(arrowstyle='->', color='purple', lw=1.5))

# UART to DDS
ax.annotate('', xy=(7, 2.15), xytext=(7.5, 3.2),
            arrowprops=dict(arrowstyle='->', color='brown', lw=1.5))

# DDS to Output
ax.annotate('', xy=(7.5, 1.2), xytext=(7, 1.8),
            arrowprops=dict(arrowstyle='->', color='orange', lw=1.5))

# Input labels on left
ax.text(0.3, 4.5, 'Inputs:', fontsize=9, fontweight='bold', ha='right')
ax.text(0.3, 4.1, 'clk(100MHz)', fontsize=8, ha='right')
ax.text(0.3, 3.8, 'rst_n', fontsize=8, ha='right')
ax.text(0.3, 3.5, 'key_up/down/freq/wave', fontsize=7, ha='right')
ax.text(0.3, 3.2, 'uart_rx', fontsize=8, ha='right')

# Output label on right
ax.text(11.7, 1.2, 'Output:', fontsize=9, fontweight='bold', ha='left')
ax.text(11.7, 0.9, '8-bit DAC', fontsize=8, ha='left')

plt.tight_layout()
plt.savefig('/mnt/d/FPGAmoudle/--main/--main/system_block_diagram.png',
            dpi=200, bbox_inches='tight', facecolor='white')
plt.close()
print("System block diagram saved as system_block_diagram.png")
