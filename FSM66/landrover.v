module landrover (
  input wire X, clk, reset,
  output reg [2:0] state
);

  reg A,B,C;
  reg [2:0] next_state;
  
  always @(posedge clk or posedge reset) begin
  
	 if(reset == 1)
	 begin
	 
		state <= 3'b000;
		
	 end
	 
	 else
	 begin
  
		 A = state[2];
		 B = state[1];
		 C = state[0];
		 
		 next_state[2] = ( A & ( !C | X ) ) | ( (B ^ C) & X );
		 next_state[1] = ( !A & C & !X ) | ( A & (B ^ C) ) | ( (A | B) & !C & !X );
		 next_state[0] = ( !B & !C & X ) | ( !X & ( ( A ^ B ) | ( B & !C ) ) ) | ( A & B & C & X ); 
		 
		 
		 state <= next_state;

	 end
	 
  end
  
  initial begin
    state <= 3'b000; // Initialize state to 000
  end

  
endmodule 
