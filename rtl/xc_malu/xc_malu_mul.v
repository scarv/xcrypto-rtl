
//
// Handles instructions:
//  - mul
//  - mulh
//  - mulhu
//  - mulhsu
//
module xc_malu_mul (

input  wire [31:0]  rs1             ,
input  wire [31:0]  rs2             ,

input  wire [ 5:0]  counter         ,
input  wire [63:0]  accumulator     ,
input  wire [31:0]  argument        ,

input  wire         carryless       ,

input  wire         lhs_sign        ,
input  wire         rhs_sign        ,

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.

input       [31:0]  padd_carry      , // Carry bits
input       [31:0]  padd_result     , // Result of the operation

output wire [63:0]  n_accumulator   ,
output wire [32:0]  n_argument      ,
output wire         finished        

);

assign finished  = counter == 32;

wire          add_en     = argument[0];

wire          sub_last   = rs2[31] && counter == 31 && rhs_sign && |rs1;

wire [32:0]   add_lhs    = {lhs_sign && accumulator[63], accumulator[63:32]};
wire [32:0]   add_rhs    = add_en ? {lhs_sign && rs1[31], rs1} : 0 ;

assign        padd_lhs   = add_lhs[31:0];
assign        padd_rhs   = add_rhs[31:0];
assign        padd_sub   = sub_last;

wire          add_32     = carryless ? 1'b0 :
                           add_lhs[32] + 
                           add_rhs[32] +
                           sub_last    + padd_carry[31];

wire   [32:0] add_result = {add_32, padd_result};

assign n_accumulator     = {add_result, accumulator[31:1]};

assign n_argument        = {1'b0, argument[31:1]};

endmodule
