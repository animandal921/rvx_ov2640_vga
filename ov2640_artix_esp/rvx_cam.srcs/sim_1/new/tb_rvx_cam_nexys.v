`timescale 1ns/1ps

module tb_rvx_cam_nexys();

    // 1. Parameters
    parameter GPIO_WIDTH = 3;

    // 2. Testbench Signals (Inputs to UUT)
    reg clock;
    reg reset;
    reg uart_rx;
    reg pclk;
    reg href;
    reg vsync;
    reg [7:0] camera_data;

    // 3. Testbench Signals (Outputs from UUT)
    wire uart_tx;
    wire sio_c;
    wire cam_reset;
    wire cam_pwdn;
    wire xclk;
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;
    wire vga_x_valid;
    wire vga_y_valid;

    // 4. Testbench Signals (Bidirectional)
    wire [GPIO_WIDTH-1:0] gpio;
    wire sio_d;

    // 5. Instantiate the Unit Under Test (UUT)
    rvx_cam_nexys #(
        .GPIO_WIDTH(GPIO_WIDTH)
    ) uut (
        .clock(clock),
        .reset(reset),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .gpio(gpio),
        .sio_c(sio_c),
        .sio_d(sio_d),
        .cam_reset(cam_reset),
        .cam_pwdn(cam_pwdn),
        .xclk(xclk),
        .pclk(pclk),
        .href(href),
        .vsync(vsync),
        .camera_data(camera_data),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_x_valid(vga_x_valid),
        .vga_y_valid(vga_y_valid)
    );

    // --------------------------------------------------------
    // 6. Virtual Physical Switches (Simulating Human Input)
    // --------------------------------------------------------
    reg [2:0] virtual_switches;
    
    // Drive the bidirectional GPIO bus with our virtual switches
    assign gpio = virtual_switches;

    // Sequence to flip the switches over time
    initial begin
        // Start with all switches OFF (000)
        virtual_switches = 3'b000;
        
        // Wait 500,000 ns (500us) to give the RISC-V core 
        // plenty of time to boot and enter the while(1) loop
        #500000;
        
        $display("[%0t] TEST: Flipping SW0 HIGH (e.g., Camera Enable)", $time);
        virtual_switches = 3'b001; 
        
        // Wait another 500us
        #500000;
        
        $display("[%0t] TEST: Flipping SW1 HIGH (e.g., Filter Enable)", $time);
        virtual_switches = 3'b011; 
        
        // Wait another 500us
        #500000;
        
        $display("[%0t] TEST: Flipping SW2 HIGH", $time);
        virtual_switches = 3'b111; 
    end

    // 7. Clock Generation
    // 100 MHz Nexys System Clock (10ns period)
    initial clock = 0;
    always #5 clock = ~clock;

    // ~24 MHz Camera PCLK (41.66ns period)
    initial pclk = 0;
    always #20.83 pclk = ~pclk;

    // 8. Main Test Sequence
    initial begin
        // Initialize Inputs
        uart_rx = 1'b1;
        href = 1'b0;
        vsync = 1'b0;
        camera_data = 8'h00;
        
        // Assert Reset (Nexys CPU_RESETN is active-low, so 0 means pressed)
        reset = 1'b0; 
        
        $display("[%0t] Simulation Started. Holding reset...", $time);

        // Wait 200ns, then release reset
        #200;
        reset = 1'b1; 
        $display("[%0t] Reset Released. RVX Core Booting...", $time);

        // Let the simulation run for 5 milliseconds to allow C code execution 
        // and several VGA line draws.
        #5000000; 

        $display("[%0t] Simulation Finished.", $time);
        $finish;
    end

    // 9. Dummy Camera Data Generator
    // This process simulates the camera sending frames so your VGA buffer doesn't starve
    always begin
        #50000; // Initial delay before the camera "wakes up"
        
        // VSYNC Pulse (Start of a new frame)
        vsync = 1'b1;
        #20000;
        vsync = 1'b0;
        #10000;
        
        // Generate a few lines of video data (HREF)
        repeat(10) begin
            href = 1'b1;
            camera_data = 8'hA5; // Fake pixel byte (10100101)
            
            // Hold HREF high for the active video period
            #15000; 
            
            href = 1'b0;
            camera_data = 8'h00;
            
            // Wait for the horizontal blanking period
            #5000; 
        end
    end

endmodule