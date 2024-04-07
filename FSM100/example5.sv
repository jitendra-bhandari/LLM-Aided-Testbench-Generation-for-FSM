module example5 (
  // inputs
  input  logic [7:0]   in,
  // outputs
  output logic [7:0]   out,
  // clock and reset
  input  logic         clk_i,
  input  logic         rst_i
);

`ifdef USE_ENUM_STATE
  typedef enum logic [3:0] {
    S0 = 4'd0,
    S1 = 4'd1,
    S2 = 4'd2,
    S3 = 4'd3,
    S4 = 4'd4,
    S5 = 4'd5,
    S6 = 4'd6,
    S7 = 4'd7,
    S8 = 4'd8,
    S9 = 4'd9,
    S10 = 4'd10,
    S11 = 4'd11,
    S12 = 4'd12,
    S13 = 4'd13,
    S14 = 4'd14,
    S15 = 4'd15
  } state_t;
`else
  localparam logic [3:0] S0 = 4'd0;
  localparam logic [3:0] S1 = 4'd1;
  localparam logic [3:0] S2 = 4'd2;
  localparam logic [3:0] S3 = 4'd3;
  localparam logic [3:0] S4 = 4'd4;
  localparam logic [3:0] S5 = 4'd5;
  localparam logic [3:0] S6 = 4'd6;
  localparam logic [3:0] S7 = 4'd7;
  localparam logic [3:0] S8 = 4'd8;
  localparam logic [3:0] S9 = 4'd9;
  localparam logic [3:0] S10 = 4'd10;
  localparam logic [3:0] S11 = 4'd11;
  localparam logic [3:0] S12 = 4'd12;
  localparam logic [3:0] S13 = 4'd13;
  localparam logic [3:0] S14 = 4'd14;
  localparam logic [3:0] S15 = 4'd15;
  typedef logic [3:0] state_t;
`endif  // USE_ENUM_STATE

  state_t state_d, state_q;


  always_ff @(posedge clk_i) begin
`ifdef FORMAL
    // SV assertions
    default clocking
      formal_clock @(posedge clk_i);
    endclocking
    default disable iff (rst_i);
`endif  // FORMAL
    if (rst_i) begin
      state_q <= S0;
    end else begin
      state_q <= state_d;
    end
  end

  always_comb begin
    // default values
    state_d = state_q;
    out = '0;
    unique case (state_q)
      S0: begin
        out = 8'h00;
        if (in < 32) begin
          state_d = S2;
        end else if (in < 4) begin
          state_d = S1;
        end else if (in < 64) begin
          state_d = S3;
        end else if (in == '0) begin
          state_d = S0;
        end else begin
          state_d = S4;
        end
      end
      S1: begin
        out = 8'h06;
        if (in[0] && in[1]) begin
          state_d = S0;
        end else begin
          state_d = S3;
        end
      end
      S2: begin
        out = 8'h18;
        state_d = S3;

      end
      S3: begin
        out = 8'h60;
        state_d = S5;

      end
      S4: begin
        out = 8'h80;
        if (in[0] || in[2] || in[4]) begin
          state_d = S5;
        end else begin
          state_d = S6;
        end
      end
      S5: begin
        out = 8'hF0;
        if (!in[0]) begin
          state_d = S5;
        end else begin
          state_d = S7;
        end
      end
      S6: begin
        out = 8'h1F;
        if (in[7:6] == 2'b00) begin
          state_d = S6;
        end else if (in[7:6] == 2'b01) begin
          state_d = S8;
        end else if (in[7:6] == 2'b10) begin
          state_d = S9;
        end else if (in[7:6] == 2'b11) begin
          state_d = S1;
        end
      end
      S7: begin
        out = 8'h3F;
        if (in[7:6] == 2'b00) begin
          state_d = S3;
        end else if (in[7:6] == 2'b01 || in[7:6] == 2'b10) begin
          state_d = S7;
        end else if (in[7:6] == 2'b11) begin
          state_d = S4;
        end
      end
      S8: begin
        out = 8'h7F;
        if (in[4] ^ in[5]) begin
          state_d = S11;
        end else if (in[7]) begin
          state_d = S1;
        end else begin
          state_d = S8;
        end
      end
      S9: begin
        out = 8'hFF;
        if (!in[0]) begin
          state_d = S9;
        end else begin
          state_d = S11;
        end
      end
      S10: begin
        out = 8'hFF;
        state_d = S1;

      end
      S11: begin
        out = 8'hFF;
        if (in == 64) begin
          state_d = S15;
        end else begin
          state_d = S8;
        end
      end
      S12: begin
        out = 8'hFD;
        if (in == 255) begin
          state_d = S0;
        end else begin
          state_d = S12;
        end
      end
      S13: begin
        out = 8'hF7;
        if (in[5] ^ in[3] ^ in[1]) begin
          state_d = S12;
        end else begin
          state_d = S14;
        end
      end
      S14: begin
        out = 8'hDF;
        if (in < 64) begin
          state_d = S12;
        end else if (in == 0) begin
          state_d = S14;
        end else begin
          state_d = S10;
        end
      end
      S15: begin
        out = 8'h7F;
        if (!in[7]) begin
          state_d = S15;
        end else if (in[1:0] == 2'b00) begin
          state_d = S14;
        end else if (in[1:0] == 2'b01) begin
          state_d = S10;
        end else if (in[1:0] == 2'b10) begin
          state_d = S13;
        end else if (in[1:0] == 2'b11) begin
          state_d = S0;
        end
      end
      default: begin
        state_d = S0;
      end
    endcase
  end
endmodule
