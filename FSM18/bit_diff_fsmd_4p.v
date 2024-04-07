module bit_diff_fsmd_4p
  #(
    parameter WIDTH=16
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
   state_t state_r, next_state;

   logic [$bits(data)-1:0]                      data_r, next_data;
   logic [$bits(result)-1:0]                    result_r, next_result;
   logic [$clog2(WIDTH)-1:0]                    count_r, next_count;
   logic signed [$bits(result)-1:0]             diff_r, next_diff;

   assign result = result_r;

   // Like the 3-process model, in the 4-process model, one process is always 
   // just an always_ff for the state register.
   always @(posedge clk or posedge rst)
      if (rst == 1'b1) state_r <= START;       
      else state_r <= next_state;

   // The second process is combinational logic solely for the next state
   // transitions.
   always_comb begin
      next_state = state_r;
            
      case (state_r)
        START : if (go == 1'b1) next_state = COMPUTE;
        COMPUTE : if (count_r == WIDTH-1) next_state = RESTART;
        RESTART : if (go == 1'b1) next_state = COMPUTE;
        default : next_state = XXX;
      endcase      
   end 
   
   // The 3rd process simply allocates all other registers.
   always @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin              
         result_r <= '0;   
         diff_r <= '0;   
         count_r <= '0;
         data_r <= '0;   
      end
      else begin         
         result_r <= next_result;
         diff_r <= next_diff;
         count_r <= next_count;
         data_r <= next_data;
      end      
   end // always @ (posedge clk or posedge rst)

   // The 4th process is all remaining combinational logic, which includes
   // non-registered output logic, and all non-state register inputs.
   always_comb begin
      
      next_result = result_r;
      next_diff = diff_r;
      next_data = data_r;
      next_count = count_r;

      done = 1'b0;
      
      case (state_r)    
        START : begin      
           done = 1'b0;
           next_result = '0;       
           next_diff = '0;
           next_data = data;
           next_count = '0;
        end
        
        COMPUTE : begin 
           next_diff = data_r[0] == 1'b1 ? diff_r + 1'b1 : diff_r - 1'b1;
           next_data = data_r >> 1;
           next_count = count_r + 1'b1;
           if (count_r == WIDTH-1) next_result = next_diff;
        end

        RESTART : begin   
           done = 1'b1;            
           next_diff = '0;
           next_count = '0;
           next_data = data;
        end
      endcase     
   end      
endmodule

