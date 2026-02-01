/*
 * TinyTapeout 4-bit State Machine Adder
 *
 * A simple state machine that:
 * 1. IDLE: Waits for load_a signal
 * 2. LOADED_A: Stores operand A, waits for load_b
 * 3. RESULT: Shows A + B with carry, ready flag high
 *
 * Interface:
 *   ui_in[3:0]  - 4-bit data input (operand A or B)
 *   ui_in[4]    - load_a control
 *   ui_in[5]    - load_b control
 *   ui_in[7:6]  - unused
 *
 *   uo_out[3:0] - 4-bit sum output
 *   uo_out[4]   - carry out
 *   uo_out[5]   - ready flag (high when result valid)
 *   uo_out[6]   - state[0] (for debugging)
 *   uo_out[7]   - state[1] (for debugging)
 */

module tt_um_4bit_adder (
    input  wire [7:0] ui_in,    // Data + control inputs
    output wire [7:0] uo_out,   // Sum + status outputs
    input  wire [7:0] uio_in,   // Bidirectional (unused)
    output wire [7:0] uio_out,  // Bidirectional (unused)
    output wire [7:0] uio_oe,   // Bidirectional enable
    input  wire       ena,      // Enable
    input  wire       clk,      // Clock
    input  wire       rst_n     // Active-low reset
);

    // State encoding
    localparam IDLE     = 2'b00;
    localparam LOADED_A = 2'b01;
    localparam RESULT   = 2'b10;

    reg [1:0] state;
    reg [3:0] reg_a;
    reg [4:0] sum;  // 5 bits to capture carry

    // Input signals
    wire [3:0] data_in = ui_in[3:0];
    wire load_a = ui_in[4];
    wire load_b = ui_in[5];

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            reg_a <= 4'b0;
            sum   <= 5'b0;
        end else if (ena) begin
            case (state)
                IDLE: begin
                    if (load_a) begin
                        reg_a <= data_in;
                        state <= LOADED_A;
                    end
                end
                LOADED_A: begin
                    if (load_b) begin
                        sum <= {1'b0, reg_a} + {1'b0, data_in};
                        state <= RESULT;
                    end
                end
                RESULT: begin
                    if (load_a) begin
                        reg_a <= data_in;
                        state <= LOADED_A;
                    end else if (!load_a && !load_b) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    // Output assignments
    assign uo_out[3:0] = sum[3:0];      // 4-bit sum
    assign uo_out[4]   = sum[4];        // Carry out
    assign uo_out[5]   = (state == RESULT); // Ready flag
    assign uo_out[6]   = state[0];      // Debug: state LSB
    assign uo_out[7]   = state[1];      // Debug: state MSB

    // Bidirectional pins unused - set as inputs
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

endmodule
