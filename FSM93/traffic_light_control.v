module traffic_light_control(
	input CLOCK_50,
	input [0:0]KEY,
	input [0:0]SW,
	output reg[7:7] LEDG,
	output reg[9:0] LEDR,
	output reg[0:6]HEX0,
	output reg[0:6]HEX1,
	output reg[0:6]HEX2,
	output reg[0:6]HEX3);

	reg[3:0] Hex0_value, Hex1_value;
	reg[2:0] state, next_state;
	reg[5:0] delay_counter;		
	parameter S0 = 3'b000,S1 = 3'b001, S2 = 3'b010, S3 = 3'b011, S4 = 3'b100; //state value
	
	Lab4B_modified oneHzClock (CLOCK_50,KEY[0:0],clock_oneHz);
	
always@ (posedge clock_oneHz, negedge KEY[0:0])
begin

 if(~KEY[0:0])
	state <= S0;
 else
	state <= next_state;
end	

always @ (posedge clock_oneHz or negedge KEY[0:0])
begin
if(!KEY)	
	delay_counter <= 6'b101000;
		 
else
	if(state == S0)
		delay_counter <= 6'b000000;
		
	else if(state == S1)
		delay_counter <= delay_counter + 6'b000001;
		
	else if(state == S2)
		delay_counter <= delay_counter + 6'b000001;
		
	else if(state == S3)
		delay_counter <= delay_counter;
		
	else if(state == S4)
		delay_counter <= delay_counter + 6'b000001;
	else
		delay_counter <= 6'b000000;
end	

// next state logic
always@ (state)
  case(state)
		S0: if(SW[0])			// when x = 1	
				next_state = S1;
			else				// when x = 0
				next_state = S0;

		S1: 
			if(delay_counter == 6'b001010) // when reached delay_counter 10
				next_state = S2;
			else
				next_state = S1;
		S2:	
			if(delay_counter == 6'b011111) // when reached delay_counter 30
				next_state = S3;
			else
				next_state = S2;
		S3: 
			//start_delay_counter = 1'b0;
			if(SW[0:0])
				next_state = S3;
			else
				next_state = S4;
			
		S4:	
			//start_delay_counter = 1'b1;
			if(delay_counter == 6'b101010) // when reached delay_counter 40
				next_state = S0;
			else
				next_state = S4;
			
		default : next_state = 3'bxxx;
	endcase
	
// output logic
always@ (state) 
begin								// R - Y - G            R - Y - G
			 LEDR[9:0] = 10'd0;		// LEDR[9:8:7] HWY		LEDR[2:1:0] CNTRY
			
			case (state)						
			 S0:	LEDR[9:0] = 10'b0010000100;
			 S1:    LEDR[9:0] = 10'b0100000100;
			 S2:	LEDR[9:0] = 10'b1000000100;
			 S3:	LEDR[9:0] = 10'b1000000001;
			 S4:	LEDR[9:0] = 10'b1000000010;
			 default : LEDR[9:0] = 10'b0000000000;
			 endcase
end

always@(delay_counter, state)
begin 
	case(state)
	 S0: begin HEX3[0:6] = 7'b1001000;
		 HEX2[0:6] = 7'b1111010;
		 HEX1[0:6] = 7'b0100000;
		 HEX0[0:6] = 7'b0000001;
		 end
	 
	 S1: begin HEX3[0:6] = 7'b0000000;
		 HEX2[0:6] = 7'b0000000;
		 
		 case(delay_counter)
		
		 6'b000000 : begin HEX1[0:6] = 7'b1001111; 
					 HEX0[0:6] = 7'b0000001; end
		 6'b000001 : begin HEX1[0:6] = 7'b0000001; 
					 HEX0[0:6] = 7'b0001100; end
		 6'b000010 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0000000; end
		 6'b000011 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0001111; end
		 6'b000100 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0100000; end	 
		 6'b000101 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0100100; end
		 6'b000110 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b1001100; end
		 6'b000111 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0000110; end		
		 6'b001000 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0010010; end
		 6'b001001 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b1001111; end	 
		 6'b001010 : begin HEX1[0:6] = 7'b0000001;
				     HEX0[0:6] = 7'b0000001; end
		
		 endcase
		 end
	
	S2: begin HEX3[0:6] = 7'b0000000;
		 HEX2[0:6] = 7'b0000000; 
		case(delay_counter)
	
		 6'b001011 : begin 
					 HEX0[0:6] = 7'b0011000; 	
					 HEX1[0:6] = 7'b0000001; 
					 HEX2[0:6] = 7'b1110000;
					 HEX3[0:6] = 7'b0100100;
					 end
		 6'b001100 : begin 
					 HEX0[0:6] = 7'b1111111; 	
					 HEX1[0:6] = 7'b1111111; 
					 HEX2[0:6] = 7'b1111111;
					 HEX3[0:6] = 7'b1111111;
					 end
		 6'b001101:   begin 
					 HEX0[0:6] = 7'b0011000; 	
					 HEX1[0:6] = 7'b0000001; 
					 HEX2[0:6] = 7'b1110000;
					 HEX3[0:6] = 7'b0100100;
					 end
		 6'b001110 :  begin 
					 HEX0[0:6] = 7'b1111111; 	
					 HEX1[0:6] = 7'b1111111; 
					 HEX2[0:6] = 7'b1111111;
					 HEX3[0:6] = 7'b1111111;
					 end	 
		 6'b001111 : begin 
					 HEX0[0:6] = 7'b0011000; 	
					 HEX1[0:6] = 7'b0000001; 
					 HEX2[0:6] = 7'b1110000;
					 HEX3[0:6] = 7'b0100100;
					 end
		 6'b010000 : begin HEX1[0:6] = 7'b1001111;
					 HEX0[0:6] = 7'b0100100; end
		 6'b010001 : begin HEX1[0:6] = 7'b1001111;
					 HEX0[0:6] = 7'b1001100; end		
		 6'b010010 : begin HEX1[0:6] = 7'b1001111;
					 HEX0[0:6] = 7'b0000110; end
		 6'b010011 : begin HEX1[0:6] = 7'b1001111;
					 HEX0[0:6] = 7'b0010010; end	  
		 6'b010100 : begin HEX1[0:6] = 7'b1001111;
					 HEX0[0:6] = 7'b1001111; end
					 
		 6'b010101 : begin HEX1[0:6] = 7'b1001111; 
					 HEX0[0:6] = 7'b0000001; end
		 6'b010110 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0001100; end
		 6'b010111 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0000000; end
		 6'b011000 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0001111; end	
		 6'b011001 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0100000; end
		 6'b011010 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0100100; end
		 6'b011011:  begin HEX1[0:6]  = 7'b0000001;
					 HEX0[0:6] = 7'b1001100; end	 	
		 6'b011100 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0000110; end
		 6'b011101 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0010010; end	 
		 6'b011110 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b1001111; end	
		 6'b011111 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0000001; end			 		 
		endcase
		end
	S3:  begin HEX3[0:6] = 7'b0110001;
		 HEX2[0:6] = 7'b1111010;
		 HEX1[0:6] = 7'b0100000;
		 HEX0[0:6] = 7'b0000001;
		 end
	S4 : begin HEX3[0:6] = 7'b0000000;
		 HEX2[0:6] = 7'b0000000;
		 
		 case(delay_counter)
		
		 6'b100000 : begin HEX1[0:6] = 7'b1001111; 
					 HEX0[0:6] = 7'b0000001; end
		 6'b100001 : begin HEX1[0:6] = 7'b0000001; 
					 HEX0[0:6] = 7'b0001100; end
		 6'b100010 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0000000; end
		 6'b100011 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0001111; end
		 6'b100100 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0100000; end	 
		 6'b100101 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0100100; end
		 6'b100110 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b1001100; end
		 6'b100111 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0000110; end		
		 6'b101000 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b0010010; end
		 6'b101001 : begin HEX1[0:6] = 7'b0000001;
					 HEX0[0:6] = 7'b1001111; end	 
		 6'b101010 : begin HEX1[0:6] = 7'b0000001;
				     HEX0[0:6] = 7'b0000001; end
		
		 endcase
		 end
	endcase	
end	
endmodule

/*
always @ (state)
begin
	if(state == S0)
		begin
		Hex0_value = 4'd0;
		Hex1_value = 4'd0;
		end		
	else if(state == S1)
		begin
		Hex0_value = 4'd0;
		Hex1_value = 4'd1;
		end		
		
	else if(state == S2)
		begin
		Hex0_value = 4'd0;
		Hex1_value = 4'd2;
		end		
	else if(state == S3)
		begin
		Hex0_value = 4'd0;
		Hex1_value = 4'd0;
		end		
		
	else if(state == S4)
		begin
		Hex0_value = 4'd0;
		Hex1_value = 4'd1;
		end		
		
	else
		begin
		Hex0_value = 4'd0;
		Hex1_value = 4'd0;
		end		
end
*/
