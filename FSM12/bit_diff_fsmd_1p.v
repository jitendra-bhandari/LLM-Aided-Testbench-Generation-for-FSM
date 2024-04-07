module bit_diff_fsmd_1p
  #(
    parameter WIDTH=16
    )
   (
    input logic                                 clk,
    input logic                                 rst,
    input logic                                 go,
    input logic [WIDTH-1:0]                     data,
   
    // The range of results can be from WIDTH to -WIDTH, which is
    // 2*WIDTH + 1 possible values, where the +1 includes 0.
    output logic signed [$clog2(2*WIDTH+1)-1:0] result,
    output logic                                done    
    );
   
   typedef enum logic[1:0] {START, COMPUTE, RESTART, XXX='x} state_t;
   // We only have one process, so we'll only have a state_r variable.
   state_t state_r;

   // Create variables for the internal registers.
   logic [$bits(data)-1:0]                      data_r;
   logic [$bits(result)-1:0]                    result_r;
   logic [$clog2(WIDTH)-1:0]                    count_r;
   logic signed [$bits(result)-1:0]             diff_r;
   logic                                        done_r;

   // These concurrent assignments aren't necessary, but they preserve the 
   // naming convention of having all registers use a _r suffix without 
   // requiring the outputs to have the suffix. I prefer to not name the
   // outputs based on the internal representation for several reasons. First,
   // there may be parameters for a module that change whether or not the
   // output is registered, which could make the suffix misleading. Second,
   // the user of the module usually doesn't need to know if an output is
   // registered. They might need to know the timing, but that can be specified
   // in documentation, which is more meaningful than just knowing the 
   // existence of a register. Finally, retiming might move all the registers
   // anyway, in which case there might not be a register on the output.
   //
   // For simple modules, this convention is overkill, but becomes useful when
   // using large modules because every variable that appears on the LHS of
   // an assignment within an always_ff should have a _r suffix. If you
   // accidentally assign a signal that isn't intended to be a register, then
   // the naming convention helps catch that mistake.
   assign result = result_r;
   assign done = done_r;

   // In the 1-process FSMD, everything is captured in a single always block.
   // It doesn't have to be an always_ff block in case there is combinational
   // logic mixed into the assignments, but use the always_ff when possible.
   always_ff @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin     
         
         result_r <= '0;
         done_r <= 1'b0;                 
         diff_r <= '0;   
         count_r <= '0;
         data_r <= '0;   
         state_r <= START;       
      end
      else begin

         done_r <= 1'b0;
         
         case (state_r)
           START : begin

              // Assign outputs.
              done_r <= 1'b0;
              result_r <= '0;
              
              // Initialize internal state.
              diff_r <= '0;
              count_r <= '0;
              data_r <= data;

              // Wait for go to be asserted.
              if (go == 1'b1) state_r <= COMPUTE;              
           end

           COMPUTE : begin

              // Add one to the difference if asserted, else subtract one.
              diff_r <= data_r[0] == 1'b1 ? diff_r + 1'b1 : diff_r - 1'b1;  

              // Shift out the current lowest bit.
              data_r <= data_r >> 1;

              // Update the count. IMPORTANT: count_r ++ would not work in this
              // situation. count_r ++ is equivalent to count_r = count_r + 1'b1
              // which uses a blocking assigning. The blocking assignment will
              // cause the following if statement to be off by 1. We could
              // potentially fix that issue by doing count_r == WIDTH, but that
              // would cause an infinite loop because count_r doesn't have
              // enough bits to ever represent WIDTH. We could make count_r
              // one bit wider, but that would increase area with no real
              // benefit. In addition, even if the ++ worked, we would be
              // using a block operator within an always_ff block, which could
              // cause synthesis/linter warnings.
              count_r <= count_r + 1'b1;

              // We are done after checking WIDTH bits. The -1 is used because
              // the count_r assignment is non-blocking, which means that
              //  count_r hasn't been updated with the next value yet. 
              // When subtracting from a variable, this would create an 
              // extra subtractor, which we definitely want to avoid. However, 
              // in this case, WIDTH is a parameter, which is treated as a 
              // constant. Synthesis will do constant propagation and replace 
              // WIDTH-1 with a constant, so this will just be a comparator.
              //
              // We could also use a blocking assignment in the previous
              // statement and then get rid of the -1, but since this is an
              // always_ff block, it could introduce warnings.
              if (count_r == WIDTH-1) state_r <= RESTART; 
           end

           // This state could easily be combined with START, but was done
           // this way on purpose to match the FSM+D version, where done is
           // not registered.
           RESTART : begin
              // Assign outputs.
              result_r <= diff_r;
              done_r <= 1'b1;

              // Reset internal state.
              count_r <= '0;
              data_r <= data;
              
              if (go == 1'b1) begin
                 // We need to clear diff_r here in case the FSMD stays in
                 // the restart state for multiple cycles, in which case
                 // result_r would only be valid for 1 cycle.
                 diff_r <= '0;
                 
                 // If we don't clear done here, then we'll get an assertion
                 // error because it will take an extra cycle for done to be
                 // cleared after the circuit is restarted.
                 done_r <= 1'b0;                 
                 state_r <= COMPUTE;
              end
           end 

           default : state_r <= XXX;
         endcase          
      end      
   end   
endmodule
