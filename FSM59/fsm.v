module fsm (input clk, input a, b, c, output k, m, l);
  localparam
    STATE_IDLE = 3'b000,
    STATE_K = 3'b001,
    STATE_M = 3'b010,
    STATE_L = 3'b100,
    STATE_ML = 3'b110;

  reg [2:0] state;
  reg [2:0] next_state;

  // combinational logic
  always @* begin
    case (state)
      STATE_IDLE: begin
        if (a && b) begin
          next_state = STATE_ML;
        end else if (b) begin
          next_state = STATE_K;
        end else begin
          next_state = state;
        end
      end
      STATE_ML: begin
        if (a && b && c) begin
          next_state = STATE_L;
        end else if (b && c) begin
          next_state = STATE_M;
        end else begin
          next_state = state;
        end
      end
      default: next_state = state;
    endcase
  end

  // reset and next state
  always @(posedge clk) begin
    if (!a && !b && !c) begin
      state <= STATE_IDLE;
    end else begin
      state <= next_state;
    end
  end

  // output logic
  assign k = state[0] & ~state[1] & ~state[2];
  assign m = ~state[0] & state[1] & ~state[2];
  assign l = ~state[0] & ~state[1] & state[2];
endmodule
