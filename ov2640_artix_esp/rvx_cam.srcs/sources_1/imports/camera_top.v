`timescale 1ns / 1ps

module camera_top(
    output       sio_c,
    inout        sio_d,
    output       reset,
    output       pwdn,
    output       xclk,
    input        pclk, 
    input        href, 
    input        vsync,
    input  [7:0] camera_data,
    
    // VGA Outputs (Disabled for Streaming)
    output [3:0] red_out, 
    output [3:0] green_out, 
    output [3:0] blue_out, 
    output       x_valid,
    output       y_valid,
    
    // System & Control
    input        clk,
    input        rst,
    input        cam_en,     
    input        filter_en,  
    input        res_sel,    
    
    // Wireless Stream & Diagnostics
    output       out_pclk,
    output       out_vsync,
    output       out_href,
    output [7:0] out_data,
    output [3:0] led
);

    wire clk_vga;      
    wire clk_init_reg; 

    clk_wiz_0 div(
        .clk_in1(clk), 
        .clk_out1(clk_vga), 
        .clk_out2(clk_init_reg)
    );

    assign pwdn = ~cam_en; 

    camera_init init(
        .clk(clk_init_reg), 
        .res_sel(res_sel),
        .sio_c(sio_c), 
        .sio_d(sio_d), 
        .reset(reset), 
        .pwdn(),       
        .rst(rst), 
        .xclk(xclk)
    );

    wire [11:0] raw_ram_data; 
    wire        raw_wr_en;
    wire [18:0] raw_ram_addr; 
    
    camera_get_pic get_pic(
        .rst(rst), 
        .pclk(pclk), 
        .href(href), 
        .vsync(vsync), 
        .data_in(camera_data), 
        .data_out(raw_ram_data), 
        .wr_en(raw_wr_en), 
        .out_addr(raw_ram_addr)
    );
    
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

    wire [11:0] mux_ram_data;
    wire        mux_wr_en;
    wire [18:0] mux_ram_addr;

    assign mux_ram_data = filter_en ? sobel_data  : raw_ram_data;
    assign mux_ram_addr = filter_en ? sobel_addr  : raw_ram_addr;
    
    assign mux_wr_en = (filter_en ? sobel_wr_en : raw_wr_en) & cam_en;

    wire [18:0] stream_rd_addr;
    wire [11:0] stream_rd_data;

    blk_mem_gen_0 stream_buffer(
        .clka(pclk), 
        .ena(1'b1), 
        .wea(mux_wr_en), 
        .addra(mux_ram_addr), 
        .dina(mux_ram_data),
        .clkb(clk),  
        .enb(1'b1), 
        .addrb(stream_rd_addr), 
        .doutb(stream_rd_data)
    );

    parallel_streamer streamer_inst(
        .clk(clk),
        .rst(rst),
        .stream_en(cam_en), 
        .ram_addr(stream_rd_addr),
        .ram_data(stream_rd_data),
        .out_pclk(out_pclk),
        .out_vsync(out_vsync),
        .out_href(out_href),
        .out_data(out_data)
    );

    // Disable VGA outputs safely
    assign red_out   = 4'b0;
    assign green_out = 4'b0;
    assign blue_out  = 4'b0;
    assign x_valid   = 1'b0;
    assign y_valid   = 1'b0;
    
    // LED Indicators!
    assign led[0] = raw_ram_addr[15];   
    assign led[1] = sobel_addr[15];     
    assign led[2] = stream_rd_addr[15]; 
    assign led[3] = out_pclk;            

endmodule