////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:      Ushakov M.V. (EvilLord666)
//
// Create Date:   
// Design Name:   
// Module Name:   
// Project Name:  milley_automate
// Target Device:  
// Tool versions:  
// Description:   An example of Milley automate design
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
////////////////////////////////////////////////////////////////////////////////
module milley_automate(
    input wire reset,
    input wire clk,
    input wire [1:0] a,
    output reg [1:0] b
);
    
    // a1 - 1, a2 - 2, a3 - 3
    // b1 - 0, b2 - 1, b3 - 2, b4 -3
    
    localparam reg [1:0] A1 = 2'b01;
    localparam reg [1:0] A2 = 2'b10;
    localparam reg [1:0] A3 = 2'b11;
    
    localparam reg [1:0] B1 = 2'b00;
    localparam reg [1:0] B2 = 2'b01;
    localparam reg [1:0] B3 = 2'b10;
    localparam reg [1:0] B4 = 2'b11;
    
    localparam reg [1:0] C1 = 2'b00;
    localparam reg [1:0] C2 = 2'b01;
    localparam reg [1:0] C3 = 2'b10;
    localparam reg [1:0] C4 = 2'b11;

    reg[1:0] c;
    
    always @(posedge clk)
    begin
        if (reset)
        begin
            c <= C1;
            b <= 0;
        end
        else
        begin
            case (c)
                C1: 
                begin
                    if (a == A2)
                    begin
                        c <= C2;
                        b <= B3;
                    end
                    else if (a == A3)
                    begin
                        c <= C3;
                        b <= B4;
                    end
                    else // доопределение состояния автомата
                    begin
                        c <= C1;
                        b <= B2;
                    end
                end
                C2: 
                begin
                    if (a == A3)
                    begin
                        c <= C1;
                        b <= B1;
                    end
                    else // доопределение состояния автомата
                    begin
                        c <= C2;
                        // мы не изменяем значение b
                    end
                end
                C3: 
                begin
                    if (a == A1)
                    begin
                        c <= C4;
                        b <= B1;
                    end
                    else if (a == A2)
                    begin
                        c <= C1;
                        b <= B3;
                    end
                    else if (a == A3)
                    begin
                        c <= C2;
                        b <= B4;
                    end
                    else
                    begin
                        c <= C3;
                    end
                end
                C4: 
                begin
                    if (a == A1)
                    begin
                        c <= C4;
                        b <= B2;
                    end
                    else if (a == A3)
                    begin
                        c <= C2;
                        b <= B2;
                    end
                    else 
                    begin  // доопределение автомата, мы не изменяем значение b
                        c <= C4;
                    end
                end
                default:
                begin
                    b <= B1;
                    c <= C1;
                end
            endcase
        end
    end

endmodule
