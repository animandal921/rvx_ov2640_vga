module camera_get_pic (
    input rst,
    input pclk,
    input href,
    input vsync,
    input [7:0]data_in,
    output reg[11:0]data_out,
    output reg wr_en,
    output reg[18:0]out_addr=0
    );


    reg [15:0] rgb565 = 0;
    reg  [18:0] next_addr = 0;
    reg [1:0] status = 0;
    
    
    always@ (posedge pclk)
        begin
        if(vsync == 0)
            begin
                out_addr <=0;
                next_addr <= 0;
                status=0;
            end
        else
            begin
                data_out <= {rgb565[15:12],rgb565[10:7],rgb565[4:1]};
                out_addr <= next_addr;
                wr_en <= status[1];
                status <= {status[0], (href && !status[0])};
                rgb565 <= {rgb565[7:0], data_in};
                    
                if(status[1] == 1)
                    begin
                        next_addr <= next_addr+1;
                    end
                end
        end

endmodule