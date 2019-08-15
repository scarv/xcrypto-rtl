
`define STR(x) `"x`"

`ifndef WAVE_FILE
    `define WAVE_FILE waves.vcd
`endif

//
// module: xc_malu_tb
//
//  Randomised testbech for the xc_malu module.
//  Using a simulation based approach for xc_malu module, since BMC
//  approaches can't handle multiplication.
//
module xc_malu_tb ();

reg          clock           ;
reg          resetn          ;
reg  [31:0]  rs1             ; //
reg  [31:0]  rs2             ; //
reg  [31:0]  rs3             ; //
reg          valid           ; // Inputs valid.
wire         flush           ; // Flush state / pipeline progress
wire         ready           ; // Outputs ready.
reg          insn_mul        ; // Variant of the MUL instruction.
reg          insn_pmul       ; // Variant of the PMUL instruction.
reg          insn_div        ; // Variant of divide
reg          insn_rem        ; // Variant of remainder
reg          insn_macc       ; // Accumulate
reg          insn_madd       ; // Add 3
reg          insn_msub       ; // Subtract 3
reg  [ 2:0]  pw_single       ; // Pack width to operate on
wire [ 4:0]  pw = insn_pmul ? {            // Pack width to operate on
    pw_single == 3'd0,
    pw_single == 3'd1,
    pw_single == 3'd2,
    pw_single == 3'd3,
    pw_single == 3'd4
} : 5'b1;
reg          lhs_sign        ; // MULHSU variant.
reg          rhs_sign        ; // Unsigned instruction variant (MUL).
reg          drem_unsigned   ; // Unsigned div/rem variant.
reg          carryless_r     ; // Do carryless [p]mul.
wire         carryless = carryless_r && (insn_mul || insn_pmul);
wire [31:0]  result_1        ; // High 32 bits of result.
wire [31:0]  result_0        ; // Low 32-bits of result.

wire        output_valid = valid && ready;

integer     clock_ticks  = 0;
parameter   max_ticks    = 10000;

// Initial values
initial begin

    $dumpfile(`STR(`WAVE_FILE));
    $dumpvars(0, xc_malu_tb);

    resetn  = 1'b0;
    clock   = 1'b0;
    valid   = 1'b0;

    #40 resetn = 1'b1;
end

// Make the clock tick.
always @(clock) #20 clock <= !clock;

assign flush = valid && ready;

// Input stimulus generation
always @(posedge clock) begin

    clock_ticks = clock_ticks + 1;

    // Randomise inputs.
    if(!valid || (valid && ready)) begin
        
        rs1             <= ($random & 32'hFFFFFFFF);
        rs2             <= ($random & 32'hFFFFFFFF);
        rs3             <= ($random & 32'hFFFFFFFF);
        
        insn_mul        <= 1'b0; // 32-bit multiply (signed / unsigned)
        insn_pmul       <= 1'b0; // packed multiply
        insn_div        <= 1'b1; // divide
        insn_rem        <= 1'b0; // remainder
        insn_macc       <= 1'b0; // Accumulate
        insn_madd       <= 1'b0; // Add 3
        insn_msub       <= 1'b0; // Subtract 3

        lhs_sign        <= $random;
        rhs_sign        <= $random;
        drem_unsigned   <= $random;
        pw_single       <= $random % 4;
        carryless_r     <= $random;

        valid           <= $random && resetn;
    end

    if(clock_ticks > max_ticks) begin
        $finish;
    end

end

wire [31:0] pmul_result_hi; // Expected results for packed multiplies.
wire [31:0] pmul_result_lo;

reg [63:0] expected;    // Expected result
reg        finish;


//
// 32-bit carryless multiply function.
function [63:0] clmul_ref;
    input [31:0] lhs;
    input [31:0] rhs;
    input [ 5:0] len;

    reg [63:0] result;
    integer i;

    result =  rhs[0] ? lhs : 0;

    for(i = 1; i < len; i = i + 1) begin
        
        result = result ^ (rhs[i] ? lhs<<i : 32'b0);

    end

    clmul_ref = result;

endfunction

wire [63:0] clmul_ref_32 = clmul_ref(rs1,rs2,32);

//
// Results checking
always @(posedge clock) begin

    finish = 0;

    if(valid && ready) begin
        
        if(insn_mul) begin
            if(carryless) begin
                expected = clmul_ref_32;
            end else begin
                if         (!lhs_sign && !rhs_sign) begin
                    expected= $unsigned(rs1) * $unsigned(rs2);
                end else if(!lhs_sign &&  rhs_sign) begin
                    expected= $signed({1'b0,rs1}) * $signed(rs2);
                end else if( lhs_sign && !rhs_sign) begin
                    expected= $signed(rs1) * $signed({1'b0,rs2});
                end else if( lhs_sign &&  rhs_sign) begin
                    expected= $signed(rs1) * $signed(rs2);
                end
            end
        end else if(insn_pmul) begin
            expected = {pmul_result_hi, pmul_result_lo};
        end else if(insn_div) begin
            if(rs2 == 0) begin
                expected = -1;
            end else if(drem_unsigned) begin
                expected = $unsigned(rs1) / $unsigned(rs2);
            end else begin
                expected = $signed(rs1) / $signed(rs2);
            end
            expected = expected & 32'hFFFFFFFF;
        end else if(insn_rem) begin
            if(rs2 == 0) begin
                expected = rs1;
            end else if(drem_unsigned) begin
                expected = $unsigned(rs1) % $unsigned(rs2);
            end else begin
                expected = $signed(rs1) % $signed(rs2);
            end
            expected = expected & 32'hFFFFFFFF;
        end

        if(expected !== {result_1, result_0}) begin
            $display("ERROR:");
            $display("- LHS Sign: %d, RHS Sign: %d",lhs_sign, rhs_sign);
            $display("- Carryless: %d", carryless);
            $display("- Expected %d = %d . %d", expected, rs1, rs2);
            $display("- Expected %x = %x . %x", expected, rs1, rs2);
            $display("- Got      %x          ", {result_1,result_0});
        end
        if(expected[31: 0] !== result_0) begin
            $display("ERROR - Lo:");
            $display("- Expected %d = %d . %d", expected[31:0], rs1, rs2);
            $display("- Expected %x = %x . %x", expected[31:0], rs1, rs2);
            $display("- Got      %x          ", result_0);
            finish = 1;
        end
        if(expected[63:32] !== result_1) begin
            $display("ERROR - Hi:");
            $display("- Expected %d = %d . %d", expected[63:32], rs1, rs2);
            $display("- Expected %x = %x . %x", expected[63:32], rs1, rs2);
            $display("- Got      %x          ", result_1);
            finish = 1;
        end
        
    end
    
    if(finish) begin
        #1 $finish;
    end

end

//
// Instance of the DUT.
//
xc_malu i_dut(
.clock           (clock           ),
.resetn          (resetn          ),
.rs1             (rs1             ), //
.rs2             (rs2             ), //
.rs3             (rs3             ), //
.valid           (valid           ), // Inputs valid.
.flush           (flush           ), // Flush state / pipeline progress
.ready           (ready           ), // Outputs ready.
.insn_mul        (insn_mul        ), // Variant of the MUL instruction.
.insn_pmul       (insn_pmul       ), // Variant of the PMUL instruction.
.insn_div        (insn_div        ), // Variant of divide
.insn_rem        (insn_rem        ), // Variant of remainder
.insn_macc       (insn_macc       ), // Accumulate
.insn_madd       (insn_madd       ), // Add 3
.insn_msub       (insn_msub       ), // Subtract 3
.pw              (pw              ), // Pack width to operate on
.lhs_sign        (lhs_sign        ), // MULHSU variant.
.rhs_sign        (rhs_sign        ), // Unsigned instruction variant.
.drem_unsigned   (drem_unsigned   ), // Unsigned div/rem
.carryless       (carryless       ), // Do carryless [p]mul.
.result_1        (result_1        ), // High 32 bits of result.
.result_0        (result_0        )  // Low 32-bits of result.
);


//
// Checker instantiation for packed multiplication..
p_mul_checker i_p_mul_checker (
.mul_l (1'b1        ),
.mul_h (1'b0        ),
.clmul ( carryless  ),
.pw    (pw          ),
.crs1  (rs1         ),
.crs2  (rs2         ),
.result_hi(pmul_result_hi),
.result(pmul_result_lo)
);

endmodule

