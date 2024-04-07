////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:      Ushakov M.V. (EvilLord666)
//
// Create Date:   
// Design Name:   
// Module Name:   
// Project Name:  moore_automate
// Target Device:  
// Tool versions:  
// Description:   An example of Moore automate design
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
////////////////////////////////////////////////////////////////////////////////
module moore_automate(
    input wire reset,
    input wire clk,
    input wire [1:0] a,
    output wire [1:0] b
);
    
    // a1 - 1, a2 - 2, a3 - 3
    // b1 - 0, b2 - 1, b3 - 2, b4 -3
    
    localparam reg [1:0] A1 = 2'b00;
    localparam reg [1:0] A2 = 2'b01;
    localparam reg [1:0] A3 = 2'b10;
    
    localparam reg [1:0] B1 = 2'b00;
    localparam reg [1:0] B2 = 2'b01;
    localparam reg [1:0] B3 = 2'b10;
    
    localparam reg [1:0] C1 = 2'b00;
    localparam reg [1:0] C2 = 2'b01;
    localparam reg [1:0] C3 = 2'b10;

    reg[1:0] c;

    assign b = get_output_state(c);
    
    always @(posedge clk)
    begin
        if (reset)
        begin
            c <= C1;
        end
        else
        begin
            case (c)
                C1:
                begin
                    if (a == A1)
                        c <= C2;
                    else if (a == A2)
                        c <= C3;
                    else
                        c <= C1;
                end
                C2: 
                begin
                    if (a == A3)
                        c <= C1;
                    else
                        c <= C2;
                end
                C3: 
                begin
                    if (a == A3)
                        c <= C2;
                    else
                        c <= C3;
                end
                default:
                begin
                    c <= C1;
                end
            endcase
        end
    end
    
function [1:0] get_output_state;
    input [1:0] state;
    case (state)
        C1:
            get_output_state = B3;
        C2:
            get_output_state = B2;
        C3:
            get_output_state = B1;
        default:
            get_output_state = B1;
    endcase
endfunction

endmodule
