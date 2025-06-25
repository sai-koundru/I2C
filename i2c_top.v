module i2c_top
(
    input wire clk,
    input wire trigger,
    input wire [6:0] address,
    input wire rw,
    input wire [7:0] din,

    output wire [7:0] dout,
    output wire sclk,
    output wire sda_dir,
    
    inout wire sda
);

    i2c_master_fsm master_inst ( .clk(clk), .trigger(trigger), .address(address), .rw(rw), .din(din), .dout(dout), .sclk(sclk), .sda(sda), .sda_dir(sda_dir)  );

    i2c_slave_fsm slave_inst ( .clk(clk), .sclk(sclk), .sda(sda), .sda_dir_m(sda_dir) );

endmodule
