module Project_COE312(input clk, input reset,input count_up , output reg [3:0] y);//By Mohammad Yaser Ammar | 3704975 | April / 2020
reg [2:0]state;
parameter S0=0,S1=1,S2=2,S3=3,S4=4,S5=5; //we have 6 state ; because initially letter in State 0
reg[3:0] count;//Counter 10 times ; then need 4-bit | Need condtion max in 10 ; count 1 to 10

always@(posedge clk)begin
  if (reset == 0) begin
   count = 0;
   state <= S0;//System starts from the initial state
end
   else begin
	count <= count + 1; //counter 
		case (state)
		S0:begin
		if(count == 10) begin //to wait count from 1 to 10
			count <= 0;
			state<=S1;
			end
			else begin
			state<=S0; end
			y<='hC;end//value directly in hexadecimal			
		S1:begin
		if(count == 10) begin
		   count <= 0;
			state<=S2; end
			else begin
			state<=S1; end
			y<='h0;end
			
		S2:begin
		if(count == 10)begin
			count <= 0;
			state<=S3;end
			else begin
			state<=S2;end
			y<='hE;end
			
		S3:begin
		if(count == 10) begin
			count <= 0;
			state<=S4;end
			else begin
			state<=S3;end
			y<='h3;end
			
		S4:begin
		if(count == 10)begin
			count <= 0;
			state<=S5;end
			else begin
			state<=S4;end
			y<='h1;
			end
		
		S5:begin
		if(count == 10) begin
			count <= 0;
			state<=S0;end //to back repeat to C
			else begin
			state<=S5;end
			y<='h2;
			end
		default:
			y<=0;
		endcase 
		end
end
endmodule 
