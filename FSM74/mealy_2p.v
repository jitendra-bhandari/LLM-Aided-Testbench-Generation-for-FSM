module mealy_2p
  (
   input logic 	clk, rst, go, ack,
   output logic en, done
   );

   typedef enum logic [1:0] {START, COMPUTE, FINISH, RESTART} state_t;
   state_t state_r, next_state;

   always_ff @(posedge clk, posedge rst)
     if (rst) state_r <= START;
     else state_r <= next_state;

   always_comb begin
      case (state_r)
	START : begin
	   // In a Mealy FSM, outputs are a function of the state and the
	   // current input, which makes them associated with transitions.
	   // Therefore, all outputs appear within if statements that
	   // correspond to transitions between states.
	   if (go) begin
	      done = 1'b0;
	      en = 1'b0;	      
	      next_state = COMPUTE;
	   end
	   else begin
	      done = 1'b0;
	      en = 1'b0;	      
	      next_state = START;
	   end
	end

	COMPUTE : begin
	   if (ack) begin
	      en = 1'b0;	      
	      done = 1'b1;	      
	      next_state = FINISH;	      
	   end
	   else begin
	      en = 1'b1;	      
	      done = 1'b0;	      
	      next_state = COMPUTE;	      
	   end	   
	end

	FINISH : begin
	   if (go) begin
	      done = 1'b1;
	      en = 1'b0;	      
	      next_state = FINISH;
	   end
	   else begin
	      done = 1'b1;
	      en = 1'b0;	      
	      next_state = RESTART;
	   end
	end
	
	RESTART : begin
	   if (go) begin
	      done = 1'b0;
	      en = 1'b0;	      
	      next_state = COMPUTE;
	   end
	   else begin
	      done = 1'b1;
	      en = 1'b0;	      
	      next_state = RESTART;
	   end
	end          	   	 
      endcase
   end         
endmodule // mealy

