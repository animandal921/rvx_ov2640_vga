`timescale 1ns / 1ps

module median_filter (
    input clk,
    input rst,
    input href,
    
    input pixel_valid_in,
    input [11:0] pixel_data_in,   // 12-bit RGB from camera
    input [18:0] pixel_addr_in,
    
    output reg pixel_valid_out,
    output reg [11:0] pixel_data_out, // 12-bit Grayscale out to Sobel
    output reg [18:0] pixel_addr_out
);

    // ==========================================
    // Math Primitives (Combinatorial LUTs)
    // ==========================================
    function [5:0] max2(input [5:0] a, b); 
        max2 = (a > b) ? a : b; 
    endfunction
    
    function [5:0] min2(input [5:0] a, b); 
        min2 = (a < b) ? a : b; 
    endfunction
    
    function [5:0] max3(input [5:0] a, b, c); 
        max3 = max2(max2(a,b), c); 
    endfunction
    
    function [5:0] min3(input [5:0] a, b, c); 
        min3 = min2(min2(a,b), c); 
    endfunction
    
    function [5:0] med3(input [5:0] a, b, c);
        // The mathematical definition of a 3-input median
        med3 = max2(min2(a,b), min2(max2(a,b), c));
    endfunction

    // ==========================================
    // STAGE 0: Grayscale Conversion & Line Buffers
    // ==========================================
    reg [5:0] gray_buf1 [0:1023];
    reg [5:0] gray_buf2 [0:1023];
    reg [9:0] wr_ptr;

    always @(posedge clk) begin
        if (rst || !href) wr_ptr <= 0;
        else if (pixel_valid_in) wr_ptr <= wr_ptr + 1;
    end

    // Convert 12-bit RGB to 6-bit Grayscale
    wire [5:0] gray_in = {2'b00, pixel_data_in[11:8]} + 
                         {2'b00, pixel_data_in[7:4]}  + 
                         {2'b00, pixel_data_in[3:0]};

    reg [5:0] p_in_d1;   reg valid_in_d1; reg [18:0] addr_in_d1; reg [9:0] wr_ptr_d1;
    reg [5:0] row1_read, row2_read;

    always @(posedge clk) begin
        p_in_d1     <= gray_in;
        valid_in_d1 <= pixel_valid_in;
        addr_in_d1  <= pixel_addr_in;
        wr_ptr_d1   <= wr_ptr;

        row1_read <= gray_buf1[wr_ptr];
        row2_read <= gray_buf2[wr_ptr];
    end

    // ==========================================
    // STAGE 1: Shift Window & Sort Rows
    // ==========================================
    reg [5:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
    reg [5:0] max_r1, med_r1, min_r1;
    reg [5:0] max_r2, med_r2, min_r2;
    reg [5:0] max_r3, med_r3, min_r3;
    reg valid_in_d2; reg [18:0] addr_in_d2;

    always @(posedge clk) begin
        valid_in_d2 <= valid_in_d1;
        addr_in_d2  <= addr_in_d1;

        if (valid_in_d1) begin
            // Update Buffers
            gray_buf1[wr_ptr_d1] <= p_in_d1;
            gray_buf2[wr_ptr_d1] <= row1_read;

            // Shift Window
            p02 <= p_in_d1;   p01 <= p02; p00 <= p01;
            p12 <= row1_read; p11 <= p12; p10 <= p11;
            p22 <= row2_read; p21 <= p22; p20 <= p21;
        end

        // Sort Row 1
        max_r1 <= max3(p00, p01, p02);
        med_r1 <= med3(p00, p01, p02);
        min_r1 <= min3(p00, p01, p02);
        
        // Sort Row 2
        max_r2 <= max3(p10, p11, p12);
        med_r2 <= med3(p10, p11, p12);
        min_r2 <= min3(p10, p11, p12);
        
        // Sort Row 3
        max_r3 <= max3(p20, p21, p22);
        med_r3 <= med3(p20, p21, p22);
        min_r3 <= min3(p20, p21, p22);
    end

    // ==========================================
    // STAGE 2: Sort Columns
    // ==========================================
    reg [5:0] min_of_maxs;
    reg [5:0] med_of_meds;
    reg [5:0] max_of_mins;
    reg valid_in_d3; reg [18:0] addr_in_d3;

    always @(posedge clk) begin
        valid_in_d3 <= valid_in_d2;
        addr_in_d3  <= addr_in_d2;

        min_of_maxs <= min3(max_r1, max_r2, max_r3);
        med_of_meds <= med3(med_r1, med_r2, med_r3);
        max_of_mins <= max3(min_r1, min_r2, min_r3);
    end

    // ==========================================
    // STAGE 3: Final Median Output
    // ==========================================
    reg [5:0] final_median;
    
    always @(posedge clk) begin
        if (rst) begin
            pixel_valid_out <= 0;
            pixel_addr_out  <= 0;
            pixel_data_out  <= 0;
        end else begin
            pixel_valid_out <= valid_in_d3;
            pixel_addr_out  <= addr_in_d3;
            
            final_median = med3(min_of_maxs, med_of_meds, max_of_mins);
            
            // Pad the 6-bit grayscale back into a 12-bit "gray" RGB pixel 
            // so the downstream Sobel module doesn't need to be modified.
            pixel_data_out <= {final_median[5:2], final_median[5:2], final_median[5:2]};
        end
    end

endmodule