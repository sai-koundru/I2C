`timescale 1ns / 1ps

module i2c_master_fsm_tb;

    reg clk = 0;
    reg trigger = 0;
    reg [6:0] address = 7'h50;       // Example I2C addressess
    reg rw = 0;                      // Write operation
    reg [7:0] din = 8'hA5;           // Data to send
    wire [7:0] dout;
    wire sda;
    wire sclk;

    // Instantiate the I2C master
    i2c_master_fsm uut (        .clk(clk),        .trigger(trigger),        .address(address),        .rw(rw),        .din(din),        .dout(dout),        .sda(sda),        .sclk(sclk)    );

    always #5 clk = ~clk;  // 10ns clock period

    initial 
        begin
        
        // Wait for a few clock cycles
        #100;

        // Trigger a write
        trigger = 1;
        #20;
        trigger = 0;

        #100000;

        // Trigger a read
        rw = 1;
        trigger = 1;
        #20;
        trigger = 0;

        #100000;

        $finish;
    end

endmodule
