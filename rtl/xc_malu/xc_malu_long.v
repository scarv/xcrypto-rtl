
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

input  wire [63:0]  acc             ,
input  wire [ 0:0]  carry           ,
input  wire [ 5:0]  count           ,

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire         padd_cin        , // Carry in bit.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.

input       [31:0]  padd_cout       , // Carry bits
input       [31:0]  padd_result     , // Result of the operation

input  wire         uop_madd        , //
input  wire         uop_msub        , //
input  wire         uop_macc        , //
input  wire         uop_mmul        , //

output wire         n_carry         ,
output wire [63:0]  n_acc           ,
output wire [63:0]  result          ,
output wire         ready           

);

assign padd_lhs     = {32{uop_madd}} & rs1;

assign padd_rhs     = {32{uop_madd}} & rs2;

assign padd_sub     = uop_msub;

assign padd_cin     = uop_msub                      ||
                      uop_madd  && rs3[0]           ;

assign n_carry      = uop_mmul && padd_cout[31]     ||
                      uop_madd && padd_cout[31]     ;

assign n_acc        = {acc[63:32], padd_result};

assign result       = {64{uop_madd}} & {31'b0, padd_cout[31], padd_result};

assign ready        = uop_madd;

endmodule
