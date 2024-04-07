module mealy_hybrid
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
	   // If all ouptuts are the same for all transitions, the state can
	   // be simplfied into a Moore state to save some code. Note that
	   // this is just a coding simplification because if the FSM has any
	   // outputs that are specific to a transition, it is technically
	   // a Mealy FSM.
	   en = 1'b0;
	   done = 1'b0;	   
	  
	   if (go) begin
	      next_state = COMPUTE;
	   end
	   else begin
	      next_state = START;
	   end
	end

	// In this state, outputs differ on each transition, so we can't
	// simplify the code.
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

	// This state can be simplified due to the same outputs on all
	// transitions.
	FINISH : begin
	   done = 1'b1;
	   en = 1'b0;
	   	   
	   if (go) begin
	      next_state = FINISH;
	   end
	   else begin
	      next_state = RESTART;
	   end
	end

	// In this state, en has the same value on all transitions, so it can
	// be removed from transitions.However, the done signal must be
	// assigned for each transition.
	//
	// Alteratively, done could be assigned a default value and then
	// assigned when the default does not apply.	
	RESTART : begin
	   en = 1'b0;
	   	   
	   if (go) begin
	      done = 1'b0;	      
	      next_state = COMPUTE;
	   end
	   else begin
	      done = 1'b1;
	      next_state = RESTART;
	   end
	end          	   	 
      endcase
   end         
endmodule
