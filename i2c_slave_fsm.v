module i2c_slave_fsm
(
    input wire clk,            
    inout wire sda,            
    input wire sclk,
    input sda_dir_m
);

parameter SLAVE_ADDRESS = 7'b1010001;

reg [4:0] state = 0;
reg sda_out = 1'b1;
reg [7:0] shift_reg = 0;
reg [7:0] clk_counter = 0;
reg [7:0] sclk_counter  = 0 ;
reg [3:0] shift_reg_counter = 0;


        assign sda = sda_dir_m ?  1'bz : sda_out;


parameter       IDLE                             =      4'd0,
                          ADDR_st                      =      4'd1,
                          ADDR_ACK                  =      4'd2,
                          DATA                           =      4'd3,
                          DATA_ACK                  =       4'd4,
                          STOP_CONDITIONS    =      4'd5,
                          END                                 =      4'd6;



reg temp = 0;
reg temp2 = 0;
reg ack_pass = 0;
reg sclk_prev = 1'b1;
reg sda_prev = 1'b1;



wire start_condition = (sda_prev == 1 && sda == 0 && sclk == 1);         //  Start Condition (SDA goes low while SCLK is high)

wire stop_condition = (sda_prev == 0 && sda == 1 && sclk == 1);         // Stop Condition (SDA goes high while SCLK is high)


always @(posedge clk) 
        begin

            if(clk_counter == 125)
                begin
                    sda_prev <= sda;
                    sclk_prev <= sclk;
                end
    
            else
                begin
                    clk_counter <= clk_counter + 1;
                end

        end

always @(posedge clk) 
    begin
      

case (state)

    IDLE: begin
    
        shift_reg_counter <= 0;
        
            if (start_condition) 
                begin
                    state <= ADDR_st;
                end 
end 
            
            

    ADDR_st: begin
    
        if (sclk_prev == 1 && sclk == 0) 
            begin
                shift_reg <= {shift_reg[6:0], sda};
            
                    if(temp == 0) 
                        begin
                            shift_reg_counter <= 0; 
                            temp <= 1;
                        end
                        
        else 
            begin
                shift_reg_counter <= shift_reg_counter + 1;
            end
            
                if (shift_reg_counter == 7 )                              
                    begin
                        shift_reg_counter <= 0;
                        temp2 <= 1;
                        state <= ADDR_ACK;
                    end
          end
end




    ADDR_ACK: begin
    
       if (sclk_prev == 0 && sclk == 1) 
        begin
        
            if (shift_reg[7:1] == SLAVE_ADDRESS) 
                begin                                   
                    sda_out <= 0;  // ACK
                    ack_pass <= 1;
                    
                // this has been added now onlyyy    
                if (sclk_prev == 1 && sclk == 0) 
                begin
                    state <= DATA;
                    ack_pass <= 0;
                end
                // till here    
                    
                    
                end 
            
            else 
                begin
                    sda_out <= 1;  // NACK
                    ack_pass <= 0;
                    state <= IDLE;
                end
        end
end
    


    DATA: begin
    
        if (sclk_prev == 1 && sclk == 0) 
            begin
                shift_reg <= {shift_reg[6:0], sda};
                shift_reg_counter <= shift_reg_counter + 1;
            end
            
        if (shift_reg_counter == 7 && sclk_prev == 1 && sclk == 0) 
            begin
                shift_reg_counter <= 0;
                state <= DATA_ACK;
            end
end




    DATA_ACK: begin
    
           if (sclk_prev == 0 && sclk == 1)  
                begin
                     if (shift_reg[7:0] == 8'hAB)  
                        begin                                   
                            sda_out <= 0;  // ACK
                            ack_pass <= 1;
                        end 
                        
                        else 
                            begin
                                sda_out <= 1;  // NACK
                                ack_pass <= 0;
                            end
                end
        
        if (sclk_prev == 1 && sclk == 0) 
            begin
                state <= STOP_CONDITIONS;
                ack_pass <= 0;
            end              
end
    
    
    STOP_CONDITIONS: begin
    
    if (stop_condition) 
        begin
            state <= IDLE;
        end
end


    END: begin
        sda_out <= 1;
       
    end



    default: state <= END;



    endcase


end

//if(

endmodule