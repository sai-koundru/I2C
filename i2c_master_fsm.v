module i2c_master_fsm 
(
    input wire clk,
    input wire trigger,
    input wire [6:0] address,                   // 7-bit addressess                    |   these both lines combined together
    input wire rw,                                      // 0 = write, 1 = read                |   is a single data packet that is used 
    input wire [7:0] din,
    
    output reg [7:0] dout,
    output reg sclk,
    output reg sda_dir = 1,                   // 1 = output from master , 0 = input for master (for ACK)
                  
    inout wire sda
    
);

                                        
parameter     IDLE                              =          4'd0,                               
                          START                           =          4'd1,           
                          SEND_ADDRESS           =          4'd2,                              // so in this only we have both the address nd the r/w data        
                          ADDRESS_ACK             =          4'd3,               
                          SEND_DATA                 =          4'd4,                
                          DATA_ACK                   =          4'd5,               
                          RECEIVE                       =          4'd6,             
                          MASTER_ACK              =          4'd7,                  
                          STOP                            =          4'd8,            
                          END                               =         4'd9;

reg [3:0] state = IDLE;
reg [7:0] clk_counter = 0;
reg [7:0] shift_reg = 0;
reg [3:0] shift_reg_counter = 0;
reg sda_out = 1;
reg temp = 0;


    assign sda = sda_dir ? sda_out : 1'bz;                                      // tri-state SDA


    always @(posedge clk) 
        begin

        if (trigger) 
            begin
                shift_reg <= {address, rw};
                sda_out <= 1;
                sda_dir <= 1;
            end
        end



always @(posedge clk) 
begin

    case (state)

    IDLE: begin
    
        sclk <= 1;
        sda_out <= 1;
        clk_counter <= 0;
        shift_reg_counter <= 0;
        
        if(trigger == 1)
        begin
        state <= START;
        end
        end                         


    START: begin
    
        if (clk_counter == 125)            // so in this logic what is happening is that this logic is counting still 125 clk cycles of 100MHz clk and then it activates the start bit logic, but remember that it is not switching the sclk to 0-1-0-1 but it just counts the clk and exactly after 1 clk cycles it brings the start line down just like a RT system i.e. SDA = 0 when SCLK = 1
            begin
                sda_out <= 0;                   // dude this is only *kin start bit logic i.e. when the clk is high then the sda goes low which implies that it is a start bit
                clk_counter <= 0;
                state <= SEND_ADDRESS;
            end 
        
        else 
            begin
                clk_counter <= clk_counter + 1;             // so in this logic what we are doing is simple i.e. basically i am not operating based on the sclk instead i am triggering the logic in each block by counting on each cycle of the 100MHz CLK  
            end
        end



    SEND_ADDRESS: begin
    
        if (clk_counter == 125)                                              // so basically in this logic what is happening is that after every 125 clk_cycles of the clk the sclk gets triggered to 1-0-1-0-1....
            begin
                clk_counter <= 0;
                sclk <= ~sclk;
            
                    if (sclk == 0)                                  
                        begin 
                            sda_out <= shift_reg[7];                                 // so in this logic the sda line is being updated bit by bit in this the MSB bit is updated each time and this bit is being alloted to the sda_out
                            shift_reg <= {shift_reg[6:0], 1'b0};                  // after the MSB is shifted the LSB of shift_reg is updated by an 0 bit making all the bits to shift right by 1 bit this way the bits are all transmitted bit by bit
                
                                if(temp == 0) 
                                    begin
                                        shift_reg_counter <= 0;
                                        temp <= 1;
                                    end
                
                    else 
                        begin
                        
                            if (shift_reg_counter == 7 && sclk == 0)                // once all the data bits are sent the counter count reaches 8 this implies that all the bits have been sent completly and waits for the sclk to become 1when this happens the shift_reg_counter becomes 0, and the data line direction (sda_dir) changes from output =1 <--> output = 0 this means master is gettin the input from slave using sda 
                                begin
                                    shift_reg_counter <= 0;
                                    sda_dir <= 0;                                              // release SDA for ACK --> (so sda becomes input line for master)  fffffffffffffffffffffffffffffffffffffffffffffffffffff
                                    state <= ADDRESS_ACK;                               // goes to address_ack block of code
                                end
                    
                        else 
                            begin
                                shift_reg_counter <= shift_reg_counter + 1;      // this logic is used to count the bits remaining in the shift_reg
                                sda_dir <= 1;
                            end
                            
                        end
            end
        end 
        
        else 
            begin
                clk_counter <= clk_counter + 1;
            end 
    end
    
    
    
    ADDRESS_ACK: begin
    
        if (clk_counter == 125) 
            begin
                clk_counter <= 0;
                sclk <= ~sclk;
            
                    if (sclk == 1) 
                        begin
                        
                            if(sda == 0)
                                begin
                
                                    if (!rw)                                                // here this logic works if rw is 0   -->   write operation is being performed
                                        begin
                                            shift_reg <= din;
                                            state <= SEND_DATA;
                                            temp <= 0;
                                        end 
                                        
                                    else               // (rw)                                          // here this logic works if rw is 1   -->   read operation is being performed
                                        begin
                                            state <= RECEIVE;
                                        end
                                end
            
                    else 
                        begin  // NACK received
                            state <= STOP;  // Abort transaction
                        end 
            end
        end
        
        else begin
            clk_counter <= clk_counter + 1;
       end
       
    end
    

    SEND_DATA: begin                                                            // it is all the same logic as that of the SEND_ADDRESS 
        if (clk_counter == 125) 
        begin
            clk_counter <= 0;
            sclk <= ~sclk;
            
            if (sclk == 0) 
            begin
                sda_out <= shift_reg[7];
                shift_reg <= {shift_reg[6:0], 1'b0};
                if(temp == 0) begin
                    shift_reg_counter <= 0;
                    temp <= 1;
                    sda_dir <= 1;
                end
                else begin
                    shift_reg_counter <= shift_reg_counter + 1;
                end
                if (shift_reg_counter == 7 && sclk == 0) 
                begin
                    shift_reg_counter <= 0;
                    state <= DATA_ACK;
                    sda_dir <= 0;
                end
            end
        end 
        
        else begin
            clk_counter <= clk_counter + 1;
        end
      
    end


    DATA_ACK: begin
        if (clk_counter == 125) 
        begin
            clk_counter <= 0;
            sclk <= ~sclk;
            
            if (sclk == 1)   begin
                if(sda == 0) begin
                    state <= STOP;
                end
            end
        end 
        
        else 
        clk_counter <= clk_counter + 1;
    end
    

    RECEIVE: begin                                  // in this logic it majorly deals with the reciever part
        if (clk_counter == 125) 
        begin
            clk_counter <= 0;
            sclk <= ~sclk;
            
            if (sclk == 1) 
            begin
                dout <= {dout[6:0], sda};
                shift_reg_counter <= shift_reg_counter + 1;
            end
        end 
        
        else 
        clk_counter <= clk_counter + 1;

        if (shift_reg_counter == 8 && sclk == 1) 
        begin
            shift_reg_counter <= 0;
            sda_dir <= 1;
            sda_out <= 1;                                                       // Send NACK
            state <= MASTER_ACK;
        end
    end


    MASTER_ACK: begin
        if (clk_counter == 125) 
        begin
            clk_counter <= 0;
            sclk <= ~sclk;
            if (sclk == 1) 
            begin
                state <= STOP;
            end
        end 
        else 
        clk_counter <= clk_counter + 1;
    end




    STOP: begin
        if (clk_counter == 125) 
        begin
            clk_counter <= 0;
            sda_out <= 0;             
            sclk <= 1;
                #250;
                sda_out <= 1;
            state <= IDLE;
        end 

        else 
        clk_counter <= clk_counter + 1;
    end


    END: begin
        sda_out <= 1;
        sclk <= 1;
    end

    default: state <= END;



    endcase
    end

endmodule









