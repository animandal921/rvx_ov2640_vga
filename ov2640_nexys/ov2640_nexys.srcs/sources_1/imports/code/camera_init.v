module camera_init(
    input clk,
    input rst,
    output sio_c,
    inout sio_d,
    output reset,
    output pwdn,
    output xclk
);

    assign reset=1;
    assign pwdn=0;

    pullup up (sio_d);
    assign xclk=clk;
    wire [15:0] data_send;
    wire reg_ok,sccb_ok;
    reg_init init(.clk(clk),.rst(rst),.data_out(data_send),.reg_ok(reg_ok),.sccb_ok(sccb_ok));
    sccb_sender sender(.clk(clk),.rst(rst),.sio_d(sio_d),.sio_c(sio_c),.reg_ok(reg_ok),.sccb_ok(sccb_ok),.slave_id(8'h60),.reg_addr(data_send[15:8]),.value(data_send[7:0]));

endmodule