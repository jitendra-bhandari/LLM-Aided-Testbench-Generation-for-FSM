module debounced_counter (

    // Inputs
    input               clk,
    input               rst_btn,
    input               inc_btn,
    
    // Outputs
    output  reg [3:0]   led
);

    // States
    localparam STATE_HIGH       = 2'd0;
    localparam STATE_LOW        = 2'd1;    
    localparam STATE_WAIT       = 2'd2;
    localparam STATE_PRESSED    = 2'd3;
    
    // Max counts for wait state (40 ms with 12 MHz clock)
    localparam MAX_CLK_COUNT    = 20'd480000 - 1;
    
    // Internal signals
    wire rst;
    wire inc;
    
    // Internal storage elements
    reg [1:0]   state;
    reg [19:0]  clk_count;
    
    // Invert active-low buttons
    assign rst = ~rst_btn;
    assign inc = ~inc_btn;
    
    // State transition logic
    always @ (posedge clk or posedge rst) begin
    
        // On reset, return to idle state and restart counters
        if (rst == 1'b1) begin
            state <= STATE_HIGH;
            led <= 4'd0;
            
        // Define the state transitions
        end else begin
            case (state)
            
                // Wait for increment signal to go from high to low
                STATE_HIGH: begin
                    if (inc == 1'b0) begin
                        state <= STATE_LOW;
                    end
                end
            
                // Wait for increment signal to go from low to high
                STATE_LOW: begin
                    if (inc == 1'b1) begin
                        state <= STATE_WAIT;
                    end
                end
                
                // Wait for count to be done and sample button again
                STATE_WAIT: begin
                    if (clk_count == MAX_CLK_COUNT) begin
                        if (inc == 1'b1) begin
                            state <= STATE_PRESSED;
                        end else begin
                            state <= STATE_HIGH;
                        end
                    end
                end
                
                // If button is still pressed, increment LED counter
                STATE_PRESSED: begin
                    led <= led + 1;
                    state <= STATE_HIGH;
                end
                
                    
                // Default case: return to idle state
                default: state <= STATE_HIGH;
            endcase
        end
    end
    
    // Run counter if in wait state
    always @ (posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            clk_count <= 20'd0;
        end else begin
            if (state == STATE_WAIT) begin
                clk_count <= clk_count + 1;
            end else begin
                clk_count <= 20'd0;
            end
        end
    end
    
endmodule
