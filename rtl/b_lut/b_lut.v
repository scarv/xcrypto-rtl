
//
// module: b_lut
//
//  Implements the core logic for the xc.lut instruction.
//
module b_lut (

input  wire [31:0] crs1  , // Source register 1 (LUT input)
input  wire [31:0] crs2  , // Source register 2 (LUT bottom half)
input  wire [31:0] crs3  , // Source register 3 (LUT top half)

output wire [31:0] result  //

);


wire [ 3:0] lut_arr [15:0];
wire [63:0] lut_con = {crs3, crs2};

genvar i;
generate for (i = 0; i < 16; i = i + 1) begin

    assign lut_arr[i] = lut_con[4*i+3:4*i];

end endgenerate


genvar j;
generate for (j = 0; j < 8; j = j + 1) begin

    wire [3:0] lut_in = crs1[4*j+3:4*j];

    wire [31:0] l1 = lut_in[3] ? lut_con[63:32] : lut_con[31:0];
    wire [15:0] l2 = lut_in[2] ? l1[31:16] : l1[15:0];
    wire [ 7:0] l3 = lut_in[1] ? l2[15: 8] : l2[ 7:0];
    wire [ 3:0] l4 = lut_in[0] ? l3[ 7: 4] : l3[ 3:0];

    assign result[4*j+3:4*j] = l4;

end endgenerate

endmodule
