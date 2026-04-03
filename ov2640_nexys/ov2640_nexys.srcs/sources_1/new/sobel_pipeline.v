module sobel_pipeline (
    input clk,                
    input rst,
    input href,               
    input pixel_valid_in,     
    input [11:0] pixel_data_in,
    input [18:0] pixel_addr_in, 
    
    output reg pixel_valid_out,
    output reg [11:0] pixel_data_out,
    output reg [18:0] pixel_addr_out
);

    // Threshold out of ~180. 
    // Increase if you see static noise, decrease if edges are too faint.
    parameter EDGE_THRESHOLD = 8'd15; 

    // Oversized buffers to absorb camera dummy pixels safely
    reg [11:0] buf1 [0:1023];
    reg [11:0] buf2 [0:1023];
    reg [9:0] wr_ptr;

    // Anchor the pointer to the start of the camera's row
    always @(posedge clk) begin
        if (rst || !href) wr_ptr <= 0;
        else if (pixel_valid_in) wr_ptr <= wr_ptr + 1;
    end

    // ==========================================
    // STAGE 1: Synchronous Memory Fetch (The Air Gap)
    // ==========================================
    reg [11:0] p_in_d1;
    reg [18:0] addr_in_d1;
    reg        valid_in_d1;
    reg [9:0]  wr_ptr_d1;
    reg [11:0] row1_read, row2_read;

    always @(posedge clk) begin
        p_in_d1     <= pixel_data_in;
        addr_in_d1  <= pixel_addr_in;
        valid_in_d1 <= pixel_valid_in;
        wr_ptr_d1   <= wr_ptr;

        // Fetch the OLD pixels exactly 1 clock cycle before we overwrite them
        row1_read <= buf1[wr_ptr];
        row2_read <= buf2[wr_ptr];
    end

    // ==========================================
    // STAGE 2: Memory Write & Window Shift
    // ==========================================
    reg [11:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
    reg [18:0] addr_in_d2;
    reg        valid_in_d2;

    always @(posedge clk) begin
        addr_in_d2  <= addr_in_d1;
        valid_in_d2 <= valid_in_d1;

        if (valid_in_d1) begin
            // Safely write the NEW pixels into the delayed pointer location
            buf1[wr_ptr_d1] <= p_in_d1;
            buf2[wr_ptr_d1] <= row1_read;

            // Shift 3x3 Window (Right to Left)
            p02 <= p_in_d1;   p01 <= p02; p00 <= p01;
            p12 <= row1_read; p11 <= p12; p10 <= p11;
            p22 <= row2_read; p21 <= p22; p20 <= p21;
        end
    end

    // ==========================================
    // STAGE 3: Grayscale Conversion
    // ==========================================
    function [5:0] to_gray(input [11:0] rgb);
        begin
            // 6-bit math prevents overflow crushing
            to_gray = {2'b00, rgb[11:8]} + {2'b00, rgb[7:4]} + {2'b00, rgb[3:0]};
        end
    endfunction

    reg [5:0] g00, g01, g02, g10, g12, g20, g21, g22;
    reg valid_in_d3; reg [18:0] addr_in_d3;

    always @(posedge clk) begin
        valid_in_d3 <= valid_in_d2;
        addr_in_d3  <= addr_in_d2;

        g00 <= to_gray(p00); g01 <= to_gray(p01); g02 <= to_gray(p02);
        g10 <= to_gray(p10);                      g12 <= to_gray(p12);
        g20 <= to_gray(p20); g21 <= to_gray(p21); g22 <= to_gray(p22);
    end

    // ==========================================
    // STAGE 4: Gradients (Sobel Kernels)
    // ==========================================
    reg signed [8:0] Gx, Gy;
    reg valid_in_d4; reg [18:0] addr_in_d4;

    always @(posedge clk) begin
        valid_in_d4 <= valid_in_d3;
        addr_in_d4  <= addr_in_d3;

        Gx <= $signed({3'b0, g02}) + $signed({2'b0, g12, 1'b0}) + $signed({3'b0, g22})
            - $signed({3'b0, g00}) - $signed({2'b0, g10, 1'b0}) - $signed({3'b0, g20});
             
        Gy <= $signed({3'b0, g00}) + $signed({2'b0, g01, 1'b0}) + $signed({3'b0, g02})
            - $signed({3'b0, g20}) - $signed({2'b0, g21, 1'b0}) - $signed({3'b0, g22});
    end

    // ==========================================
    // STAGE 5: Absolute Sum & Threshold Output
    // ==========================================
    reg [8:0] sum_G;
    
    always @(posedge clk) begin
        if (rst) begin
            pixel_valid_out <= 0;
            pixel_data_out  <= 0;
            pixel_addr_out  <= 0;
        end else begin
            pixel_valid_out <= valid_in_d4;
            pixel_addr_out  <= addr_in_d4;

            // Absolute value math
            sum_G = (Gx[8] ? -Gx : Gx) + (Gy[8] ? -Gy : Gy); 

            // The Noise Gate
            if (sum_G > EDGE_THRESHOLD) begin
                pixel_data_out <= 12'hFFF; // High-contrast White Edge
            end else begin
                pixel_data_out <= 12'h000; // Pitch Black Background
            end
        end
    end

endmodule