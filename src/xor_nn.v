module xor_nn #(
    parameter DATA_WIDTH = 16,  // Fixed-point: 8.8 format
    parameter FRAC_BITS = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire x1,
    input wire x2,
    output reg y_out,
    output reg done
);

    // Neural network parameters (pre-trained weights)
    reg signed [DATA_WIDTH-1:0] w_hidden [0:15];
    reg signed [DATA_WIDTH-1:0] b_hidden [0:7];
    reg signed [DATA_WIDTH-1:0] w_output [0:7];
    reg signed [DATA_WIDTH-1:0] b_output;
    
    // Internal signals
    reg signed [DATA_WIDTH-1:0] hidden_sum [0:7];
    reg signed [DATA_WIDTH-1:0] hidden_out [0:7];
    reg signed [DATA_WIDTH-1:0] output_sum;
    reg signed [DATA_WIDTH-1:0] mult_result;
    
    // State machine
    reg [2:0] state;
    localparam IDLE = 3'd0;
    localparam COMPUTE_HIDDEN = 3'd1;
    localparam ACTIVATE_HIDDEN = 3'd2;
    localparam COMPUTE_OUTPUT = 3'd3;
    localparam ACTIVATE_OUTPUT = 3'd4;
    localparam DONE = 3'd5;
    
    // Accumulator index for output computation
    reg [3:0] acc_idx;
    
    integer i;
    
    // Initialize with YOUR trained weights
    initial begin
        // Hidden weights:
        w_hidden[0] = 16'h00F4;  // 0.953
        w_hidden[1] = 16'hFFB7;  // -0.288
        w_hidden[2] = 16'hFF5A;  // -0.650
        w_hidden[3] = 16'hFFFE;  // -0.010
        w_hidden[4] = 16'h0156;  // 1.339
        w_hidden[5] = 16'hFF95;  // -0.421
        w_hidden[6] = 16'h069A;  // 6.603
        w_hidden[7] = 16'hFAB6;  // -5.292
        w_hidden[8] = 16'h0219;  // 2.100
        w_hidden[9] = 16'h0249;  // 2.285
        w_hidden[10] = 16'hFD53;  // -2.679
        w_hidden[11] = 16'hFCDF;  // -3.132
        w_hidden[12] = 16'h0613;  // 6.077
        w_hidden[13] = 16'hF8C5;  // -7.233
        w_hidden[14] = 16'h0358;  // 3.347
        w_hidden[15] = 16'hFE22;  // -1.868
        
        // Hidden biases:
        b_hidden[0] = 16'hFFF7;  // -0.038
        b_hidden[1] = 16'h0078;  // 0.469
        b_hidden[2] = 16'h0012;  // 0.072
        b_hidden[3] = 16'h027A;  // 2.477
        b_hidden[4] = 16'h00BC;  // 0.736
        b_hidden[5] = 16'h0012;  // 0.073
        b_hidden[6] = 16'hFD17;  // -2.913
        b_hidden[7] = 16'h00C0;  // 0.751
        
        // Output weights:
        w_output[0] = 16'hFFAF;  // -0.320
        w_output[1] = 16'h01B0;  // 1.691
        w_output[2] = 16'hFF76;  // -0.540
        w_output[3] = 16'hF671;  // -9.562
        w_output[4] = 16'h03DF;  // 3.873
        w_output[5] = 16'hFD80;  // -2.501
        w_output[6] = 16'h0C39;  // 12.226
        w_output[7] = 16'hFD36;  // -2.793
        
        // Output bias:
        b_output = 16'h0263;  // 2.390
    end
    
    // Sigmoid approximation function
    function [DATA_WIDTH-1:0] sigmoid;
        input signed [DATA_WIDTH-1:0] x;
        /* verilator lint_off BLKSEQ */
        begin
            // Piecewise linear approximation of sigmoid
            // Input x is in 8.8 fixed point format
            if ($signed(x) < $signed(16'hFC00))  // x < -4
                sigmoid = 16'h0000;  // 0.0
            else if ($signed(x) < $signed(16'hFE00))  // -4 <= x < -2
                sigmoid = 16'h0010 + (($signed(x) + $signed(16'h0400)) >>> 4);
            else if ($signed(x) < $signed(16'h0000))  // -2 <= x < 0
                sigmoid = 16'h0040 + (($signed(x) + $signed(16'h0200)) >>> 2);
            else if ($signed(x) < $signed(16'h0200))  // 0 <= x < 2
                sigmoid = 16'h0080 + ($signed(x) >>> 2);
            else if ($signed(x) < $signed(16'h0400))  // 2 <= x < 4
                sigmoid = 16'h00C0 + (($signed(x) - $signed(16'h0200)) >>> 4);
            else  // x >= 4
                sigmoid = 16'h0100;  // 1.0
        end
        /* verilator lint_on BLKSEQ */
    endfunction
    
    // Fixed-point multiplication
    function signed [DATA_WIDTH-1:0] fp_mult;
        input signed [DATA_WIDTH-1:0] a, b;
        /* verilator lint_off UNUSEDSIGNAL */
        reg signed [31:0] temp;
        /* verilator lint_on UNUSEDSIGNAL */
        begin
            temp = a * b;
            fp_mult = temp[DATA_WIDTH+FRAC_BITS-1:FRAC_BITS];  // Extract correct bits
        end
    endfunction
    
    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            y_out <= 0;
            acc_idx <= 0;
            mult_result <= 0;  // Initialize this too
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    acc_idx <= 0;
                    if (start) begin
                        state <= COMPUTE_HIDDEN;
                    end
                end
                
                COMPUTE_HIDDEN: begin
                    // Compute hidden layer weighted sums

                    // Convert boolean input into fixed-point signed values
                    reg signed [DATA_WIDTH-1:0] x1_fixed;
                    reg signed [DATA_WIDTH-1:0] x2_fixed;
                    x1_fixed = x1 ? 16'h0100 : 16'h0000;
                    x2_fixed = x2 ? 16'h0100 : 16'h0000;

                    for (i = 0; i < 8; i = i + 1) begin
                        hidden_sum[i] <= fp_mult(x1_fixed, w_hidden[i*2]) +
                                    fp_mult(x2_fixed, w_hidden[i*2+1]) +
                                    b_hidden[i];
                    end
                    state <= ACTIVATE_HIDDEN;
                end
                
                ACTIVATE_HIDDEN: begin
                    // Apply sigmoid activation
                    for (i = 0; i < 8; i = i + 1) begin
                        hidden_out[i] <= sigmoid(hidden_sum[i]);
                    end
                    state <= COMPUTE_OUTPUT;
                    acc_idx <= 0;
                    output_sum <= b_output;  // Initialize with bias
                end
                
                COMPUTE_OUTPUT: begin
                    // Simple accumulation - one per cycle
                    if (acc_idx < 4'd8) begin
                        /* verilator lint_off WIDTHTRUNC */
                        output_sum <= output_sum + fp_mult(hidden_out[acc_idx], w_output[acc_idx]);
                        /* verilator lint_on WIDTHTRUNC */
                        acc_idx <= acc_idx + 4'd1;
                    end else begin
                        state <= ACTIVATE_OUTPUT;
                    end
                end
                
                ACTIVATE_OUTPUT: begin
                    reg signed [DATA_WIDTH-1:0] output_value;
                    output_value = sigmoid(output_sum);
                    y_out <= output_value < 16'h007f ? 1'h0 : 1'h1;
                    state <= DONE;
                end
                
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                    done <= 0;
                    y_out <= 0;
                    acc_idx <= 0;
                end
            endcase
        end
    end

endmodule
