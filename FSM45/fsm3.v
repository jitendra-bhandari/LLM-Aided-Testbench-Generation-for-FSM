module FSM
(
    input clk,
    input reset,
    output reg [1:0] out
);

    reg [1:0] state;
    reg [8:0] counter;
    localparam Boarding = 2'b00;
    localparam InTransit = 2'b01;
    localparam Disembarking = 2'b10;
    
    always @(posedge clk) begin
        if (reset) begin
            state = Boarding;
            out = 2'b00;
        end else begin
            case (state)
            Boarding: begin
                state = InTransit;
                counter = 0;
            end
            InTransit: begin
                if (counter < 2)
                    counter = counter + 1;
                else
                    state = Disembarking;
            end
            Disembarking: begin
                state = Boarding;
                counter = 0;
            end
            endcase
            
            // This is a Moore machine
            out = state;
        end
    end
endmodule
