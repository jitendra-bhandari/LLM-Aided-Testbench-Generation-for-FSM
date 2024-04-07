module combolock(Clock, confirm, Resetn, Change, disp, x3, x2, x1, x0, changepulse, confirmpulse);

	integer tries = 0;
	input x3, x2, x1, x0;
	input Clock, confirm, Resetn, Change;
	output [1:7] disp;
	output changepulse, confirmpulse;
	reg [1:0] y;
	reg [3:0] lock = 4'b0110;
	parameter in = 2'b00, open = 2'b01, new = 2'b10, alarm = 2'b11;
	
	inputcond cpulse(Clock, Change, changepulse);
	inputcond epulse(Clock, confirm, confirmpulse);
	hexdisp display(y, disp);
	
	always @(negedge Resetn, posedge Clock)
	begin 
	
		if (Resetn == 0)
		begin 
			y <= in;
			tries = 0;
			lock <= 4'b0110;
		end 
		
		else
			case(y)
				in: if(confirmpulse == 1)
						if(lock == {x3, x2, x1, x0})
						begin 
							tries = 0;
							y <= open;
						end
						else
							if(tries > 0)
								y <= alarm; 
							else
								tries = tries + 1;
								
					 else if(changepulse == 1 & {x3, x2, x1, x0} == lock)
						y <= new;
						
				open: if(confirmpulse == 1)
							y <= in;
				
				new: if(confirmpulse == 1 | changepulse == 1)
					  begin 
					    lock <= {x3, x2, x1, x0};
						 y <= in;
					  end
			endcase
			
	end
	
endmodule 
