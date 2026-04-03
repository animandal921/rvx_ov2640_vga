`timescale 1ns / 1ps

module uart_image_sender (
    input clk,                   // clk_vga (25.175 MHz)
    input rst,                   // Active high reset
    input send_en,               // Hardware switch to trigger capture
    
    input [11:0] bram_data,      // 12-bit RGB444 pixel from BRAM Port B
    output reg [18:0] bram_addr, // Address requested from BRAM
    
    output reg freeze_frame,     // High: stops camera from overwriting BRAM
    output reg take_control,     // High: routes bram_addr to BRAM instead of VGA
    output uart_tx           // Physical UART TX pin
);

    // 921600 Baud Rate Generator for 25.175 MHz clock (25,175,000 / 921600 = ~27)
    parameter CLKS_PER_BIT = 27;
    // Full VGA Frame: 640 * 480 - 1
    parameter MAX_ADDR = 19'd307199; 
    
    // State Machine States
    parameter IDLE      = 4'd0;
    parameter READ_REQ  = 4'd1;
    parameter READ_WAIT = 4'd2;
    parameter SEND_B1   = 4'd3;
    parameter WAIT_B1   = 4'd4;
    parameter SEND_B2   = 4'd5;
    parameter WAIT_B2   = 4'd6;
    parameter NEXT_PIX  = 4'd7;
    parameter DONE      = 4'd8;
    
    reg [3:0] state = IDLE;
    
    // UART TX Internals
    reg [7:0] tx_data;
    reg tx_start;
    wire tx_active;
    wire tx_done;
    
    uart_tx_basic #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx_inst (
        .clk(clk), 
        .rst(rst), 
        .tx_start(tx_start), 
        .tx_data(tx_data), 
        .tx_active(tx_active), 
        .tx_done(tx_done), 
        .uart_tx(uart_tx)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            bram_addr <= 0;
            freeze_frame <= 0;
            take_control <= 0;
            tx_start <= 0;
        end else begin
            tx_start <= 0; // Default to 0, pulse high only when needed
            
            case (state)
                IDLE: begin
                    bram_addr <= 0;
                    if (send_en) begin
                        freeze_frame <= 1; // Freeze the BRAM contents
                        take_control <= 1; // Steal the read port from VGA
                        state <= READ_REQ;
                    end else begin
                        freeze_frame <= 0;
                        take_control <= 0;
                    end
                end
                
                READ_REQ: begin
                    // BRAM takes 1 clock cycle to output data after address changes
                    state <= READ_WAIT; 
                end
                
                READ_WAIT: begin
                    state <= SEND_B1;
                end
                
                SEND_B1: begin
                    // Byte 1: Pad with zeros, send Red (11:8)
                    tx_data <= {4'b0000, bram_data[11:8]}; 
                    tx_start <= 1;
                    state <= WAIT_B1;
                end
                
                WAIT_B1: begin
                    if (tx_done) state <= SEND_B2;
                end
                
                SEND_B2: begin
                    // Byte 2: Send Green (7:4) and Blue (3:0)
                    tx_data <= bram_data[7:0];
                    tx_start <= 1;
                    state <= WAIT_B2;
                end
                
                WAIT_B2: begin
                    if (tx_done) state <= NEXT_PIX;
                end
                
                NEXT_PIX: begin
                    if (bram_addr == MAX_ADDR) begin
                        state <= DONE;
                    end else begin
                        bram_addr <= bram_addr + 1;
                        state <= READ_REQ;
                    end
                end
                
                DONE: begin
                    // Hold here until the user flips the switch back down
                    if (!send_en) state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule


// ========================================================
// Standard Basic UART Transmitter (Included in same file)
// ========================================================
module uart_tx_basic #(parameter CLKS_PER_BIT = 27) (
    input clk, 
    input rst, 
    input tx_start, 
    input [7:0] tx_data,
    
    output reg tx_active, 
    output reg tx_done, 
    output reg uart_tx
);

    parameter IDLE  = 2'd0;
    parameter START = 2'd1;
    parameter DATA  = 2'd2;
    parameter STOP  = 2'd3;
    
    reg [1:0] state = IDLE;
    reg [15:0] clk_count = 0; // Sized for lower baud rates if needed later
    reg [2:0] bit_idx = 0;
    reg [7:0] data_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; 
            uart_tx <= 1; 
            tx_active <= 0; 
            tx_done <= 0;
            clk_count <= 0;
            bit_idx <= 0;
            data_reg <= 0;
        end else begin
            tx_done <= 0;
            
            case (state)
                IDLE: begin
                    uart_tx <= 1; 
                    tx_active <= 0;
                    if (tx_start) begin
                        tx_active <= 1; 
                        data_reg <= tx_data; 
                        state <= START; 
                        clk_count <= 0;
                    end
                end
                
                START: begin
                    uart_tx <= 0; // Start bit is low
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin 
                        clk_count <= 0; 
                        state <= DATA; 
                        bit_idx <= 0; 
                    end
                end
                
                DATA: begin
                    uart_tx <= data_reg[bit_idx];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    uart_tx <= 1; // Stop bit is high
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin 
                        tx_done <= 1; 
                        tx_active <= 0; 
                        state <= IDLE; 
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule