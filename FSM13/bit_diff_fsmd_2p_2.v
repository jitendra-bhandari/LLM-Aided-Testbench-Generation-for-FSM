module bit_diff_fsmd_2p_2
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

   // Done is no longer registered, so we don't need it in this block.
   always_ff @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin
         result_r <= '0;
         diff_r <= '0;   
         count_r <= '0;
         data_r <= '0;   
         state_r <= START;       
      end
      else begin
         result_r <= next_result;
         diff_r <= next_diff;
         count_r <= next_count;
         data_r <= next_data;
         state_r <= next_state;
      end 
   end 

   always_comb begin
      
      next_result = result_r;
      next_diff = diff_r;
      next_data = data_r;
      next_count = count_r;
      next_state = state_r;

      // Done is combinational logic in this module, so it doesn't have a 
      // "next" version. 
      done = 1'b0;
      
      case (state_r)    
        START : begin      
           done = 1'b0;
           next_result = '0;       
           next_diff = '0;
           next_data = data;
           next_count = '0;

           if (go == 1'b1) begin
              next_state = COMPUTE;
           end
        end
        
        COMPUTE : begin 

           next_diff = data_r[0] == 1'b1 ? diff_r + 1'b1 : diff_r - 1'b1;
           next_data = data_r >> 1;
           next_count = count_r + 1'b1;

           if (count_r == WIDTH-1) begin
              next_state = RESTART;

              // For us to be able to assert done in the next cycle, we need
              // to send the new diff to the result register this cycle. Also, 
              // we need to use the next version of diff since the register 
              // won't be updated yet.
              next_result = next_diff;
           end
        end

        // The restart state is now identical to the start state with the
        // exception of the done signal, which is now asserted. Basically, the
        // logic for done has been moved from a separate register into logic
        // based on the state register.
        RESTART : begin   
           done = 1'b1;            
           next_diff = '0;
           next_count = '0;
           next_data = data;

           // Since done is now combinational logic, we don't want to clear it
           // here otherwise it will be cleared in the same cycle that go
           // is asserted. If that is desired behavior, it is fine to do so,
           // but the specification for this module requires done to be cleared
           // one cycle after the assertion of go.
           //
           // One reason to avoid clearing done within the same cycle as go is
           // that if the logic for go outside this module depends on done,
           // it creates a combinational loop. The 1-cycle delay avoids that
           // problem.
           if (go == 1'b1) next_state = COMPUTE;
        end

        default : next_state = XXX;
      endcase     
   end      
endmodule


