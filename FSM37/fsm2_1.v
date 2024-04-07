module fsm2
  (
   input logic  clk,
   input logic  rst,
   input logic  go,
   input logic  count_done,
   output logic done,
   output logic data_sel,
   output logic data_en,
   output logic diff_rst,
   output logic diff_en,
   output logic count_rst,
   output logic count_en,
   output logic result_en
   );
   
   typedef enum logic[1:0] {START, COMPUTE, RESTART, XXX='x} state_t;
   state_t state_r, next_state;

   always_ff @(posedge clk or posedge rst) begin
      if (rst) state_r <= START;
      else state_r <= next_state;      
   end

   always_comb begin

      done = 1'b0;

      result_en = 1'b0;
      diff_en = 1'b0;
      count_en = 1'b0;
      data_en = 1'b0;

      data_sel = 1'b0;

      // Use resets now instead of selects.
      diff_rst = 1'b0;
      count_rst = 1'b0;

      next_state = state_r;
      
      case (state_r)
        START : begin

           // Replaces diff_r <= '0;
           diff_rst = 1'b1;
           
           // Replaces count_r <= '0;
           count_rst = 1'b1;
           
           // Replaces data_r <= data
           data_en = 1'b1;
           data_sel = 1'b1;       
           
           if (go) next_state = COMPUTE;
        end

        COMPUTE : begin
           
           // Replaces diff_r <= data_r[0] == 1'b1 ? diff_r + 1 : diff_r - 1;  
           diff_en = 1'b1;

           // Replaces data_r <= data_r >> 1;
           data_en = 1'b1;

           // Replaces count_r <= count_r + 1;
           count_en = 1'b1;

           // Replaces count_r == WIDTH-1
           if (count_done) begin
              result_en = 1'b1;       
              next_state = RESTART;
           end
        end

        RESTART : begin
           done = 1'b1;

           // Replaces diff_r <= '0;
           diff_rst = 1'b1;
           
           // Replaces count_r <= '0;
           count_rst = 1'b1;
           
           // Replaces data_r <= data
           data_en = 1'b1;
           data_sel = 1'b1;       

           if (go) next_state = COMPUTE;           
        end     

        default : next_state = XXX;
      endcase            
   end 
endmodule

