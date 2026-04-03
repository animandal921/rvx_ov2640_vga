`timescale 1ns / 1ps

module denoised_sobel_pipeline (
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

    parameter EDGE_THRESHOLD = 8'd15;

    // ==========================================
    // Math Primitives (Combinatorial)
    // ==========================================
    function [5:0] max2(input [5:0] a, b); max2 = (a > b) ? a : b; endfunction
    function [5:0] min2(input [5:0] a, b); min2 = (a < b) ? a : b; endfunction
    function [5:0] max3(input [5:0] a, b, c); max3 = max2(max2(a,b), c); endfunction
    function [5:0] min3(input [5:0] a, b, c); min3 = min2(min2(a,b), c); endfunction
    function [5:0] med3(input [5:0] a, b, c); med3 = max2(min2(a,b), min2(max2(a,b), c)); endfunction

    // ==========================================
    // PART 1: THE MEDIAN FILTER (Stages 0-4)
    // ==========================================
    reg [5:0] raw_buf1 [0:1023];
    reg [5:0] raw_buf2 [0:1023];
    reg [9:0] wr_ptr_raw;

    always @(posedge clk) begin
        if (rst || !href) wr_ptr_raw <= 0;
        else if (pixel_valid_in) wr_ptr_raw <= wr_ptr_raw + 1;
    end

    wire [5:0] gray_in = {2'b00, pixel_data_in[11:8]} + {2'b00, pixel_data_in[7:4]} + {2'b00, pixel_data_in[3:0]};

    // Stage 1: Fetch Raw Rows
    reg [5:0] p_in_d1; reg valid_in_d1; reg [18:0] addr_in_d1; reg [9:0] ptr_raw_d1;
    reg [5:0] r1_read, r2_read;
    always @(posedge clk) begin
        p_in_d1 <= gray_in; valid_in_d1 <= pixel_valid_in; addr_in_d1 <= pixel_addr_in; ptr_raw_d1 <= wr_ptr_raw;
        r1_read <= raw_buf1[wr_ptr_raw]; r2_read <= raw_buf2[wr_ptr_raw];
    end

    // Stage 2: Shift Window & Sort Rows
    reg [5:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;
    reg [5:0] max_r1, med_r1, min_r1, max_r2, med_r2, min_r2, max_r3, med_r3, min_r3;
    reg valid_in_d2; reg [18:0] addr_in_d2;
    always @(posedge clk) begin
        valid_in_d2 <= valid_in_d1; addr_in_d2 <= addr_in_d1;
        if (valid_in_d1) begin
            raw_buf1[ptr_raw_d1] <= p_in_d1; raw_buf2[ptr_raw_d1] <= r1_read;
            p02 <= p_in_d1; p01 <= p02; p00 <= p01;
            p12 <= r1_read; p11 <= p12; p10 <= p11;
            p22 <= r2_read; p21 <= p22; p20 <= p21;
        end
        max_r1 <= max3(p00, p01, p02); med_r1 <= med3(p00, p01, p02); min_r1 <= min3(p00, p01, p02);
        max_r2 <= max3(p10, p11, p12); med_r2 <= med3(p10, p11, p12); min_r2 <= min3(p10, p11, p12);
        max_r3 <= max3(p20, p21, p22); med_r3 <= med3(p20, p21, p22); min_r3 <= min3(p20, p21, p22);
    end

    // Stage 3: Sort Columns
    reg [5:0] min_of_maxs, med_of_meds, max_of_mins;
    reg valid_in_d3; reg [18:0] addr_in_d3;
    always @(posedge clk) begin
        valid_in_d3 <= valid_in_d2; addr_in_d3 <= addr_in_d2;
        min_of_maxs <= min3(max_r1, max_r2, max_r3);
        med_of_meds <= med3(med_r1, med_r2, med_r3);
        max_of_mins <= max3(min_r1, min_r2, min_r3);
    end

    // Stage 4: Final Median Output (The "Bridge" to Sobel)
    reg [5:0] med_pixel;
    reg med_valid; 
    reg [18:0] med_addr;
    always @(posedge clk) begin
        med_valid <= valid_in_d3;
        med_addr  <= addr_in_d3;
        med_pixel <= med3(min_of_maxs, med_of_meds, max_of_mins);
    end

    // ==========================================
    // PART 2: THE SOBEL FILTER (Stages 5-9)
    // ==========================================
    reg [5:0] med_buf1 [0:1023];
    reg [5:0] med_buf2 [0:1023];
    reg [9:0] wr_ptr_med;

    always @(posedge clk) begin
        if (rst || !href) wr_ptr_med <= 0;
        else if (med_valid) wr_ptr_med <= wr_ptr_med + 1;
    end

    // Stage 5: Fetch Median Rows
    reg [5:0] m_in_d1; reg m_valid_d1; reg [18:0] m_addr_d1; reg [9:0] ptr_med_d1;
    reg [5:0] m_r1_read, m_r2_read;
    always @(posedge clk) begin
        m_in_d1 <= med_pixel; m_valid_d1 <= med_valid; m_addr_d1 <= med_addr; ptr_med_d1 <= wr_ptr_med;
        m_r1_read <= med_buf1[wr_ptr_med]; m_r2_read <= med_buf2[wr_ptr_med];
    end

    // Stage 6: Shift Sobel Window
    reg [5:0] g00, g01, g02, g10, g12, g20, g21, g22;
    reg m_valid_d2; reg [18:0] m_addr_d2;
    always @(posedge clk) begin
        m_valid_d2 <= m_valid_d1; m_addr_d2 <= m_addr_d1;
        if (m_valid_d1) begin
            med_buf1[ptr_med_d1] <= m_in_d1; med_buf2[ptr_med_d1] <= m_r1_read;
            g02 <= m_in_d1;   g01 <= g02; g00 <= g01;
            g12 <= m_r1_read;             g10 <= g12; // Center pixel g11 is ignored in Sobel!
            g22 <= m_r2_read; g21 <= g22; g20 <= g21;
        end
    end

    // Stage 7: Gradient Math (Gx and Gy)
    reg signed [8:0] Gx, Gy;
    reg m_valid_d3; reg [18:0] m_addr_d3;
    always @(posedge clk) begin
        m_valid_d3 <= m_valid_d2; m_addr_d3 <= m_addr_d2;
        Gx <= $signed({3'b0, g02}) + $signed({2'b0, g12, 1'b0}) + $signed({3'b0, g22})
            - $signed({3'b0, g00}) - $signed({2'b0, g10, 1'b0}) - $signed({3'b0, g20});
             
        Gy <= $signed({3'b0, g00}) + $signed({2'b0, g01, 1'b0}) + $signed({3'b0, g02})
            - $signed({3'b0, g20}) - $signed({2'b0, g21, 1'b0}) - $signed({3'b0, g22});
    end

    // Stage 8 & 9: Absolute Sum & Threshold
    reg [8:0] sum_G;
    always @(posedge clk) begin
        if (rst) begin
            pixel_valid_out <= 0;
            pixel_data_out  <= 0;
            pixel_addr_out  <= 0;
        end else begin
            pixel_valid_out <= m_valid_d3;
            pixel_addr_out  <= m_addr_d3;

            sum_G = (Gx[8] ? -Gx : Gx) + (Gy[8] ? -Gy : Gy); 

            if (sum_G > EDGE_THRESHOLD) pixel_data_out <= 12'hFFF;
            else                        pixel_data_out <= 12'h000;
        end
    end

endmodule