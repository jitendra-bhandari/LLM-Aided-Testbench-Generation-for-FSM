module bit_diff_fsmd_3p
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

   // In the 3-process model, one process is always just an always_ff for
   // the state register.
   always @(posedge clk or posedge rst)
      if (rst == 1'b1) state_r <= START;       
      else state_r <= next_state;
   
   // The second process is another always_ff (usually assuming no blocking
   // assignments) that handles all the other registered logic. In other words,
   // we have simply taken the one always_ff block from the previous module and
   // separated it into two: one for the state register, and one for everything
   // else.
   always @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin              
         result_r <= '0;   
         diff_r <= '0;   
         count_r <= '0;
         data_r <= '0;   
      end
      else begin
         case (state_r)
           START : begin
              result_r <= '0;
              diff_r <= '0;
              count_r <= '0;
              data_r <= data;
           end

           COMPUTE : begin
              diff_r = data_r[0] == 1'b1 ? diff_r + 1'b1 : diff_r - 1'b1;  
              data_r <= data_r >> 1;
              count_r <= count_r + 1'b1;
              if (count_r == WIDTH-1) result_r <= diff_r;
           end

           RESTART : begin
              count_r <= '0;
              data_r <= data;
              diff_r <= '0;                                            
           end
         endcase          
      end      
   end

   // The third process handles all the combinational logic, which is identical
   // to the previous example.
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

