module bit_diff_fsmd_2p_3
  #(
    parameter WIDTH
    )
   (
    input logic                                 clk,
    input logic                                 rst,
    input logic                                 go,
    input logic [WIDTH-1:0]                     data,
    output logic signed [$clog2(2*WIDTH+1)-1:0] result,
    output logic                                done    
    );
   
   typedef enum logic[1:0] {START, COMPUTE, RESTART, XXX='x} state_t;
   state_t state_r;

   logic [$bits(data)-1:0]                      data_r;
   logic [$bits(result)-1:0]                    result_r;
   logic [$clog2(WIDTH)-1:0]                    count_r;
   logic signed [$bits(result)-1:0]             diff_r;

   assign result = result_r;

   // Note that this code is almost identical to a 1-process FSMD. We have
   // simply removed the done logic.
   always @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin              
         result_r <= '0;   
         diff_r <= '0;   
         count_r <= '0;
         data_r <= '0;   
         state_r <= START;       
      end
      else begin         
         case (state_r)
           START : begin
              result_r <= '0;
              diff_r <= '0;
              count_r <= '0;
              data_r <= data;              
              if (go == 1'b1) state_r <= COMPUTE;              
           end

           COMPUTE : begin
              diff_r = data_r[0] == 1'b1 ? diff_r + 1'b1 : diff_r - 1'b1;  
              data_r <= data_r >> 1;
              count_r <= count_r + 1'b1;
              if (count_r == WIDTH-1) begin
                 result_r <= diff_r;
                 state_r <= RESTART; 
              end
           end

           RESTART : begin
              count_r <= '0;
              data_r <= data;
              diff_r <= '0;                              
              if (go == 1'b1) state_r <= COMPUTE;
           end

           default : state_r <= XXX;
         endcase          
      end      
   end

   // Since we actually want registers for all the code above, it is not
   // necessary to add next signals for any of them, including the state_r.
   // Instead, we'll just pull out the done_r signal and make it combinational
   // logic in this process.
   always_comb begin
      case (state_r)
         START : begin 
            done = 1'b0;
         end
        
        COMPUTE : begin 
            done = 1'b0;
         end

        RESTART : begin
           done = 1'b1;
        end     
      endcase 
      
      // Could be simplified to the following if you never plan on having any
      // other logic in this process.
      // done = state_r == RESTART;
   end   
endmodule

