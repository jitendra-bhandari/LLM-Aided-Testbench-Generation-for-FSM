module example3 (
  // inputs
  input  logic [0:0]   jmp,
  input  logic [0:0]   go,
  // outputs
  output logic [0:0]   y1,
  // clock and reset
  input  logic         clk_i,
  input  logic         rst_ni
);

`ifdef USE_ENUM_STATE
  typedef enum logic [9:0] {
    S0 = 10'd1,
    S1 = 10'd2,
    S2 = 10'd4,
    S3 = 10'd8,
    S4 = 10'd16,
    S5 = 10'd32,
    S6 = 10'd64,
    S7 = 10'd128,
    S8 = 10'd256,
    S9 = 10'd512
  } state_t;
`else
  localparam logic [9:0] S0 = 10'd1;
  localparam logic [9:0] S1 = 10'd2;
  localparam logic [9:0] S2 = 10'd4;
  localparam logic [9:0] S3 = 10'd8;
  localparam logic [9:0] S4 = 10'd16;
  localparam logic [9:0] S5 = 10'd32;
  localparam logic [9:0] S6 = 10'd64;
  localparam logic [9:0] S7 = 10'd128;
  localparam logic [9:0] S8 = 10'd256;
  localparam logic [9:0] S9 = 10'd512;
  typedef logic [9:0] state_t;
`endif  // USE_ENUM_STATE

  state_t state_d, state_q;
  logic [0:0] y1_d, y1_q;

  assign y1 = y1_q;

  always_ff @(posedge clk_i) begin
`ifdef FORMAL
    // SV assertions
    default clocking
      formal_clock @(posedge clk_i);
    endclocking
    default disable iff (!rst_ni);
`endif  // FORMAL
    if (!rst_ni) begin
      state_q <= S0;
      y1_q <= '0;
    end else begin
      state_q <= state_d;
      y1_q <= y1_d;
    end
  end

  always_comb begin
    // default values
    state_d = state_q;
    y1_d = y1_q;
    unique case (state_q)
      S0: begin
        if (!go) begin
          state_d = S0;
        end else if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S1;
        end
      end
      S1: begin
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S2;
        end
      end
      S2: begin
        y1_d = 1'b1;
        state_d = S3;

      end
      S3: begin
        y1_d = 1'b1;
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S4;
        end
      end
      S4: begin
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S5;
        end
      end
      S5: begin
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S6;
        end
      end
      S6: begin
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S7;
        end
      end
      S7: begin
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S8;
        end
      end
      S8: begin
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S9;
        end
      end
      S9: begin
        if (jmp) begin
          state_d = S3;
        end else begin
          state_d = S0;
        end
      end
      default: begin
        state_d = S0;
      end
    endcase
  end
endmodule
