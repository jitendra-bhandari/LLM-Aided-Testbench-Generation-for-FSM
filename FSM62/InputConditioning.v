module InputConditioning(Clock, A, pulse);

	input Clock, A;
	reg [1:0] y, Y;
	output pulse;
	parameter B = 2'b00, C = 2'b01, D = 2'b10;
	
	always@(negedge A, posedge Clock)
	begin
		case(y)
			B: if(A == 0) Y = A;
				else Y = C;
			
			C: if (A == 0) Y = A;
				else Y = D;
			D: if (A == 0) Y = A;
				else Y = D;
			
			default: Y= 2'bxx;
		endcase
	end
	
	always@(posedge Clock)
	begin
		y <= Y;
	end
	
	assign pulse = (y == C);
	
endmodule
