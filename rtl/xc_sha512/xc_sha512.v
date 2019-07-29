
//
// module: xc_sha512
//
//  Implements the light-weight SHA512 instruction functions.
//
module xc_sha512 (

input  wire [63:0] rs1   , // Input source register 1
input  wire [ 1:0] ss    , // Exactly which transformation to perform?

output wire [63:0] result  // 

);

`define ROR64(a,b) ((a >> b) | (a << 64-b))
`define SRL64(a,b) ((a >> b)              )

//
// Which transformation to perform?
wire s0 = ss == 2'b00;
wire s1 = ss == 2'b01;
wire s2 = ss == 2'b10;
wire s3 = ss == 2'b11;

wire [63:0] pr_0 =
    {64{s0}} & (`ROR64(rs1, 1)) |
    {64{s1}} & (`ROR64(rs1,19)) |
    {64{s2}} & (`ROR64(rs1,28)) |
    {64{s3}} & (`ROR64(rs1,14)) ;

wire [63:0] pr_1 =
    {64{s0}} & (`ROR64(rs1, 8)) |
    {64{s1}} & (`ROR64(rs1,61)) |
    {64{s2}} & (`ROR64(rs1,34)) |
    {64{s3}} & (`ROR64(rs1,18)) ;

wire [63:0] pr_2 =
    {64{s0}} & (`SRL64(rs1, 7)) |
    {64{s1}} & (`SRL64(rs1, 6)) |
    {64{s2}} & (`ROR64(rs1,39)) |
    {64{s3}} & (`ROR64(rs1,41)) ;

assign result = pr_0 ^ pr_1 ^ pr_2;

`undef ROR64
`undef SRL64

endmodule
