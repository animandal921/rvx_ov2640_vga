`timescale 1ns/1ps

module gaussian_sobel_pipeline (
    input clk,
    input rst,
    input href,
    
    input pixel_valid_in,
    input [11:0] pixel_data_in,   // Raw 12-bit RGB from camera
    input [18:0] pixel_addr_in,
    
    output reg pixel_valid_out,
    output reg [11:0] pixel_data_out, // Smoothed Color + White Edges
    output reg [18:0] pixel_addr_out
);

    parameter EDGE_THRESHOLD = 8'd18; // Slightly higher threshold for smoothed data
	parameter EDGE_COLOR     = 12'h0F0; // 12'h0F0 is Neon Green, 12'hF0F is Magenta
    // ==========================================
    // REGISTER DECLARATIONS (Scope & Sim Fix)
    // ==========================================
    
    // --- PART 1: GAUSSIAN REGISTERS ---
    reg [11:0] g_rgb_buf1 [0:1023];
    reg [11:0] g_rgb_buf2 [0:1023];
    reg [9:0]  wr_ptr_g;

    reg [11:0] g_in_d1; reg g_v_d1; reg [18:0] g_a_d1; reg [9:0] ptr_g_d1;
    reg [11:0] g_r1_read, g_r2_read;

    reg [11:0] g00, g01, g02, g10, g11, g12, g20, g21, g22;
    reg g_v_d2; reg [18:0] g_a_d2;

    reg [7:0] sum_R_r1, sum_R_r2, sum_R_r3;
    reg [7:0] sum_G_r1, sum_G_r2, sum_G_r3;
    reg [7:0] sum_B_r1, sum_B_r2, sum_B_r3;
    reg g_v_d3; reg [18:0] g_a_d3;

    reg [7:0] tot_R, tot_G, tot_B;
    reg g_v_d4; reg [18:0] g_a_d4;
    reg [11:0] smoothed_rgb;

    // --- PART 2: SOBEL REGISTERS ---
    reg [5:0]  s_gray_buf1 [0:1023];
    reg [5:0]  s_gray_buf2 [0:1023];
    reg [11:0] s_color_buf [0:1023]; // The Color Shadow Buffer
    reg [9:0]  wr_ptr_s;

    reg [5:0] s_in_d1; reg s_v_d1; reg [18:0] s_a_d1; reg [9:0] ptr_s_d1;
    reg [5:0] s_r1_read, s_r2_read;
    reg [11:0] s_color_in_d1, s_color_r1_read;

    reg [5:0] s00, s01, s02, s10, s12, s20, s21, s22; // s11 is omitted for Sobel
    reg [11:0] c12, c11; // Color shadow tracking to center
    reg s_v_d2; reg [18:0] s_a_d2;

    reg signed [8:0] Gx, Gy;
    reg s_v_d3; reg [18:0] s_a_d3;
    reg [11:0] final_color_d3;

    reg [8:0] sum_G;


    // ==========================================
    // INITIALIZATION (Prevents 'xxx' in Sim)
    // ==========================================
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            g_rgb_buf1[i] = 0; g_rgb_buf2[i] = 0;
            s_gray_buf1[i] = 0; s_gray_buf2[i] = 0; s_color_buf[i] = 0;
        end
        wr_ptr_g = 0; wr_ptr_s = 0;
        g_in_d1 = 0; g_v_d1 = 0; g_a_d1 = 0; ptr_g_d1 = 0; g_r1_read = 0; g_r2_read = 0;
        g00 = 0; g01 = 0; g02 = 0; g10 = 0; g11 = 0; g12 = 0; g20 = 0; g21 = 0; g22 = 0;
        g_v_d2 = 0; g_a_d2 = 0;
        sum_R_r1 = 0; sum_R_r2 = 0; sum_R_r3 = 0; tot_R = 0;
        sum_G_r1 = 0; sum_G_r2 = 0; sum_G_r3 = 0; tot_G = 0;
        sum_B_r1 = 0; sum_B_r2 = 0; sum_B_r3 = 0; tot_B = 0;
        g_v_d3 = 0; g_a_d3 = 0; g_v_d4 = 0; g_a_d4 = 0; smoothed_rgb = 0;
        
        s_in_d1 = 0; s_v_d1 = 0; s_a_d1 = 0; ptr_s_d1 = 0; s_r1_read = 0; s_r2_read = 0;
        s_color_in_d1 = 0; s_color_r1_read = 0;
        s00 = 0; s01 = 0; s02 = 0; s10 = 0; s12 = 0; s20 = 0; s21 = 0; s22 = 0;
        c12 = 0; c11 = 0; s_v_d2 = 0; s_a_d2 = 0;
        Gx = 0; Gy = 0; s_v_d3 = 0; s_a_d3 = 0; final_color_d3 = 0; sum_G = 0;
        pixel_valid_out = 0; pixel_addr_out = 0; pixel_data_out = 0;
    end

    // =========================================================================
    // PART 1: FULL COLOR GAUSSIAN BLUR
    // =========================================================================
    
    always @(posedge clk) begin
        if (rst || !href) wr_ptr_g <= 0;
        else if (pixel_valid_in) wr_ptr_g <= wr_ptr_g + 1;
    end

    // Cycle 1: Fetch
    always @(posedge clk) begin
        g_in_d1  <= pixel_data_in; g_v_d1 <= pixel_valid_in; g_a_d1 <= pixel_addr_in; ptr_g_d1 <= wr_ptr_g;
        g_r1_read <= g_rgb_buf1[wr_ptr_g]; g_r2_read <= g_rgb_buf2[wr_ptr_g];
    end

    // Cycle 2: Shift Window
    always @(posedge clk) begin
        g_v_d2 <= g_v_d1; g_a_d2 <= g_a_d1;
        if (g_v_d1) begin
            g_rgb_buf1[ptr_g_d1] <= g_in_d1; g_rgb_buf2[ptr_g_d1] <= g_r1_read;
            g02 <= g_in_d1;   g01 <= g02; g00 <= g01;
            g12 <= g_r1_read; g11 <= g12; g10 <= g11;
            g22 <= g_r2_read; g21 <= g22; g20 <= g21;
        end
    end

    // Cycle 3: RGB Gaussian Row Sums
    always @(posedge clk) begin
        g_v_d3 <= g_v_d2; g_a_d3 <= g_a_d2;
        // RED
        sum_R_r1 <= g00[11:8] + (g01[11:8] << 1) + g02[11:8];
        sum_R_r2 <= (g10[11:8] << 1) + (g11[11:8] << 2) + (g12[11:8] << 1);
        sum_R_r3 <= g20[11:8] + (g21[11:8] << 1) + g22[11:8];
        // GREEN
        sum_G_r1 <= g00[7:4] + (g01[7:4] << 1) + g02[7:4];
        sum_G_r2 <= (g10[7:4] << 1) + (g11[7:4] << 2) + (g12[7:4] << 1);
        sum_G_r3 <= g20[7:4] + (g21[7:4] << 1) + g22[7:4];
        // BLUE
        sum_B_r1 <= g00[3:0] + (g01[3:0] << 1) + g02[3:0];
        sum_B_r2 <= (g10[3:0] << 1) + (g11[3:0] << 2) + (g12[3:0] << 1);
        sum_B_r3 <= g20[3:0] + (g21[3:0] << 1) + g22[3:0];
    end

    // Cycle 4: Total Sums & Output Bridge
    always @(posedge clk) begin
        g_v_d4 <= g_v_d3; g_a_d4 <= g_a_d3;
        tot_R = sum_R_r1 + sum_R_r2 + sum_R_r3;
        tot_G = sum_G_r1 + sum_G_r2 + sum_G_r3;
        tot_B = sum_B_r1 + sum_B_r2 + sum_B_r3;
        smoothed_rgb <= {tot_R[7:4], tot_G[7:4], tot_B[7:4]}; // Divide by 16
    end

    // =========================================================================
    // PART 2: SOBEL EDGE DETECTION & COLOR SHADOW OVERLAY
    // =========================================================================
    
    // Convert Smoothed RGB to 6-bit Grayscale for Sobel Math
    wire [5:0] smoothed_gray = {2'b00, smoothed_rgb[11:8]} + {2'b00, smoothed_rgb[7:4]} + {2'b00, smoothed_rgb[3:0]};

    always @(posedge clk) begin
        if (rst || !href) wr_ptr_s <= 0;
        else if (g_v_d4) wr_ptr_s <= wr_ptr_s + 1;
    end

    // Cycle 5: Fetch Sobel Rows + Color Shadow
    always @(posedge clk) begin
        s_in_d1 <= smoothed_gray; s_v_d1 <= g_v_d4; s_a_d1 <= g_a_d4; ptr_s_d1 <= wr_ptr_s;
        s_r1_read <= s_gray_buf1[wr_ptr_s]; s_r2_read <= s_gray_buf2[wr_ptr_s];
        
        // Track the smoothed color into the shadow buffer
        s_color_in_d1 <= smoothed_rgb;
        s_color_r1_read <= s_color_buf[wr_ptr_s];
    end

    // Cycle 6: Shift Sobel Window
    always @(posedge clk) begin
        s_v_d2 <= s_v_d1; s_a_d2 <= s_a_d1;
        if (s_v_d1) begin
            s_gray_buf1[ptr_s_d1] <= s_in_d1; s_gray_buf2[ptr_s_d1] <= s_r1_read;
            s02 <= s_in_d1;   s01 <= s02; s00 <= s01;
            s12 <= s_r1_read;             s10 <= s12; 
            s22 <= s_r2_read; s21 <= s22; s20 <= s21;
            
            // Shift the color to the center of the 3x3 window (c11)
            s_color_buf[ptr_s_d1] <= s_color_in_d1;
            c12 <= s_color_r1_read;
            c11 <= c12;
        end
    end

    // Cycle 7: Gradient Math
    always @(posedge clk) begin
        s_v_d3 <= s_v_d2; s_a_d3 <= s_a_d2;
        Gx <= $signed({3'b0, s02}) + $signed({2'b0, s12, 1'b0}) + $signed({3'b0, s22})
            - $signed({3'b0, s00}) - $signed({2'b0, s10, 1'b0}) - $signed({3'b0, s20});
             
        Gy <= $signed({3'b0, s00}) + $signed({2'b0, s01, 1'b0}) + $signed({3'b0, s02})
            - $signed({3'b0, s20}) - $signed({2'b0, s21, 1'b0}) - $signed({3'b0, s22});
            
        final_color_d3 <= c11; // Lock color
    end

    // Cycle 8: Absolute Sum & Final Overlay Mux
    always @(posedge clk) begin
        if (rst) begin
            pixel_valid_out <= 0; pixel_addr_out <= 0; pixel_data_out <= 0;
        end else begin
            pixel_valid_out <= s_v_d3;
            pixel_addr_out  <= s_a_d3;

            sum_G = (Gx[8] ? -Gx : Gx) + (Gy[8] ? -Gy : Gy); 

            // SUPERIMPOSE LOGIC
            // If it's an edge, draw a white pixel. Otherwise, draw the smoothed color pixel.
            if (sum_G > EDGE_THRESHOLD) begin
                pixel_data_out <= EDGE_COLOR; 
            end else begin                        
                pixel_data_out <= final_color_d3; 
            end
        end
    end

endmodule
