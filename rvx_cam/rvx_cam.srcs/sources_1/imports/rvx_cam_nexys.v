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
  output wire       vga_y_valid
  );

  wire [GPIO_WIDTH-1:0] gpio_input;
  wire [GPIO_WIDTH-1:0] gpio_oe;
  wire [GPIO_WIDTH-1:0] gpio_output;

  genvar i;
  for (i = 0; i < GPIO_WIDTH; i = i + 1) begin
    assign gpio_input[i] = gpio_oe[i] == 1'b1 ? gpio_output[i] : gpio[i];
    assign gpio[i] = gpio_oe[i] == 1'b1 ? gpio_output[i] : 1'bZ;
  end

  // Divides the 100MHz board block by 2
  reg clock_50mhz;
  initial clock_50mhz = 1'b0;
  always @(posedge clock) clock_50mhz <= !clock_50mhz;
  // Push-button debouncing
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

  // Note that unused inputs are hardwired to zero,
  // while unused outputs are left open.

  .clock                    (clock_50mhz                ),
  .reset                    (reset_debounced            ),
  .halt                     (1'b0                       ),
  .uart_rx                  (uart_rx                    ),
  .uart_tx                  (uart_tx                    ),
  .gpio_input               (gpio_input                 ),
  .gpio_oe                  (gpio_oe                    ),
  .gpio_output              (gpio_output                ),
  .sclk                     (/* unused, leave open */   ),
  .pico                     (/* unused, leave open */   ),
  .poci                     (1'b0                       ),
  .cs                       (/* unused, leave open */   ),

  // Camera Accelerator Connections
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
  .vga_y_valid              (vga_y_valid                )

  );

endmodule