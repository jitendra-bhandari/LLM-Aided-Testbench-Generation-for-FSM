module example2 (
  // inputs
  input  logic [1:0]   in0,
  input  logic [0:0]   in1,
  // outputs
  output logic [0:0]   out0,
  output logic [1:0]   out1,
  output logic [3:0]   out2,
  // clock and reset
  input  logic         clk_i,
  input  logic         rst_ni
);

`ifdef USE_ENUM_STATE
  typedef enum logic [1:0] {
    IDLE = 2'd1,
    STATE0 = 2'd2
  } state_t;
`else
  localparam logic [1:0] IDLE = 2'd1;
  localparam logic [1:0] STATE0 = 2'd2;
  typedef logic [1:0] state_t;
`endif  // USE_ENUM_STATE

  state_t state_d, state_q;
  logic [1:0] out1_d, out1_q;

  assign out1 = out1_q;

  always_ff @(posedge clk_i, negedge rst_ni) begin
`ifdef FORMAL
    // SV assertions
    default clocking
      formal_clock @(posedge clk_i);
    endclocking
    default disable iff (!rst_ni);
`endif  // FORMAL
    if (!rst_ni) begin
      state_q <= IDLE;
      out1_q <= '0;
    end else begin
      state_q <= state_d;
      out1_q <= out1_d;
    end
  end

  always_comb begin
    // default values
    state_d = state_q;
    out0 = '0;
    out1_d = out1_q;
    out2 = '0;
    unique case (state_q)
      IDLE: begin
        out2 = 4'h2;
        if (in0 == 2'h1 && in1 == 1'h0) begin
          state_d = STATE0;
          out0 = 1'h1;
          out1_d = 2'h1;
        end
      end
      STATE0: begin
        if (in0 == 2'h0 && in1 == 1'h1) begin
          state_d = IDLE;
          out1_d = 2'h2;
        end
      end
      default: begin
        state_d = IDLE;
      end
    endcase
  end
endmodule
