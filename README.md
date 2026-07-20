# FPGA-Based Pixel-Stream Acceleration System

## 📌 Project Overview
This repository contains a proprietary FPGA-based hardware pipeline designed to synthesize and render graphical images directly from Block RAM at full VGA resolution. The system ensures a tearing-free, zero-latency display during high-speed pixel streaming and is accelerated by a custom Python data-translation layer for rapid asset-to-hardware deployment.

**Key Features:**
*   Full VGA resolution image rendering directly from on-chip Block RAM.
*   Custom Python data-translation layer for rapidly converting visual assets into hardware-deployable memory formats.
*   Hardware-level image filtering capabilities.
*   Sub-microsecond color-space control directly on the FPGA.
*   Zero-latency, tearing-free display synchronization.

## 🛠️ Tech Stack & Tools
*   **Hardware Description Language:** Verilog
*   **Software Layer:** Python
*   **Target Board:** Digilent Basys 3 (Xilinx Artix-7)
*   **EDA Tool:** Xilinx Vivado
*   **Core Concepts:** VGA Timing Protocols, Block RAM (BRAM) Instantiation, Hardware-Software Co-design, Image Signal Processing.

## 🏗️ System Architecture
### 🐍 Python Data-Translation Layer
A custom Python toolchain acts as the bridge between standard image assets and the FPGA hardware. It processes input images and translates the RGB pixel data into memory initialization files that are loaded directly into the Vivado BRAM IP, drastically reducing asset deployment time.

### ⚡ Hardware Pipeline
1.  **VGA Timing Controller:** Generates strict horizontal and vertical synchronization signals (H-Sync/V-Sync) compliant with standard VGA timing specifications.
2.  **Memory Controller:** Fetches pixel data from the BRAM IP in perfect sync with the VGA pixel clock domain.
3.  **Color Space & Filtering Logic:** Applies real-time, sub-microsecond filtering and color-space manipulations to the pixel stream before routing it to the VGA DAC.

## 📂 Directory Structure
```text
├── hardware/
│   ├── src/                  # Verilog RTL (VGA controller, BRAM interface)
│   ├── tb/                   # Simulation testbenches
│   └── constraints/          # Basys 3 pin mappings for the VGA port (.xdc)
├── software/
│   ├── scripts/              # Python data-translation tools
│   └── sample_assets/        # Source images and generated memory files
└── docs/
    ├── block_diagram.png     # System architecture diagram
