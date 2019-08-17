
//
// module: xc_malu_long
//
//  Module responsible for handline atomic parts of the multi-precision
//  arithmetic instructions.
//
module xc_malu_long (

input  wire [31:0]  rs1             , //
input  wire [31:0]  rs2             , //
input  wire [31:0]  rs3             , //

input  wire [63:0]  accumulator     ,
input  wire [ 0:0]  carry           ,

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire         padd_cin        , // Carry in bit.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.

input       [31:0]  padd_carry      , // Carry bits
input       [31:0]  padd_result     , // Result of the operation

input  wire         uop_madd        , //
input  wire         uop_msub_1      , //
input  wire         uop_msub_2      , //
input  wire         uop_macc_1      , //
input  wire         uop_macc_2      , //
input  wire         uop_mmul_1      , //
input  wire         uop_mmul_2      , //

output wire         n_carry         ,
output wire [63:0]  n_accumulator    

);

assign padd_sub = uop_msub_1 || uop_msub_2;

assign padd_lhs = {32{uop_msub_1}} & rs1                |
                  {32{uop_macc_2}} & rs1                |
                  {32{uop_msub_2}} & accumulator[31: 0] |
                  {32{uop_mmul_1}} & accumulator[31: 0] |
                  {32{uop_mmul_2}} & accumulator[63:32] |
                  {32{uop_macc_1}} & rs2                ;

assign padd_rhs = {32{uop_msub_1}} & rs2                |
                  {32{uop_macc_2}} & {31'b0, carry }    |
                  {32{uop_mmul_2}} & {31'b0, carry }    |
                  {32{uop_msub_2}} & {31'b0, rs3[0]}    |
                  {32{uop_mmul_1}} & rs3                |
                  {32{uop_macc_1}} & rs3                ;

assign padd_cin = uop_madd && rs3[0];


assign n_accumulator[63:32] = 
    uop_macc_2 || uop_mmul_2 ? padd_result : 0;

assign n_carry = uop_macc_1 || uop_mmul_1 ? {31'b0,padd_carry[31]}   : 0;

assign n_accumulator[31: 0] = 
    uop_msub_1 || uop_msub_2 || uop_macc_1 || uop_mmul_1 ? padd_result      :
                                                           accumulator[31:0];


endmodule
