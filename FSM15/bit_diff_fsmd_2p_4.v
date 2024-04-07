module bit_diff_fsmd_2p_4
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

   logic [$bits(data)-1:0]                      data_r;
   logic [$bits(result)-1:0]                    result_r;
   logic [$clog2(WIDTH)-1:0]                    count_r;
   logic signed [$bits(result)-1:0]             diff_r;

   assign result = result_r;

   always @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin              
         result_r <= '0;   
         diff_r <= '0;   
         count_r <= '0;
         data_r <= '0;   
         state_r <= START;       
      end
      else begin

         // To add the next_state variable, this process now simply creates
         // the state register.
         state_r <= next_state;

         // All other signals are still registered without a next version, since
         // we don't have a need for the next version.
         case (state_r)
           START : begin
              result_r <= '0;
              diff_r <= '0;
              count_r <= '0;
              data_r <= data;
              // Notice there is no next-state logic here anymore. It is moved
              // to the combinational process.
           end

           COMPUTE : begin
              diff_r = data_r[0] == 1'b1 ? diff_r + 1'b1 : diff_r - 1'b1;  
              data_r <= data_r >> 1;
              count_r <= count_r + 1'b1;
              // This is non-ideal, but we have to replicate the 
              // transition-sensitive logic here. One disadvantage of this
              // approach is that replicating this logic is error prone because
              // if we change it in one place, we might forget to change it in
              // another.
              // We could also change result to have a next version, and move
              // this transition entirely to the combinational process.
              if (count_r == WIDTH-1) begin
                 result_r <= diff_r;           
              end
           end

           RESTART : begin
              count_r <= '0;
              data_r <= data;
              diff_r <= '0;                                            
           end
         endcase          
      end      
   end

   // In this version, we have done here since it isn't registered, in addition
   // to the next_state logic, so we can see both the current state and the
   // next state.
   always_comb begin

      next_state = state_r;
      
      case (state_r)
         START : begin 
            done = 1'b0;
            if (go == 1'b1) next_state = COMPUTE;
         end
        
        COMPUTE : begin 
           done = 1'b0;
           if (count_r == WIDTH-1) next_state = RESTART;    
        end
        
        RESTART : begin
           done = 1'b1;
           if (go == 1'b1) next_state = COMPUTE;
        end  

        default : next_state = XXX;  
      endcase      
   end   
endmodule
