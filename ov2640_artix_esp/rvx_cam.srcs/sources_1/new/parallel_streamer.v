`timescale 1ns / 1ps

module parallel_streamer(
    input clk,
    input rst,
    input stream_en,
    output reg [18:0] ram_addr,
    input [11:0] ram_data,
    
    // Parallel Bus Outputs
    output reg out_pclk,
    output reg out_vsync,
    output reg out_href,
    output reg [7:0] out_data
);
    
    wire [7:0] gray_data = ({4'b0, ram_data[11:8]} * 8'd5) + 
                           ({4'b0, ram_data[7:4]}  * 8'd9) + 
                           ({4'b0, ram_data[3:0]}  * 8'd2);
                           
    // Clock Divider: 50 MHz -> 500 kHz Pixel Clock
    reg [5:0] div_cnt;
    wire tick = (div_cnt == 49); 
    
    always @(posedge clk) begin
        if (rst) div_cnt <= 0;
        else if (tick) div_cnt <= 0;
        else div_cnt <= div_cnt + 1;
    end
    
    reg [8:0] x_cnt; 
    reg [8:0] y_cnt; 
    reg [2:0] state;
    
    localparam S_IDLE   = 0;
    localparam S_VSYNC  = 1;
    localparam S_WAIT   = 2;
    localparam S_ROW    = 3;
    localparam S_HBLANK = 4;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            out_pclk <= 0;
            out_vsync <= 0;
            out_href <= 0;
        end else if (tick) begin
            out_pclk <= ~out_pclk;
            
            if (out_pclk) begin 
                case (state)
                    S_IDLE: begin
                        ram_addr <= 0;
                        if (stream_en) begin
                            state <= S_VSYNC;
                            x_cnt <= 0;
                        end
                    end
                    S_VSYNC: begin
                        out_vsync <= 1; 
                        out_href <= 0;
                        if (x_cnt == 5) begin 
                            x_cnt <= 0; state <= S_WAIT;
                        end else x_cnt <= x_cnt + 1;
                    end
                    S_WAIT: begin
                        out_vsync <= 0;
                        if (x_cnt == 5) begin
                            x_cnt <= 0; y_cnt <= 0; state <= S_ROW;
                        end else x_cnt <= x_cnt + 1;
                    end
                    S_ROW: begin
                        out_href <= 1;
                        out_data <= gray_data;
                        ram_addr <= ram_addr + 1;
                        
                        if (x_cnt == 319) begin 
                            x_cnt <= 0; state <= S_HBLANK;
                        end else x_cnt <= x_cnt + 1;
                    end
                    S_HBLANK: begin
                        out_href <= 0;
                        // MASSIVE HBLANK EXTENSION (200 clocks)
                        if (x_cnt == 200) begin 
                            x_cnt <= 0;
                            if (y_cnt == 239) begin 
                                state <= S_VSYNC; 
                                ram_addr <= 0;
                            end else begin
                                y_cnt <= y_cnt + 1; 
                                state <= S_ROW;
                            end
                        end else x_cnt <= x_cnt + 1;
                    end
                endcase
            end
        end
    end
endmodule