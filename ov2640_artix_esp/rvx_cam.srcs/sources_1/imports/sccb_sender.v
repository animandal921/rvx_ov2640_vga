module sccb_sender(
    input clk,
    input rst,
    inout sio_d,
    output reg sio_c,
    input reg_ok,
    output reg sccb_ok=0,
    input [7:0]slave_id,
    input [7:0]reg_addr,
    input [7:0]value
);
    reg [20:0]count=0;
    
    always @ (posedge clk)
    begin
        if(count==0)
            count<=reg_ok;
        else
            if(count[20:11]==31)
                count<=0;
            else
                count<=count+1;
    end

    always @ (posedge clk)
    begin
        sccb_ok<=(count==0)&&(reg_ok==1);
    end

    reg sio_d_send;
    always @ (posedge clk)
    begin
        if(count[20:11]==0)
            sio_c<=1;
        else if(count[20:11]==1)
        begin
            if(count[10:9]==2'b11)
                sio_c<=0;
            else
                sio_c<=1;
        end
        else if(count[20:11]==29)
        begin
            if(count[10:9]==2'b00)
                sio_c<=0;
            else
                sio_c<=1;
        end
        else if(count[20:11]==30||count[20:11]==31)
            sio_c<=1;
        else
        begin
            if(count[10:9]==2'b00)
                sio_c<=0;
            else if(count[10:9]==2'b01)
                sio_c<=1;
            else if(count[10:9]==2'b01)
                sio_c<=1;
            else if(count[10:9]==2'b11)
                sio_c<=0;
        end
    end

    always @ (posedge clk)
    begin
        if(count[20:11]==10||count[20:11]==19||count[20:11]==28)
            sio_d_send<=0;
        else
            sio_d_send<=1;
    end

    reg [31:0] data_temp;
    always @ (posedge clk)
    begin
        if(rst)
            data_temp<=32'hffffffff;
        else
        begin
            if(count==0&&reg_ok==1)
                data_temp<={2'b10,slave_id,1'bx,reg_addr,1'bx,value,1'bx,3'b011};
            else if(count[10:0]==0)
                data_temp<={data_temp[30:0],1'b1};
        end
    end

    assign sio_d=sio_d_send?data_temp[31]:'bz;
endmodule