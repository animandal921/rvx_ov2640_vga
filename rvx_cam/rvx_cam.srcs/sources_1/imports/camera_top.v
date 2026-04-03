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
        input        cam_en,     // Bit 0: 1 = Camera ON, 0 = Camera OFF
        input        filter_en,  // Bit 1: 0 = Raw Camera, 1 = Sobel Edges
        input        res_sel     // Bit 2: 0 = 640x480, 1 = 320x240 (Reserved for future)
    );

    wire clk_vga;      // vga 25.175mhz
    wire clk_init_reg; // 24mhz

    clk_wiz_0 div(.clk_in1(clk), .clk_out1(clk_vga), .clk_out2(clk_init_reg));

    // --------------------------------------------------------
    // Camera Power Down Control
    // --------------------------------------------------------
    // OV2640 pwdn is Active HIGH (1 = Sleep, 0 = Awake)
    assign pwdn = ~cam_en; 

    // --------------------------------------------------------
    // Camera Initialization (I2C/SCCB)
    // --------------------------------------------------------
    camera_init init(
        .clk(clk_init_reg), 
        .res_sel(res_sel),
        .sio_c(sio_c), 
        .sio_d(sio_d), 
        .reset(reset), 
        .pwdn(),       // Disconnected here so we can drive it directly above!
        .rst(rst), 
        .xclk(xclk)
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
    // Gaussian + Sobel Accelerator Pipeline
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
    // Filter Multiplexer & BRAM Write Gate
    // --------------------------------------------------------
    wire [11:0] mux_ram_data;
    wire        mux_wr_en;
    wire [18:0] mux_ram_addr;

    assign mux_ram_data = filter_en ? sobel_data  : raw_ram_data;
    assign mux_ram_addr = filter_en ? sobel_addr  : raw_ram_addr;
    
    // Gate the write enable! If the camera is OFF, stop writing to memory to freeze the frame.
    assign mux_wr_en    = (filter_en ? sobel_wr_en : raw_wr_en) & cam_en;

    // --------------------------------------------------------
    // BRAM (Camera vs. VGA)
    // --------------------------------------------------------
    wire [18:0] vga_rd_addr;
    wire [11:0] rd_data; // Data out from Port B of BRAM

    blk_mem_gen_0 buffer(
        .clka(pclk), 
        .ena(1'b1), 
        .wea(mux_wr_en), 
        .addra(mux_ram_addr), 
        .dina(mux_ram_data),
        
        .clkb(clk_vga), 
        .enb(1'b1), 
        .addrb(vga_rd_addr), 
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