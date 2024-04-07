module elevator(s1, s2, s3, f1, f2, f3, u1, u2, u3, d1, d2, d3, clk, rst, ac, display, doorOpen);
    input s1, s2, s3, f1, f2, f3, u1, u2, u3, d1, d2, d3, clk, rst;
    output reg [1:0] ac = 2'b00;
    output reg [1:0] display = 1;
    output reg doorOpen = 0;

    reg [3:0] reg_f = 0;
    reg [3:0] reg_u = 0;
    reg [3:0] reg_d = 0;

    reg [3:0] state = 9;
    reg [3:0] next_state = 9;

    always @(posedge f1) if (!rst) reg_f[1] = 1;
    always @(posedge f2) if (!rst) reg_f[2] = 1;
    always @(posedge f3) if (!rst) reg_f[3] = 1;
    always @(posedge u1) if (!rst) reg_u[1] = 1;
    always @(posedge u2) if (!rst) reg_u[2] = 1;
    always @(posedge u3) if (!rst) reg_u[3] = 1;
    always @(posedge d1) if (!rst) reg_d[1] = 1;
    always @(posedge d2) if (!rst) reg_d[2] = 1;
    always @(posedge d3) if (!rst) reg_d[3] = 1;

    always @(posedge clk, posedge s1, posedge s2, posedge s3, rst) begin
        case (state)
            0: begin
                if (reg_f[2] || reg_f[3] || reg_d[2] || reg_d[3] || reg_u[2] || reg_u[3]) begin
                next_state = 1;
                assign ac = 2'b10;
                assign display = 1;
                assign doorOpen = 0;
                end
                else begin
                    next_state = 9;
                    assign ac = 2'b00;
                    assign display = 1;
                    assign doorOpen = 0;
                end
            end
            
            1: begin
                if (s2) begin
                    if (reg_f[2] || reg_u[2]) begin
                        next_state = 2;
                        assign ac = 2'b00;
                        assign display = 2;
                        assign doorOpen = 1;
                        reg_u[2] = 0;
                        reg_f[2] = 0;
                        reg_d[2] = 0;
                    end
                    else if (reg_f[3] || reg_u[3] || reg_d[3]) begin
                        next_state = 3;
                        assign ac = 2'b10;
                        assign display = 2;
                        assign doorOpen = 0;
                    end
                    else if (reg_d[2]) begin
                        next_state = 6;
                        assign ac = 2'b00;
                        assign display = 2;
                        assign doorOpen = 1;
                        reg_d[2] = 0;
                        reg_f[2] = 0;
                        reg_u[2] = 0;
                    end
                end
            end

            2: begin
                if (reg_f[3] || reg_u[3] || reg_d[3]) begin
                    next_state = 3;
                    assign ac = 2'b10;
                    assign display = 2;
                    assign doorOpen = 0;
                end
                else begin
                    next_state = 11;
                    assign ac = 2'b00;
                    assign display = 2;
                    assign doorOpen = 1;
                end
            end

            3: begin
                if (s3) begin
                    next_state = 4;
                    assign ac = 2'b00;
                    assign display = 3;
                    assign doorOpen = 1;
                    reg_f[3] = 0;
                    reg_u[3] = 0;
                    reg_d[3] = 0;
                end
            end

            4: begin
                if (reg_f[1] || reg_f[2] || reg_d[1] || reg_d[2] || reg_u[1] || reg_u[2]) begin
                    next_state = 5;
                    assign ac = 2'b01;
                    assign display = 3;
                    assign doorOpen = 0;
                end
                else begin
                    next_state = 10;
                    assign ac = 2'b00;
                    assign display = 3;
                    assign doorOpen = 0;
                end
            end

            5: begin
                if (s2) begin
                    if (reg_f[2] || reg_d[2]) begin
                        next_state = 6;
                        assign ac = 2'b00;
                        assign display = 2;
                        assign doorOpen = 1;
                        reg_d[2] = 0;
                        reg_f[2] = 0;
                        reg_u[2] = 0;
                    end
                    else if (reg_f[1] || reg_u[1] || reg_d[1]) begin
                        next_state = 7;
                        assign ac = 2'b01;
                        assign display = 2;
                        assign doorOpen = 0;
                    end
                    else if (reg_u[2]) begin
                        next_state = 2;
                        assign ac = 2'b00;
                        assign display = 2;
                        assign doorOpen = 1;
                        reg_u[2] = 0;
                        reg_f[2] = 0;
                        reg_d[2] = 0;
                    end
                end
            end

            6: begin
                if (reg_f[1] || reg_u[1] || reg_d[1]) begin
                    next_state = 7;
                    assign ac = 2'b01;
                    assign display = 2;
                    assign doorOpen = 0;
                end
                else begin
                    next_state = 11;
                    assign ac = 2'b00;
                    assign display = 2;
                    assign doorOpen = 1;
                end
            end

            7: begin
                if (s1) begin
                    next_state = 0;
                    assign ac = 2'b00;
                    assign display = 1;
                    assign doorOpen = 1;
                    reg_f[1] = 0;
                    reg_u[1] = 0;
                    reg_d[1] = 0;
                end
            end

            8: begin
                if (reg_d[2] || reg_u[2] || reg_d[2]) begin
                    next_state = 11;
                    assign ac = 2'b00;
                    assign display = 2;
                    assign doorOpen = 1;
                    reg_d[2] = 0;
                    reg_f[2] = 0;
                    reg_u[2] = 0;
                end
                else if (reg_f[1] || reg_u[1] || reg_d[1]) begin
                    next_state = 7;
                    assign ac = 2'b01;
                    assign display = 2;
                    assign doorOpen = 0;
                end
                else if (reg_f[3] || reg_u[3] || reg_d[3]) begin
                    next_state = 3;
                    assign ac = 2'b10;
                    assign display = 2;
                    assign doorOpen = 0;
                end
            end

            9: begin
                if (reg_f[1] || reg_u[1] || reg_d[1]) begin
                    next_state = 0;
                    assign ac = 2'b00;
                    assign display = 1;
                    assign doorOpen = 1;
                    reg_f[1] = 0;
                    reg_u[1] = 0;
                    reg_d[1] = 0;
                end
                else if (reg_f[2] || reg_f[3] || reg_d[2] || reg_d[3] || reg_u[2] || reg_u[3]) begin
                    next_state = 1;
                    assign ac = 2'b10;
                    assign display = 1;
                    assign doorOpen = 0;
                end
            end

            10: begin
                if (reg_f[3] || reg_u[3] || reg_d[3]) begin
                    next_state = 4;
                    assign ac = 2'b00;
                    assign display = 3;
                    assign doorOpen = 1;
                    reg_f[3] = 0;
                    reg_u[3] = 0;
                    reg_d[3] = 0;
                end
                else if (reg_f[1] || reg_f[2] || reg_d[1] || reg_d[2] || reg_u[1] || reg_u[2]) begin
                    next_state = 5;
                    assign ac = 2'b01;
                    assign display = 3;
                    assign doorOpen = 0;
                end
            end

            11: begin
                if (reg_f[3] || reg_u[3] || reg_d[3]) begin
                    next_state = 2;
                    assign ac = 2'b00;
                    assign display = 2;
                    assign doorOpen = 1;
                end
                else if (reg_f[1] || reg_d[1] || reg_u[1]) begin
                    next_state = 6;
                    assign ac = 2'b00;
                    assign display = 2;
                    assign doorOpen = 1;
                end
                else begin 
                    next_state = 8;
                    assign ac = 2'b00;
                    assign display = 2;
                    assign doorOpen = 0;
                end
            end
        endcase

        if (rst) begin
            next_state = 9;
            assign ac = 2'b00;
            assign display = 1;
            assign doorOpen = 0;
        end

        state = next_state;
    end

endmodule
