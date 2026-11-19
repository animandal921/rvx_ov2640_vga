`timescale 1ns/1ps

module rvx_cam_nexys #(
  parameter GPIO_WIDTH = 3
  )
  (
  input  wire clock,
  input  wire reset,
  output wire uart_tx,
  input  wire uart_rx, 
  inout wire [GPIO_WIDTH-1:0] gpio,

  // Camera I/O
  output wire       sio_c,
  inout  wire       sio_d,
  output wire       cam_reset,
  output wire       cam_pwdn,
  output wire       xclk,
  input  wire       pclk, 
  input  wire       href, 
  input  wire       vsync,
  input  wire [7:0] camera_data,
  
  // VGA I/O
  output wire [3:0] vga_r,
  output wire [3:0] vga_g,
  output wire [3:0] vga_b,
  output wire       vga_x_valid,
  output wire       vga_y_valid,
  
  // ESP32 Streaming & Diagnostics I/O (UPDATED TO PARALLEL)
  output wire       out_pclk,
  output wire       out_vsync,
  output wire       out_href,
  output wire [7:0] out_data,
  output wire [3:0] led
  );

  wire [GPIO_WIDTH-1:0] gpio_input;
  wire [GPIO_WIDTH-1:0] gpio_oe;
  wire [GPIO_WIDTH-1:0] gpio_output;

  genvar i;
  for (i = 0; i < GPIO_WIDTH; i = i + 1) begin
    assign gpio_input[i] = gpio_oe[i] == 1'b1 ? gpio_output[i] : gpio[i];
    assign gpio[i] = gpio_oe[i] == 1'b1 ? gpio_output[i] : 1'bZ;
  end

  reg clock_50mhz;
  initial clock_50mhz = 1'b0;
  always @(posedge clock) clock_50mhz <= !clock_50mhz;
  
  reg reset_debounced;
  always @(posedge clock_50mhz) begin
    reset_debounced <= !reset;
  end

  rvx #(
    .CLOCK_FREQUENCY          (50000000               ),
    .UART_BAUD_RATE           (9600                   ),
    .MEMORY_SIZE              (8192                   ),
    .MEMORY_INIT_FILE         ("gpio_cam.hex"         ),
    .BOOT_ADDRESS             (32'h00000000           ),
    .GPIO_WIDTH               (3                      )
  ) rvx_instance (
  .clock                    (clock_50mhz                ),
  .reset                    (reset_debounced            ),
  .halt                     (1'b0                       ),
  .uart_rx                  (uart_rx                    ),
  .uart_tx                  (uart_tx                    ),
  .gpio_input               (gpio_input                 ),
  .gpio_oe                  (gpio_oe                    ),
  .gpio_output              (gpio_output                ),
  .sclk                     (                           ),
  .pico                     (                           ),
  .poci                     (1'b0                       ),
  .cs                       (                           ),

  .sio_c                    (sio_c                      ),
  .sio_d                    (sio_d                      ),
  .cam_reset                (cam_reset                  ),
  .cam_pwdn                 (cam_pwdn                   ),
  .xclk                     (xclk                       ),
  .pclk                     (pclk                       ),
  .href                     (href                       ),
  .vsync                    (vsync                      ),
  .camera_data              (camera_data                ),
  .vga_r                    (vga_r                      ),
  .vga_g                    (vga_g                      ),
  .vga_b                    (vga_b                      ),
  .vga_x_valid              (vga_x_valid                ),
  .vga_y_valid              (vga_y_valid                ),
  
  // PARALLEL BUS CONNECTIONS
  .out_pclk                 (out_pclk                   ),
  .out_vsync                (out_vsync                  ),
  .out_href                 (out_href                   ),
  .out_data                 (out_data                   ),
  .led                      (led                        )
  );
endmodule