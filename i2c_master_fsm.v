module i2c_master_fsm 
(
    input wire clk,
    input wire trigger,
    input wire [6:0] address,                   // 7-bit addressess                    |   these both lines combined together
    input wire rw,                              // 0 = write, 1 = read                 |   is a single data packet that is used 
    input wire [7:0] din,
    
    output reg [7:0] dout,
    output reg sclk,
    output reg sda_dir = 1,                   // 1 = output from master , 0 = input for master (for ACK)
                  
    inout wire sda
    
);

                                        
parameter                 IDLE                              =          4'd0,                               
                          START                             =          4'd1,           
                          SEND_ADDRESS                      =          4'd2,                              
                          ADDRESS_ACK                       =          4'd3,               
                          SEND_DATA                         =          4'd4,                
                          DATA_ACK                          =          4'd5,               
                          RECEIVE                           =          4'd6,             
                          MASTER_ACK                        =          4'd7,                  
                          STOP                              =          4'd8,            
                          END                               =          4'd9;


reg [3:0] shift_reg_counter = 0;
reg [7:0] clk_counter = 0;
reg [7:0] shift_reg = 0;
reg [3:0] state = IDLE;
reg sda_out = 1;
reg temp = 0;


    assign sda = sda_dir ? sda_out : 1'bz;             // tri-state SDA


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
    
        if (clk_counter == 125)            
            begin
                sda_out <= 0;              
                clk_counter <= 0;
                state <= SEND_ADDRESS;
            end 
        
        else 
            begin
                clk_counter <= clk_counter + 1;             
            end
        end



    SEND_ADDRESS: begin
    
        if (clk_counter == 125)                                            
            begin
                clk_counter <= 0;
                sclk <= ~sclk;
            
                    if (sclk == 0)                                  
                        begin 
                            sda_out <= shift_reg[7];                               
                            shift_reg <= {shift_reg[6:0], 1'b0};                  
                
                                if(temp == 0) 
                                    begin
                                        shift_reg_counter <= 0;
                                        temp <= 1;
                                    end
                
                    else 
                        begin
                        
                            if (shift_reg_counter == 7 && sclk == 0)              
                                begin
                                    shift_reg_counter <= 0;
                                    sda_dir <= 0;                                 
                                    state <= ADDRESS_ACK;                         
                                end
                    
                        else 
                            begin
                                shift_reg_counter <= shift_reg_counter + 1;      
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
                
                                    if (!rw)                                              
                                        begin
                                            shift_reg <= din;
                                            state <= SEND_DATA;
                                            temp <= 0;
                                        end 
                                        
                                    else               
                                        begin
                                            state <= RECEIVE;
                                        end
                                end
            
                    else 
                        begin  // NACK received
                            state <= STOP; 
                        end 
            end
        end
        
        else begin
            clk_counter <= clk_counter + 1;
       end
       
    end
    

    SEND_DATA: begin                                                           
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
    

    RECEIVE: begin                                  
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
            sda_out <= 1;                                                    
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

