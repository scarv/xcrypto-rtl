
//
// module: xc_malu
//
//  Implements a multi-cycle arithmetic logic unit for some of
//  the bigger / more complex instructions in XCrypto.
//
//  Instructions handled:
//  - div, divu, rem, remu
//  - mul, mulh, mulhu, mulhsu
//  - pmul.l, pmul.h
//  - clmul, clmulr, clmulh
//  - madd, msub, macc, mmul
//
//  Instruction | Step 0            | Step 1        | Step 2
//  ------------|-------------------|---------------|-------------------
//  div         | r1 / r2           |               |
//  divu        | r1 / r2           |               |
//  rem         | r1 / r2           |               |
//  remu        | r1 / r2           |               |
//  mul         | r1 * r2           |               |
//  mulh        | r1 * r2           |               |
//  mulhu       | r1 * r2           |               |
//  mulhsu      | r1 * r2           |               |
//  pmul.l      | r1 * r2           |               |
//  pmul.h      | r1 * r2           |               |
//  clmul       | r1 x r2           |               |
//  clmulr      | r1 x r2           |               |
//  clmulh      | r1 x r2           |               |
//  madd        | r1 + r2 + r3[0]   |               |
//  msub        | r1 - r2           | ac_lo - r3    |
//  macc        | r2 + r3           | ac_hi + co    |
//  mmul        | r1 * r2           | ac_lo + r3    | ac_hi + co
//  
//  Micro-op    | Operation                 | Modifiers     
//  ------------|---------------------------|---------------
//  drem        | {quot, acc} <= r1/r2      | unsigned      
//  mul         | acc <= r1*r2              | lh_sign, rh_sign, carryless, pw
//  madd        | res <= r1+r2+r3[0]        | 
//  msub_1      | acc <= r1-r2              |
//  msub_2      | acc_lo <= acc_lo - r3[0]  |
//  macc_1      | {carry, acc_lo} <= r2+r3  |
//  macc_2      | acc_hi <= r1 + carry      |
//
//
module xc_malu (

input  wire         clock           ,
input  wire         resetn          ,

input  wire [31:0]  rs1             , //
input  wire [31:0]  rs2             , //
input  wire [31:0]  rs3             , //

input  wire         flush           , // Flush state / pipeline progress
input  wire         valid           , // Inputs valid.

input  wire         uop_div         , //
input  wire         uop_rem         , //
input  wire         uop_mul         , //
input  wire         uop_pmul        , //
input  wire         uop_madd        , //
input  wire         uop_msub_1      , //
input  wire         uop_msub_2      , //
input  wire         uop_macc_1      , //
input  wire         uop_macc_2      , //

input  wire         mod_lh_sign     , // RS1 is signed
input  wire         mod_rh_sign     , // RS2 is signed
input  wire         mod_carryless   , // Do a carryless multiplication.
input  wire         pw_32           , // 32-bit width packed elements.
input  wire         pw_16           , // 32-bit width packed elements.
input  wire         pw_8            , // 32-bit width packed elements.
input  wire         pw_4            , // 32-bit width packed elements.
input  wire         pw_2            , // 32-bit width packed elements.

output wire [63:0]  result          , // 64-bit multiply result

output wire         ready             // Outputs ready.

);


//
// Submodule interface wires
// -----------------------------------------------------------------

wire         uop_drem   = uop_div || uop_rem;

wire [31:0]  divrem_padd_lhs        ; // Left hand input
wire [31:0]  divrem_padd_rhs        ; // Right hand input.
wire [ 0:0]  divrem_padd_sub        ; // Subtract if set, else add.
wire [63:0]  divrem_n_accumulator   ;
wire [31:0]  divrem_n_arg0          ;
wire [31:0]  divrem_n_arg1          ;
wire         divrem_ready           ;

wire         div_outsign  = (mod_lh_sign && (rs1[31] != rs2[31]) && |rs2);
wire         rem_outsign  = (mod_lh_sign && rs1[31]);

wire [31:0]  neg_arg      = -(uop_div   ? arg1  : arg0);

wire [31:0]  result_div_r = rem_outsign ? neg_arg : arg0;
wire [31:0]  result_div_q = div_outsign ? neg_arg : arg1;


wire [31:0]  mul_padd_lhs        ; // Left hand input
wire [31:0]  mul_padd_rhs        ; // Right hand input.
wire         mul_padd_sub        ; // Subtract if set, else add.
wire [63:0]  mul_n_acc           ;
wire [32:0]  mul_n_arg0          ;
wire         mul_finished        ;

wire [31:0]  pmul_padd_lhs       ; // Left hand input
wire [31:0]  pmul_padd_rhs       ; // Right hand input.
wire [ 0:0]  pmul_padd_sub       ; // Subtract if set, else add.
wire [63:0]  pmul_n_accumulator  ;
wire [63:0]  pmul_result         =0;
wire [32:0]  pmul_n_argument     ;
wire         pmul_finished       ;

//
// Result Multiplexing
// -----------------------------------------------------------------

assign       result       = {64{uop_div }} & {32'b0, result_div_q} |
                            {64{uop_rem }} & {32'b0, result_div_r} |
                            {64{uop_mul }} & {acc                } |
                            {64{uop_pmul}} & {pmul_result        } ;

//
// Packed Adder Interface
// -----------------------------------------------------------------

wire [31:0] padd_lhs = {32{uop_drem}} & divrem_padd_lhs |
                       {32{uop_mul }} & mul_padd_lhs    |
                       {32{uop_pmul}} & pmul_padd_lhs   ;

wire [31:0] padd_rhs = {32{uop_drem}} & divrem_padd_rhs |
                       {32{uop_mul }} & mul_padd_rhs    |
                       {32{uop_pmul}} & pmul_padd_rhs   ;

wire        padd_sub =     uop_drem  && divrem_padd_sub ||
                           uop_mul   && mul_padd_sub    ;

wire        padd_cin =     uop_drem  && 1'b1            ;

wire        padd_cen =     uop_drem                     ||
                           uop_mul   && !mod_carryless  ||
                           uop_pmul                     ;

wire [ 4:0] padd_pw = {pw_2, pw_4, pw_8, pw_16, pw_32};

wire [31:0] padd_cout;
wire [31:0] padd_result;

//
// Register State
// -----------------------------------------------------------------

reg         count_en ;

always @(posedge clock) begin
    if(!resetn || flush) begin
        count_en <= 1'b0;
    end else if(valid && !count_en) begin
        count_en <= 1'b1;
    end
end

reg  [ 5:0] count    ;   // State / step counter.
wire [ 5:0] n_count = count + 1;

reg  [63:0] acc      ;   // Accumulator

wire [63:0] n_acc    = {64{uop_drem}} & divrem_n_accumulator    |
                       {64{uop_mul }} & mul_n_acc               |
                       {64{uop_pmul}} & pmul_n_accumulator      ;
                     
reg  [31:0] arg0     ;   // Misc intermediate variable
wire [31:0] n_arg0   = {32{uop_drem}} & divrem_n_arg0           |
                       {32{uop_mul }} & mul_n_arg0              |
                       {32{uop_pmul}} & pmul_n_argument         ;
                     
reg  [31:0] arg1     ;   // Misc intermediate variable
wire [31:0] n_arg1   =                  divrem_n_arg1           ;

always @(posedge clock) begin
    if(!resetn || flush) begin
        count <= 0;
        acc   <= 0;
        arg0  <= 0;
        arg1  <= 0;
    end else if(valid && !count_en) begin
        acc   <= uop_drem ? n_acc : 0  ;
        arg0  <= uop_drem ? n_arg0: rs2;
    end else if(count_en && !ready) begin
        count <= n_count;
        acc   <= n_acc  ;
        arg0  <= n_arg0 ;
        arg1  <= n_arg1 ;
    end
end

//
// Are we finished yet?
// -----------------------------------------------------------------

assign ready = uop_drem && divrem_ready ||
               uop_mul  && mul_finished ||
               uop_pmul && pmul_finished;

//
// Submodule instances.
// -----------------------------------------------------------------

//
// instance : p_addsub
//
//  Packed addition/subtraction for 32-bit 2s complement values.
//
p_addsub i_p_addsub(
.lhs     (padd_lhs   ), // Left hand input
.rhs     (padd_rhs   ), // Right hand input.
.pw      (padd_pw    ), // Pack width to operate on
.cin     (padd_cin   ), // Carry in bit.
.sub     (padd_sub   ), // Subtract if set, else add.
.c_en    (padd_cen   ), // Carry enable bits.
.c_out   (padd_cout  ), // Carry bits
.result  (padd_result)  // Result of the operation
);


//
// instance: xc_malu_divrem
//
//  Implements {div, divu, rem, remu} instructions.
//
xc_malu_divrem i_malu_divrem(
.clock           (clock                 ),
.resetn          (resetn                ),
.rs1             (rs1                   ),
.rs2             (rs2                   ),
.valid           (uop_drem && valid     ),
.op_signed       (mod_lh_sign           ),
.flush           (flush                 ),
.counter         (count                 ),
.accumulator     (acc                   ), // divisor
.arg0            (arg0                  ), // dividend
.arg1            (arg1                  ), // quotient
.padd_lhs        (divrem_padd_lhs       ), // Left hand input
.padd_rhs        (divrem_padd_rhs       ), // Right hand input.
.padd_sub        (divrem_padd_sub       ), // Subtract if set, else add.
.padd_carry      (padd_cout             ), // Carry bits
.padd_result     (padd_result           ), // Result of the operation
.n_accumulator   (divrem_n_accumulator  ),
.n_arg0          (divrem_n_arg0         ),
.n_arg1          (divrem_n_arg1         ),
.finished        (divrem_ready          ) 
);


//
// Handles instructions:
//  - mul
//  - mulh
//  - mulhu
//  - mulhsu
//
xc_malu_mul i_xc_malu_mul(
.rs1           (rs1             ),
.rs2           (rs2             ),
.counter       (count           ),
.accumulator   (acc             ),
.argument      (arg0            ),
.carryless     (mod_carryless   ),
.lhs_sign      (mod_lh_sign     ),
.rhs_sign      (mod_rh_sign     ),
.padd_lhs      (mul_padd_lhs    ), // Left hand input
.padd_rhs      (mul_padd_rhs    ), // Right hand input.
.padd_sub      (mul_padd_sub    ), // Subtract if set, else add.
.padd_carry    (padd_cout       ), // Carry bits
.padd_result   (padd_result     ), // Result of the operation
.n_accumulator (mul_n_acc       ),
.n_argument    (mul_n_arg0      ),
.finished      (mul_finished    )
);

//
// Handles instructions:
//  - pmul
//  - pmulh
//
xc_malu_pmul i_xc_malu_pmul(
.rs1             (rs1               ),
.rs2             (rs2               ),
.counter         (count             ),
.accumulator     (acc               ),
.argument        (arg0              ),
.pw              (padd_pw           ),
.padd_lhs        (pmul_padd_lhs     ), // Left hand input
.padd_rhs        (pmul_padd_rhs     ), // Right hand input.
.padd_sub        (pmul_padd_sub     ), // Subtract if set, else add.
.padd_carry      (padd_cout         ), // Carry bits
.padd_result     (padd_result       ), // Result of the operation
.n_accumulator   (pmul_n_accumulator),
.n_argument      (pmul_n_argument   ),
.finished        (pmul_finished     )
);

endmodule

