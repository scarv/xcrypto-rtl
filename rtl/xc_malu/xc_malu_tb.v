
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
    dut_valid   = 1'b0;

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
// 32-bit carryless multiply reference function.
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

//
// DUT I/O
reg  [31:0]  dut_rs1             ; //
reg  [31:0]  dut_rs2             ; //
reg  [31:0]  dut_rs3             ; //
wire         dut_flush = dut_valid && dut_ready;
reg          dut_valid           ; // Inputs valid.
reg          dut_uop_div         ; //
reg          dut_uop_rem         ; //
reg          dut_uop_mul         ; //
reg          dut_uop_pmul        ; //
reg          dut_uop_madd        ; //
reg          dut_uop_msub_1      ; //
reg          dut_uop_msub_2      ; //
reg          dut_uop_macc_1      ; //
reg          dut_uop_macc_2      ; //
reg          dut_mod_lh_sign     ; // RS1 is signed
reg          dut_mod_rh_sign     ; // RS2 is signed
reg          dut_mod_carryless   ; // Do a carryless multiplication.
reg          dut_pw_32           ; // 32-bit width packed elements.
reg          dut_pw_16           ; // 32-bit width packed elements.
reg          dut_pw_8            ; // 32-bit width packed elements.
reg          dut_pw_4            ; // 32-bit width packed elements.
reg          dut_pw_2            ; // 32-bit width packed elements.

reg  [31:0]  n_dut_rs1           ; //
reg  [31:0]  n_dut_rs2           ; //
reg  [31:0]  n_dut_rs3           ; //
reg          n_dut_valid         ; // Inputs valid.
reg          n_dut_uop_div       ; //
reg          n_dut_uop_rem       ; //
reg          n_dut_uop_mul       ; //
reg          n_dut_uop_pmul      ; //
reg          n_dut_uop_madd      ; //
reg          n_dut_uop_msub_1    ; //
reg          n_dut_uop_msub_2    ; //
reg          n_dut_uop_macc_1    ; //
reg          n_dut_uop_macc_2    ; //
reg          n_dut_mod_lh_sign   ; // RS1 is signed
reg          n_dut_mod_rh_sign   ; // RS2 is signed
reg          n_dut_mod_carryless ; // Do a carryless multiplication.
reg          n_dut_pw_32         ; // 32-bit width packed elements.
reg          n_dut_pw_16         ; // 32-bit width packed elements.
reg          n_dut_pw_8          ; // 32-bit width packed elements.
reg          n_dut_pw_4          ; // 32-bit width packed elements.
reg          n_dut_pw_2          ; // 32-bit width packed elements.

wire [63:0]  dut_result          ; // 64-bit result
wire         dut_ready           ; // Outputs ready.

always @(posedge clock) begin
    
    dut_valid        <= n_dut_valid;
    dut_rs1          <= n_dut_rs1   ;
    dut_rs2          <= n_dut_rs2   ;
    dut_rs3          <= n_dut_rs3   ;
    dut_uop_div      <= n_dut_uop_div       ; //
    dut_uop_rem      <= n_dut_uop_rem       ; //
    dut_uop_mul      <= n_dut_uop_mul       ; //
    dut_uop_pmul     <= n_dut_uop_pmul      ; //
    dut_uop_madd     <= n_dut_uop_madd      ; //
    dut_uop_msub_1   <= n_dut_uop_msub_1    ; //
    dut_uop_msub_2   <= n_dut_uop_msub_2    ; //
    dut_uop_macc_1   <= n_dut_uop_macc_1    ; //
    dut_uop_macc_2   <= n_dut_uop_macc_2    ; //
    dut_mod_lh_sign  <= n_dut_mod_lh_sign   ; // RS1 is signed
    dut_mod_rh_sign  <= n_dut_mod_rh_sign   ; // RS2 is signed
    dut_mod_carryless<= n_dut_mod_carryless ; // Do a carryless multiplication.
    dut_pw_32        <= n_dut_pw_32         ; // 32-bit width packed elements.
    dut_pw_16        <= n_dut_pw_16         ; // 32-bit width packed elements.
    dut_pw_8         <= n_dut_pw_8          ; // 32-bit width packed elements.
    dut_pw_4         <= n_dut_pw_4          ; // 32-bit width packed elements.
    dut_pw_2         <= n_dut_pw_2          ; // 32-bit width packed elements.

end

//
// Input stimulus generation
always @(posedge clock) begin
    
    // Generate new inputs?
    if(!dut_valid || (dut_valid && dut_ready)) begin

        n_dut_rs1 = $random & 32'h80000001;
        n_dut_rs2 = $random & 32'h80000001;
        n_dut_rs3 = $random & 32'h80000001;

        n_dut_pw_32 = 1'b0;
        n_dut_pw_16 = 1'b0;
        n_dut_pw_8  = 1'b0;
        n_dut_pw_4  = 1'b0;
        n_dut_pw_2  = 1'b0;

        n_dut_mod_carryless = 1'b0;
        n_dut_mod_lh_sign   = 1'b0;
        n_dut_mod_rh_sign   = 1'b0;
        
        {n_dut_uop_div   ,
         n_dut_uop_rem   ,
         n_dut_uop_mul   ,
         n_dut_uop_pmul  ,
         n_dut_uop_madd  ,
         n_dut_uop_msub_1,
         n_dut_uop_msub_2,
         n_dut_uop_macc_1,
         n_dut_uop_macc_2} = (9'b000100000);// << ($random % 9));

        if(dut_uop_div || dut_uop_rem) begin
            n_dut_mod_lh_sign   = $random;
            n_dut_mod_rh_sign   = n_dut_mod_lh_sign;
            n_dut_pw_32         = 1'b1;
        end else if(dut_uop_mul) begin
            n_dut_mod_carryless = $random;
            if(!n_dut_mod_carryless) begin
                n_dut_mod_lh_sign   = $random;
                n_dut_mod_rh_sign   = $random && n_dut_mod_lh_sign;
            end
            n_dut_pw_32         = 1'b1;
        end else if(dut_uop_pmul) begin
            n_dut_mod_carryless = $random;
            n_dut_mod_lh_sign   = 0;
            n_dut_mod_rh_sign   = 0;
            {n_dut_pw_32,
             n_dut_pw_16,
             n_dut_pw_8 ,
             n_dut_pw_4 ,
             n_dut_pw_2 } = 5'b1 << ($random % 4);
        end
        
        n_dut_valid = $random && resetn;

    end

end

reg finish; // Finish the simulation?

//
// Results checking
always @(posedge clock) if(resetn) begin

    finish = 0;

    if(dut_valid == 1'b1 && dut_ready == 1'b1) begin

        test_count = test_count + 1;

        if(grm_result != dut_result) begin
            finish = 1;
        end

    end
    
    if(finish) begin
        $display("ERROR:");
        $display("dut_uop_div   : %b", dut_uop_div   );
        $display("dut_uop_rem   : %b", dut_uop_rem   );
        $display("dut_uop_mul   : %b", dut_uop_mul   );
        $display("dut_uop_pmul  : %b", dut_uop_pmul  );
        $display("dut_uop_madd  : %b", dut_uop_madd  );
        $display("dut_uop_msub_1: %b", dut_uop_msub_1);
        $display("dut_uop_msub_2: %b", dut_uop_msub_2);
        $display("dut_uop_macc_1: %b", dut_uop_macc_1);
        $display("dut_uop_macc_2: %b", dut_uop_macc_2);
        $display("- LHS Sign: %d, RHS Sign: %d",dut_mod_lh_sign, dut_mod_rh_sign);
        $display("- Carryless: %d", dut_mod_carryless);
        $display("- Expected %d = %d . %d", grm_result, dut_rs1, dut_rs2);
        $display("- Expected %x = %x . %x", grm_result, dut_rs1, dut_rs2);
        $display("- Got      %x          ", dut_result);
        $finish;
    end

end
                    
wire [63:0] mul_ss = $signed(dut_rs1) * $signed(dut_rs2);
wire [63:0] mul_su = $signed(dut_rs1) * $unsigned(dut_rs2);
wire [63:0] mul_us = $unsigned(dut_rs1) * $signed(dut_rs2);
wire [63:0] mul_uu = $unsigned(dut_rs1) * $unsigned(dut_rs2);

reg [63:0] grm_result;
       
always @(*) begin

    grm_result = 64'hDEADBEEFBEADEADD1;

    if(dut_uop_div) begin
        
        if(dut_rs2 == 0) begin
            grm_result = -1;
        end else if(dut_mod_lh_sign) begin
            grm_result = $signed(dut_rs1) / $signed(dut_rs2);
        end else begin
            grm_result = $unsigned(dut_rs1) / $unsigned(dut_rs2);
        end

    end else if(dut_uop_rem) begin
        
        if(dut_rs2 == 0) begin
            grm_result = dut_rs1;
        end else if(dut_mod_lh_sign) begin
            grm_result = $signed(dut_rs1) % $signed(dut_rs2);
        end else begin
            grm_result = $unsigned(dut_rs1) % $unsigned(dut_rs2);
        end

    end else if(dut_uop_mul) begin

        if(dut_mod_carryless && dut_pw_32) begin
        
            grm_result =  clmul_ref(dut_rs1,dut_rs2,32);

        end else if(!dut_mod_carryless && dut_pw_32) begin

            if         ( dut_mod_lh_sign &&  dut_mod_rh_sign) begin
                grm_result = mul_ss;

            end else if( dut_mod_lh_sign && !dut_mod_rh_sign) begin
                grm_result = mul_su;

            end else if(!dut_mod_lh_sign &&  dut_mod_rh_sign) begin
                grm_result = mul_us;

            end else if(!dut_mod_lh_sign && !dut_mod_rh_sign) begin
                grm_result = mul_uu;

            end

        end
    end
end

//
// Instance of the DUT.
//
xc_malu i_dut(
.clock           (    clock           ),
.resetn          (    resetn          ),
.rs1             (dut_rs1             ), //
.rs2             (dut_rs2             ), //
.rs3             (dut_rs3             ), //
.flush           (dut_flush           ), // Flush state / pipeline progress
.valid           (dut_valid           ), // Inputs valid.
.uop_div         (dut_uop_div         ), //
.uop_rem         (dut_uop_rem         ), //
.uop_mul         (dut_uop_mul         ), //
.uop_pmul        (dut_uop_pmul        ), //
.uop_madd        (dut_uop_madd        ), //
.uop_msub_1      (dut_uop_msub_1      ), //
.uop_msub_2      (dut_uop_msub_2      ), //
.uop_macc_1      (dut_uop_macc_1      ), //
.uop_macc_2      (dut_uop_macc_2      ), //
.mod_lh_sign     (dut_mod_lh_sign     ), // RS1 is signed
.mod_rh_sign     (dut_mod_rh_sign     ), // RS2 is signed
.mod_carryless   (dut_mod_carryless   ), // Do a carryless multiplication.
.pw_32           (dut_pw_32           ), // 32-bit width packed elements.
.pw_16           (dut_pw_16           ), // 32-bit width packed elements.
.pw_8            (dut_pw_8            ), // 32-bit width packed elements.
.pw_4            (dut_pw_4            ), // 32-bit width packed elements.
.pw_2            (dut_pw_2            ), // 32-bit width packed elements.
.result          (dut_result          ), // 64-bit result
.ready           (dut_ready           )  // Outputs ready.
);


//
// Checker instantiation for packed multiplication..
// p_mul_checker i_p_mul_checker (
// .mul_l (1'b1        ),
// .mul_h (1'b0        ),
// .clmul (dut_mod_carryless),
// .pw    (pw          ),
// .crs1  (rs1         ),
// .crs2  (rs2         ),
// .result_hi(pmul_result_hi),
// .result(pmul_result_lo)
// );

endmodule

