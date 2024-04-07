module CombinationLock(x3, x2, x1, x0, Clock, enter, Resetn, Change, disp, change_pulse, confirm_pulse);

	integer try = 0;
	input x3, x2, x1, x0;
	input Clock, enter, Resetn, Change;
	output [1:7] disp;
	output change_pulse, confirm_pulse;
	reg [1:0] y;
	reg [3:0] lock = 4'b0110;
	parameter in = 2'b00, open = 2'b01, new = 2'b10, alarm = 2'b11;
	
	
	
	InputConditioning cpulse(Clock, Change, change_pulse);
	InputConditioning epulse(Clock, enter, confirm_pulse);
	hexdisp display(y, disp);
	
	always @(negedge Resetn, posedge Clock)
	begin 
	
		if (Resetn == 0)
		begin 
			y <= in;
			try = 0;
			lock <= 4'b0110;
		end 
		
		else
			case(y)
				in: if(confirm_pulse == 1)
						if(lock == {x3, x2, x1, x0})
						begin 
							try = 0;
							y <= open;
						end
						else
							if(try > 0)
								y <= alarm; 
							else
								try = try + 1;
								
					 else if(change_pulse == 1 & {x3, x2, x1, x0} == lock)
						y <= new;
						
				open: if(confirm_pulse == 1)
							y <= in;
				
				new: if(confirm_pulse == 1 | change_pulse == 1)
					  begin 
					    lock <= {x3, x2, x1, x0};
						 y <= in;
					  end
			endcase
			
	end
	
endmodule 
