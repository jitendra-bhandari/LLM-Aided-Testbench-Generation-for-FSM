module bit_diff_fsmd_1p_2
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

   // This could potentially just be one bit, but we generally want FPGA
   // synthesis to use one-hot encoding. In Quartus, it doesn't matter because
   // it will ignore the width unless it is smaller than what is needed for
   // a binary encoding.
   typedef enum logic[1:0] {START, COMPUTE, XXX='x} state_t;
   state_t state_r;

   logic [$bits(data)-1:0]                      data_r;
   logic [$bits(result)-1:0]                    result_r;
   logic [$clog2(WIDTH)-1:0]                    count_r;
   logic signed [$bits(result)-1:0]             diff_r;
   logic                                        done_r;
   
   assign result = result_r;
   assign done = done_r;
   
   // For this version, we can't use an always_ff because we have to use a
   // blocking assignment in one state.
   always @(posedge clk or posedge rst) begin
      if (rst == 1'b1) begin     
         
         result_r <= '0;
         done_r <= 1'b0;                 
         diff_r <= '0;   
         count_r <= '0;
         data_r <= '0;   
         state_r <= START;       
      end
      else begin         
         case (state_r)
           // In this version, we no longer set done_r to 0 in this state.
           // We omit this code because reset will initialize the done
           // register. Also, we want to eliminate the restart state,
           // which requires the START state to provide the same done
           // functionality. To accomplish that goal, the new START state
           // simply preserves the value of done_r.        
           START : begin
              diff_r <= '0;        
              count_r <= '0;
              data_r <= data;

              if (go == 1'b1) begin
                 // In this version, we have to clear done when circuit is
                 // started because the START state just preserves the
                 // previous value.
                 done_r <= 1'b0;                 
                 state_r <= COMPUTE;
              end
           end

           COMPUTE : begin
              // We need a blocking assignment here because we need to
              // potentially assign the output the next value of diff.
              diff_r = data_r[0] == 1'b1 ? diff_r + 1'b1 : diff_r - 1'b1;
              data_r <= data_r >> 1;
              count_r <= count_r + 1'b1;

              if (count_r == WIDTH-1) begin

                 // By assigning these here, we can get rid of the RESTART
                 // state entirely.
                 done_r <= 1'b1;
                 result_r <= diff_r;             
                 state_r <= START;
              end
           end     

           default : state_r <= XXX;       
         endcase          
      end      
   end   
endmodule

