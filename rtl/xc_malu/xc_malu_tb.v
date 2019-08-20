
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

integer     test_count   = 0;
integer     clock_ticks  = 0;
parameter   max_ticks    = 10000;

// Initial values
initial begin

    $dumpfile(`STR(`WAVE_FILE));
    $dumpvars(0, xc_malu_tb);

    resetn  = 1'b0;
    clock   = 1'b0;

    #40 resetn = 1'b1;
end

// Make the clock tick.
always @(clock) #20 clock <= !clock;

// Count clock ticks so we finish.
always @(posedge clock) begin

    clock_ticks = clock_ticks + 1;

    if(clock_ticks > max_ticks) begin
        $display("%d tests performed.", test_count);
        $finish;
    end

end

//
// DUT I/O
// -----------------------------------------------------------------------

// Integer representation of which operation to perform. Makes it easier
// to randomly generate a one hot value.
reg integer unsigned dut_operation;

reg [31:0]  dut_rs1                         ; //
reg [31:0]  dut_rs2                         ; //
reg [31:0]  dut_rs3                         ; //
reg         dut_flush                       ; // Flush state.
reg         dut_valid     , n_dut_valid     ; // Inputs valid.
reg         dut_uop_div   , n_dut_uop_div   ; //
reg         dut_uop_divu  , n_dut_uop_divu  ; //
reg         dut_uop_rem   , n_dut_uop_rem   ; //
reg         dut_uop_remu  , n_dut_uop_remu  ; //
reg         dut_uop_mul   , n_dut_uop_mul   ; //
reg         dut_uop_mulu  , n_dut_uop_mulu  ; //
reg         dut_uop_mulsu , n_dut_uop_mulsu ; //
reg         dut_uop_clmul , n_dut_uop_clmul ; //
reg         dut_uop_pmul  , n_dut_uop_pmul  ; //
reg         dut_uop_pclmul, n_dut_uop_pclmul; //
reg         dut_uop_madd  , n_dut_uop_madd  ; //
reg         dut_uop_msub  , n_dut_uop_msub  ; //
reg         dut_uop_macc  , n_dut_uop_macc  ; //
reg         dut_uop_mmul  , n_dut_uop_mmul  ; //
reg         dut_pw_32     , n_dut_pw_32     ; // 32-bit packed elements.
reg         dut_pw_16     , n_dut_pw_16     ; // 16-bit packed elements.
reg         dut_pw_8      , n_dut_pw_8      ; //  8-bit packed elements.
reg         dut_pw_4      , n_dut_pw_4      ; //  4-bit packed elements.
reg         dut_pw_2      , n_dut_pw_2      ; //  2-bit packed elements.
wire [63:0] dut_result    , n_dut_result    ; // 64-bit result
wire        dut_ready     , n_dut_ready     ; // Outputs ready.

always @(posedge clock) begin

    dut_operation <= $unsigned($random) % 8;

    if(!resetn) begin
        dut_rs1        <= 0;
        dut_rs2        <= 0;
        dut_rs3        <= 0;
        dut_valid      <= 0;
        dut_uop_div    <= 0;
        dut_uop_divu   <= 0;
        dut_uop_rem    <= 0;
        dut_uop_remu   <= 0;
        dut_uop_mul    <= 0;
        dut_uop_mulu   <= 0;
        dut_uop_mulsu  <= 0;
        dut_uop_clmul  <= 0;
        dut_uop_pmul   <= 0;
        dut_uop_pclmul <= 0;
        dut_uop_madd   <= 0;
        dut_uop_msub   <= 0;
        dut_uop_macc   <= 0;
        dut_uop_mmul   <= 0;
        dut_pw_32      <= 0;
        dut_pw_16      <= 0;
        dut_pw_8       <= 0;
        dut_pw_4       <= 0;
        dut_pw_2       <= 0;
    end else if(!dut_valid || (dut_valid && dut_ready)) begin
        dut_rs1        <= $random & 32'hFFFFFFFF;
        dut_rs2        <= $random & 32'hFFFFFFFF;
        dut_rs3        <= $random & 32'hFFFFFFFF;
        dut_valid      <= n_dut_valid     ;
        dut_uop_div    <= n_dut_uop_div   ;
        dut_uop_divu   <= n_dut_uop_divu  ;
        dut_uop_rem    <= n_dut_uop_rem   ;
        dut_uop_remu   <= n_dut_uop_remu  ;
        dut_uop_mul    <= n_dut_uop_mul   ;
        dut_uop_mulu   <= n_dut_uop_mulu  ;
        dut_uop_mulsu  <= n_dut_uop_mulsu ;
        dut_uop_clmul  <= n_dut_uop_clmul ;
        dut_uop_pmul   <= n_dut_uop_pmul  ;
        dut_uop_pclmul <= n_dut_uop_pclmul;
        dut_uop_madd   <= n_dut_uop_madd  ;
        dut_uop_msub   <= n_dut_uop_msub  ;
        dut_uop_macc   <= n_dut_uop_macc  ;
        dut_uop_mmul   <= n_dut_uop_mmul  ;
        dut_pw_32      <= n_dut_pw_32     ;
        dut_pw_16      <= n_dut_pw_16     ;
        dut_pw_8       <= n_dut_pw_8      ;
        dut_pw_4       <= n_dut_pw_4      ;
        dut_pw_2       <= n_dut_pw_2      ;

        test_count     <= test_count + 1  ;
    end
end


// Pick the next set of inputs to the DUT.
always @(*) begin

dut_flush = dut_valid && dut_ready;
        
n_dut_uop_div    = 0;
n_dut_uop_divu   = 0;
n_dut_uop_rem    = 0;
n_dut_uop_remu   = 0;
n_dut_uop_mul    = 0;
n_dut_uop_mulu   = 0;
n_dut_uop_mulsu  = 0;
n_dut_uop_clmul  = 0;
n_dut_uop_pmul   = 0;
n_dut_uop_pclmul = 0;
n_dut_uop_madd   = 0;
n_dut_uop_msub   = 0;
n_dut_uop_macc   = 0;
n_dut_uop_mmul   = 0;

n_dut_pw_32      = 0;
n_dut_pw_16      = 0;
n_dut_pw_8       = 0;
n_dut_pw_4       = 0;
n_dut_pw_2       = 0;

case(dut_operation)
 0      : begin n_dut_uop_div   = 1'b1; n_dut_pw_32 = 1'b1; end
 1      : begin n_dut_uop_divu  = 1'b1; n_dut_pw_32 = 1'b1; end
 2      : begin n_dut_uop_rem   = 1'b1; n_dut_pw_32 = 1'b1; end
 3      : begin n_dut_uop_remu  = 1'b1; n_dut_pw_32 = 1'b1; end
 4      : begin n_dut_uop_mul   = 1'b1; n_dut_pw_32 = 1'b1; end
 5      : begin n_dut_uop_mulu  = 1'b1; n_dut_pw_32 = 1'b1; end
 6      : begin n_dut_uop_mulsu = 1'b1; n_dut_pw_32 = 1'b1; end
 7      : begin n_dut_uop_clmul = 1'b1; n_dut_pw_32 = 1'b1; end
 8      : begin n_dut_uop_pmul  = 1'b1; end
 9      : begin n_dut_uop_pclmul= 1'b1; end
 10     : begin n_dut_uop_madd  = 1'b1; n_dut_pw_32 = 1'b1; end
 11     : begin n_dut_uop_msub  = 1'b1; n_dut_pw_32 = 1'b1; end
 12     : begin n_dut_uop_macc  = 1'b1; n_dut_pw_32 = 1'b1; end
 13     : begin n_dut_uop_mmul  = 1'b1; n_dut_pw_32 = 1'b1; end
default : begin /* Do nothing */        end
endcase

n_dut_valid = $random;

end

//
// Result Checking
// -----------------------------------------------------------------------

reg [63:0] expected_result;

task check_expected;
    input [63:0] expected;

    if(expected != dut_result) begin
        $display("ERROR:");
        $display("Expected %x, %d", expected  , expected  );
        $display("Got      %x, %d", dut_result, dut_result);
        $display("RS1: %x, %d", dut_rs1   , dut_rs1   );
        $display("RS2: %x, %d", dut_rs2   , dut_rs2   );
        $display("RS3: %x, %d", dut_rs3   , dut_rs3   );
        $finish;
    end

endtask

always @(posedge clock) if(dut_valid && dut_ready) begin

if( dut_uop_div   ) begin
    if(dut_rs2== 0) expected_result = -64'd1;
    else            expected_result = $signed(dut_rs1) / $signed(dut_rs2);
    check_expected(expected_result);
end

if( dut_uop_divu  ) begin
    if(dut_rs2== 0) expected_result = -64'd1;
    else            expected_result = $unsigned(dut_rs1) / $unsigned(dut_rs2);
    check_expected(expected_result);
end

if( dut_uop_rem   ) begin
    if(dut_rs2== 0) expected_result = dut_rs2;
    else            expected_result = $signed(dut_rs1) % $signed(dut_rs2);
    check_expected(expected_result);
end

if( dut_uop_remu  ) begin
    if(dut_rs2== 0) expected_result = dut_rs2;
    else            expected_result = $unsigned(dut_rs1) % $unsigned(dut_rs2);
    check_expected(expected_result);
end

if( dut_uop_mul   ) begin
    expected_result = $signed(dut_rs1) * $signed(dut_rs2);
    check_expected(expected_result);
end

if( dut_uop_mulu  ) begin
    expected_result = $unsigned(dut_rs1) * $unsigned(dut_rs2);
    check_expected(expected_result);
end

if( dut_uop_mulsu ) begin
    expected_result = $signed(dut_rs1) * $signed({1'b0,dut_rs2});
    check_expected(expected_result);
end

if( dut_uop_clmul ) begin
    // TODO
end

if( dut_uop_pmul  ) begin
    // TODO
end

if( dut_uop_pclmul) begin
    // TODO
end

if( dut_uop_madd  ) begin
    // TODO
end

if( dut_uop_msub  ) begin
    // TODO
end

if( dut_uop_macc  ) begin
    // TODO
end

if( dut_uop_mmul  ) begin
    // TODO
end

end

//
// DUT Instance
// -----------------------------------------------------------------------

xc_malu i_dut(
.clock     (clock     ),
.resetn    (resetn    ),
.rs1       (dut_rs1       ), //
.rs2       (dut_rs2       ), //
.rs3       (dut_rs3       ), //
.flush     (dut_flush     ), // Flush state / pipeline progress
.valid     (dut_valid     ), // Inputs valid.
.uop_div   (dut_uop_div   ), //
.uop_divu  (dut_uop_divu  ), //
.uop_rem   (dut_uop_rem   ), //
.uop_remu  (dut_uop_remu  ), //
.uop_mul   (dut_uop_mul   ), //
.uop_mulu  (dut_uop_mulu  ), //
.uop_mulsu (dut_uop_mulsu ), //
.uop_clmul (dut_uop_clmul ), //
.uop_pmul  (dut_uop_pmul  ), //
.uop_pclmul(dut_uop_pclmul), //
.uop_madd  (dut_uop_madd  ), //
.uop_msub  (dut_uop_msub  ), //
.uop_macc  (dut_uop_macc  ), //
.uop_mmul  (dut_uop_mmul  ), //
.pw_32     (dut_pw_32     ), // 32-bit width packed elements.
.pw_16     (dut_pw_16     ), // 16-bit width packed elements.
.pw_8      (dut_pw_8      ), //  8-bit width packed elements.
.pw_4      (dut_pw_4      ), //  4-bit width packed elements.
.pw_2      (dut_pw_2      ), //  2-bit width packed elements.
.result    (dut_result    ), // 64-bit result
.ready     (dut_ready     )  // Outputs ready.
);

endmodule

