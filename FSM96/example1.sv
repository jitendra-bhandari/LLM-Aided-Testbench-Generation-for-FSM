module example1 (
  // inputs
  input  logic [0:0]   dly,
  input  logic [0:0]   done,
  input  logic [0:0]   req,
  // outputs
  output logic [0:0]   gnt,
  // clock and reset
  input  logic         clk_i,
  input  logic         rst_ni
);

`ifdef USE_ENUM_STATE
  typedef enum logic [3:0] {
    BIDLE = 4'd1,
    BBUSY = 4'd2,
    BWAIT = 4'd4,
    BFREE = 4'd8
  } state_t;
`else
  localparam logic [3:0] BIDLE = 4'd1;
  localparam logic [3:0] BBUSY = 4'd2;
  localparam logic [3:0] BWAIT = 4'd4;
  localparam logic [3:0] BFREE = 4'd8;
  typedef logic [3:0] state_t;
`endif  // USE_ENUM_STATE

  state_t state_d, state_q;


  always_ff @(posedge clk_i, negedge rst_ni) begin
`ifdef FORMAL
    // SV assertions
    default clocking
      formal_clock @(posedge clk_i);
    endclocking
    default disable iff (!rst_ni);
`endif  // FORMAL
    if (!rst_ni) begin
      state_q <= BIDLE;
    end else begin
      state_q <= state_d;
    end
  end

  always_comb begin
    // default values
    state_d = state_q;
    gnt = '0;
    unique case (state_q)
      BIDLE: begin
        if (req) begin
          state_d = BBUSY;
        end else begin
          state_d = BIDLE;
        end
      end
      BBUSY: begin
        gnt = 1'b1;
        if (!dly && done) begin
          state_d = BFREE;
        end else if (dly && done) begin
          state_d = BWAIT;
        end else begin
          state_d = BBUSY;
        end
      end
      BWAIT: begin
        gnt = 1'b1;
        if (!dly) begin
          state_d = BFREE;
        end else begin
          state_d = BWAIT;
        end
      end
      BFREE: begin
        if (req) begin
          state_d = BBUSY;
        end else begin
          state_d = BIDLE;
        end
      end
      default: begin
        state_d = BIDLE;
      end
    endcase
  end
endmodule
