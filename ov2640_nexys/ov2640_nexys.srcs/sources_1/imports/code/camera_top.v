`timescale 1ns / 1ps

module camera_top(
        output       sio_c,
        inout        sio_d,
        output       reset,
        output       pwdn,
        output       xclk,
        input        pclk, href, vsync,
        input  [7:0] camera_data,
        
        // VGA
        output [3:0] red_out, green_out, blue_out, // rgb
        output       x_valid,
        output       y_valid,
        
        // System & Control
        input        clk,
        input        rst,
        input        filter_en,  // Switch: 0 = Raw Camera, 1 = Sobel Edges
        
        // UART Image Sender
        input        send_en,    // Switch: 1 = Freeze frame and send to PC
        output       uart_txd    // Physical UART TX pin
    );

    wire clk_vga;      // vga 25.175mhz
    wire clk_init_reg; // 24mhz

    clk_wiz_0 div(.clk_in1(clk), .clk_out1(clk_vga), .clk_out2(clk_init_reg));

    // --------------------------------------------------------
    // Camera Initialization (I2C/SCCB)
    // --------------------------------------------------------
    camera_init init(
        .clk(clk_init_reg), .sio_c(sio_c), .sio_d(sio_d), 
        .reset(reset), .pwdn(pwdn), .rst(rst), .xclk(xclk)
    );

    // --------------------------------------------------------
    // Camera Capture
    // --------------------------------------------------------
    wire [11:0] raw_ram_data; 
    wire        raw_wr_en;
    wire [18:0] raw_ram_addr; 
    
    camera_get_pic get_pic(
        .rst(rst), .pclk(pclk), .href(href), .vsync(vsync), 
        .data_in(camera_data), .data_out(raw_ram_data), 
        .wr_en(raw_wr_en), .out_addr(raw_ram_addr)
    );
    
    // --------------------------------------------------------
    // Sobel Pipeline
    // --------------------------------------------------------
    wire [11:0] sobel_data;
    wire        sobel_wr_en;
    wire [18:0] sobel_addr;
    
    gaussian_sobel_pipeline sobel_inst(
        .clk(pclk),                 
        .rst(rst),
        .href(href),
        .pixel_valid_in(raw_wr_en), 
        .pixel_data_in(raw_ram_data),
        .pixel_addr_in(raw_ram_addr),
        
        .pixel_valid_out(sobel_wr_en),
        .pixel_data_out(sobel_data),
        .pixel_addr_out(sobel_addr)
    );

    // --------------------------------------------------------
    // Filter Multiplexer (Controlled by filter_en)
    // --------------------------------------------------------
    wire [11:0] mux_ram_data;
    wire        mux_wr_en;
    wire [18:0] mux_ram_addr;

    assign mux_ram_data = filter_en ? sobel_data  : raw_ram_data;
    assign mux_wr_en    = filter_en ? sobel_wr_en : raw_wr_en;
    assign mux_ram_addr = filter_en ? sobel_addr  : raw_ram_addr;

    // --------------------------------------------------------
    // UART Image Sender Integration
    // --------------------------------------------------------
    wire uart_freeze;
    wire uart_take_ctrl;
    wire [18:0] uart_bram_addr;
    wire [11:0] rd_data; // Data out from Port B of BRAM
    // --------------------------------------------------------
    // Clock Domain Crossing (CDC) Synchronizer for freeze_frame
    // --------------------------------------------------------
    reg freeze_sync1, freeze_sync2;
    
    // We clock this on pclk (the destination domain for the BRAM write)
    always @(posedge pclk) begin
        if (rst) begin
            freeze_sync1 <= 0;
            freeze_sync2 <= 0;
        end else begin
            freeze_sync1 <= uart_freeze;   // Catch the signal from the VGA domain
            freeze_sync2 <= freeze_sync1;  // Clean it and stabilize it in the Camera domain
        end
    end
    // Make sure your uart_image_sender.v file is added to the Vivado project
    uart_image_sender sender_inst (
        .clk(clk_vga), 
        .rst(rst), 
        .send_en(send_en), 
        .bram_data(rd_data), 
        .bram_addr(uart_bram_addr),
        .freeze_frame(uart_freeze),
        .take_control(uart_take_ctrl),
        .uart_tx(uart_txd)
    );

    // --------------------------------------------------------
    // BRAM Arbitration (Camera vs. UART vs. VGA)
    // --------------------------------------------------------
    wire [18:0] vga_rd_addr;

    // 1. Write Gate: Stop overwriting the image while UART is downloading it
    wire final_ram_we = freeze_sync2 ? 1'b0 : mux_wr_en;
    
    // 2. Read Mux: Give Port B to UART if sending, otherwise give it to VGA
    wire [18:0] final_rd_addr = uart_take_ctrl ? uart_bram_addr : vga_rd_addr;

    blk_mem_gen_0 buffer(
        .clka(pclk), 
        .ena(1'b1), 
        .wea(final_ram_we), 
        .addra(mux_ram_addr), 
        .dina(mux_ram_data),
        
        .clkb(clk_vga), 
        .enb(1'b1), 
        .addrb(final_rd_addr), 
        .doutb(rd_data)
    );

    // --------------------------------------------------------
    // VGA Display
    // --------------------------------------------------------
    vga_display vga(
        .clk_vga(clk_vga), 
        .rst(rst), 
        .color_data_in(rd_data), 
        .ram_addr(vga_rd_addr), 
        .x_valid(x_valid), 
        .y_valid(y_valid), 
        .red(red_out), 
        .green(green_out), 
        .blue(blue_out)
    );
    
endmodule