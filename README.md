# OV2640 Camera & RVX SoC Integration on Nexys 4

This repository contains two parallel projects for interfacing an OV2640 camera module with a Digilent Nexys 4 FPGA board. It includes both a standalone hardware pipeline and a full RISC-V System-on-Chip (SoC) integration with hardware-accelerated image processing.

## Hardware Requirements
* **Development Board:** Digilent Nexys 4 (Xilinx Artix-7 FPGA)
* **Peripheral:** OV2640 Camera Module
* **Output:** VGA Monitor 

---

## 1. `ov2640_nexys` (Standalone Hardware Pipeline)
This project serves as the foundational hardware pipeline for capturing, storing, and displaying image data without a soft-core processor.

* **Camera Configuration:** Utilizes an SCCB interface to configure the OV2640 to output image data (primarily RGB565 format).
* **Data Flow:** Captures incoming pixel data via the DVP interface, buffers the frames into the BRAM, and generates the necessary VGA synchronization signals for display.
* **Data Offloading:** Includes a UART transmitter module to allow for image data extraction over a serial connection.

---

## 2. `rvx_cam` (RISC-V SoC with Sobel Accelerator)
This project integrates the camera pipeline into the custom RVX RISC-V SoC, introducing MMIO control and real-time hardware acceleration.

* **Hardware Accelerator:** Includes a custom `gaussian_sobel_pipeline` designed to apply a Gaussian Noise Filter and a Sobel edge-detection filter to the live video stream.
* **Memory-Mapped I/O (MMIO):** The accelerator is mapped to address `0x8004_0000` on the SoC's system bus.
* **Firmware Control:** A bare-metal C program running on the RVX core reads the physical GPIO switches on the Nexys 4 board. These switches dynamically toggle the video feed and enable/disable the Sobel filter via the MMIO registers.
* **Clocking Architecture:** Manages complex clock domain crossings across the 100MHz system clock, a 50MHz generated core clock, the VGA pixel clock, and the camera's PCLK.
