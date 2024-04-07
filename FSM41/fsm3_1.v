module fsm3
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
   
   typedef enum logic[2:0] {START, INIT, COMPUTE, RESTART, XXX='x} state_t;
   state_t state_r, next_state;

   logic        count_rst_r, next_count_rst;
   logic        diff_rst_r, next_diff_rst;

   // Register the controlled asynchronous resets to be safer.
   assign count_rst = count_rst_r;
   assign diff_rst = diff_rst_r;
   
   always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
         state_r <= START;
         count_rst_r <= 1'b1;
         diff_rst_r <= 1'b1;     
      end
      else begin
         state_r <= next_state;
         count_rst_r <= next_count_rst;
         diff_rst_r <= next_diff_rst;    
      end
   end

   always_comb begin

      done = 1'b0;

      result_en = 1'b0;
      diff_en = 1'b0;
      count_en = 1'b0;
      data_en = 1'b0;

      data_sel = 1'b0;

      next_diff_rst = 1'b0;
      next_count_rst = 1'b0;

      next_state = state_r;
      
      case (state_r)
        START : begin

           next_diff_rst = 1'b1;         
           next_count_rst = 1'b1;
           data_en = 1'b1;
           data_sel = 1'b1;       
           
           if (go) next_state = INIT;
        end

        // We need this extra state to allow time for the registered resets
        // to update.
        INIT: begin
           next_state = COMPUTE;           
        end

        COMPUTE : begin 
           diff_en = 1'b1;
           data_en = 1'b1;
           count_en = 1'b1;

           if (count_done) begin
              result_en = 1'b1;       
              next_state = RESTART;
           end
        end

        RESTART : begin
           done = 1'b1;
           next_diff_rst = 1'b1;
           next_count_rst = 1'b1;
           data_en = 1'b1;
           data_sel = 1'b1;       

           if (go) next_state = INIT;      
        end     

        default : next_state = XXX;
      endcase            
   end 
endmodule


