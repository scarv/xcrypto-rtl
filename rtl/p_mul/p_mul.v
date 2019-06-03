
//
// module: p_mul
//
//  Implements the packed multiply and carryless multiply instructions.
//
module p_mul (

input           clock   ,
input           resetn  ,

input           valid   ,
output [ 0:0]   ready   ,

input           mul_l   ,
input           mul_h   ,
input           clmul   ,
input  [4:0]    pw      ,

input  [31:0]   crs1    ,
input  [31:0]   crs2    ,

output [31:0]   result

);


reg  [63:0] psum        ; // Current partial sum
wire [63:0] n_psum      ; // Next partial sum

reg  [ 5:0] count       ; // Number of steps executed so far.
wire [ 5:0] n_count     = count + 1;
wire [ 5:0] m_count     = {pw[0],pw[1],pw[2],pw[3],pw[4], 1'b0};
wire        finish      = valid && count == m_count;

assign      ready       = finish;

//
// One-hot pack width wires
wire pw_32 = pw[0];
wire pw_16 = pw[1];
wire pw_8  = pw[2];
wire pw_4  = pw[3];
wire pw_2  = pw[4];

// Mask for adding 32-bit values
wire [31:0] addm_32     = {32{crs2[count[4:0]]}};

// Mask for adding 16-bit values
wire [15:0] addm_16_0   = {16{crs2[count[3:0] +  0]}};
wire [15:0] addm_16_1   = {16{crs2[count[3:0] + 16]}};
wire [31:0] addm_16     = {addm_16_1, addm_16_0};

// Mask for adding 8-bit values
wire [ 7:0] addm_8_0    = {8{crs2[count[2:0] +  0]}};
wire [ 7:0] addm_8_1    = {8{crs2[count[2:0] +  8]}};
wire [ 7:0] addm_8_2    = {8{crs2[count[2:0] + 16]}};
wire [ 7:0] addm_8_3    = {8{crs2[count[2:0] + 24]}};
wire [31:0] addm_8      = {addm_8_3, addm_8_2,addm_8_1, addm_8_0};

// Mask for adding 4-bit values
wire [ 3:0] addm_4_0    = {4{crs2[count[1:0] +  0]}};
wire [ 3:0] addm_4_1    = {4{crs2[count[1:0] +  4]}};
wire [ 3:0] addm_4_2    = {4{crs2[count[1:0] +  8]}};
wire [ 3:0] addm_4_3    = {4{crs2[count[1:0] + 12]}};
wire [ 3:0] addm_4_4    = {4{crs2[count[1:0] + 16]}};
wire [ 3:0] addm_4_5    = {4{crs2[count[1:0] + 20]}};
wire [ 3:0] addm_4_6    = {4{crs2[count[1:0] + 24]}};
wire [ 3:0] addm_4_7    = {4{crs2[count[1:0] + 28]}};
wire [31:0] addm_4      = {addm_4_7, addm_4_6,addm_4_5, addm_4_4,
                           addm_4_3, addm_4_2,addm_4_1, addm_4_0};

// Mask for adding 2-bit values
wire [ 1:0] addm_2_0    = {2{crs2[count[  0] +  0]}};
wire [ 1:0] addm_2_1    = {2{crs2[count[  0] +  2]}};
wire [ 1:0] addm_2_2    = {2{crs2[count[  0] +  4]}};
wire [ 1:0] addm_2_3    = {2{crs2[count[  0] +  6]}};
wire [ 1:0] addm_2_4    = {2{crs2[count[  0] +  8]}};
wire [ 1:0] addm_2_5    = {2{crs2[count[  0] + 10]}};
wire [ 1:0] addm_2_6    = {2{crs2[count[  0] + 12]}};
wire [ 1:0] addm_2_7    = {2{crs2[count[  0] + 14]}};
wire [ 1:0] addm_2_8    = {2{crs2[count[  0] + 16]}};
wire [ 1:0] addm_2_9    = {2{crs2[count[  0] + 18]}};
wire [ 1:0] addm_2_10   = {2{crs2[count[  0] + 20]}};
wire [ 1:0] addm_2_11   = {2{crs2[count[  0] + 22]}};
wire [ 1:0] addm_2_12   = {2{crs2[count[  0] + 24]}};
wire [ 1:0] addm_2_13   = {2{crs2[count[  0] + 26]}};
wire [ 1:0] addm_2_14   = {2{crs2[count[  0] + 28]}};
wire [ 1:0] addm_2_15   = {2{crs2[count[  0] + 30]}};
wire [31:0] addm_2      = {addm_2_15, addm_2_14, addm_2_13, addm_2_12, 
                           addm_2_11, addm_2_10, addm_2_9 , addm_2_8 ,
                           addm_2_7 , addm_2_6 , addm_2_5 , addm_2_4 ,
                           addm_2_3 , addm_2_2 , addm_2_1 , addm_2_0 };

// Mask for the right hand packed adder input.
wire [31:0] padd_mask   =   {32{pw_32}} & addm_32   |
                            {32{pw_16}} & addm_16   |
                            {32{pw_8 }} & addm_8    |
                            {32{pw_4 }} & addm_4    |
                            {32{pw_2 }} & addm_2    ;

// Inputs to the packed adder

wire [31:0] padd_lhs_32 =  psum[63:32];

wire [31:0] padd_lhs_16 = {psum[63:48], psum[31:16]};

wire [31:0] padd_lhs_8  =
    {psum[63:56], psum[47:40], psum[31:24], psum[15:8]};

wire [31:0] padd_lhs_4  = 
    {psum[63:60], psum[55:52], psum[47:44], psum[39:36], 
     psum[31:28], psum[23:20], psum[15:12], psum[ 7: 4]};

wire [31:0] padd_lhs_2  =
    {psum[63:62], psum[59:58], psum[55:54], psum[51:50], 
     psum[47:46], psum[43:42], psum[39:38], psum[35:34], 
     psum[31:30], psum[27:26], psum[23:22], psum[19:18], 
     psum[15:14], psum[11:10], psum[ 7: 6], psum[ 3: 2]};

wire [31:0] padd_lhs    = 
    {32{pw_32}} & padd_lhs_32 |
    {32{pw_16}} & padd_lhs_16 |
    {32{pw_8 }} & padd_lhs_8  |
    {32{pw_4 }} & padd_lhs_4  |
    {32{pw_2 }} & padd_lhs_2  ;

wire [31:0] padd_rhs    = crs1 & padd_mask;

// Result of the packed addition operation
wire [31:0] padd_carry  ;
wire [31:0] padd_result ;

wire [63:0] n_psum_32 = {padd_carry[31],padd_result,psum[31:1]};

wire [63:0] n_psum_16 = {padd_carry[31],padd_result[31:16],psum[47:33], 
                         padd_carry[15],padd_result[15: 0],psum[15:1 ]};

wire [63:0] n_psum_8  = {padd_carry[31],padd_result[31:24],psum[55:49], 
                         padd_carry[23],padd_result[23:16],psum[39:33], 
                         padd_carry[15],padd_result[15: 8],psum[23:17], 
                         padd_carry[ 7],padd_result[ 7: 0],psum[ 7: 1]};

wire [63:0] n_psum_4  = {padd_carry[31],padd_result[31:28],psum[59:57], 
                         padd_carry[27],padd_result[27:24],psum[51:49], 
                         padd_carry[23],padd_result[23:20],psum[43:41], 
                         padd_carry[19],padd_result[19:16],psum[35:33], 
                         padd_carry[15],padd_result[15:12],psum[27:25], 
                         padd_carry[11],padd_result[11: 8],psum[19:17], 
                         padd_carry[ 7],padd_result[ 7: 4],psum[11: 9], 
                         padd_carry[ 3],padd_result[ 3: 0],psum[ 3: 1]};

wire [63:0] n_psum_2  = {padd_carry[31],padd_result[31:30],psum[61], 
                         padd_carry[29],padd_result[29:28],psum[57], 
                         padd_carry[27],padd_result[27:26],psum[53], 
                         padd_carry[25],padd_result[25:24],psum[49], 
                         padd_carry[23],padd_result[23:22],psum[45], 
                         padd_carry[21],padd_result[21:20],psum[41], 
                         padd_carry[19],padd_result[19:18],psum[37], 
                         padd_carry[17],padd_result[17:16],psum[33], 
                         padd_carry[15],padd_result[15:14],psum[29], 
                         padd_carry[13],padd_result[13:12],psum[25], 
                         padd_carry[11],padd_result[11:10],psum[21], 
                         padd_carry[ 9],padd_result[ 9: 8],psum[17], 
                         padd_carry[ 7],padd_result[ 7: 6],psum[13], 
                         padd_carry[ 5],padd_result[ 5: 4],psum[ 9], 
                         padd_carry[ 3],padd_result[ 3: 2],psum[ 5], 
                         padd_carry[ 1],padd_result[ 1: 0],psum[ 1]};

assign n_psum = 
    {64{pw_32}} & n_psum_32 |
    {64{pw_16}} & n_psum_16 |
    {64{pw_8 }} & n_psum_8  |
    {64{pw_4 }} & n_psum_4  |
    {64{pw_2 }} & n_psum_2  ;

wire [31:0] intermediate = psum >> (32-count);

wire [31:0] result_32 = mul_h ? padd_lhs_32 : psum[31:0];

wire [31:0] result_16 = mul_h ? padd_lhs_16 : {psum[47:32],psum[15:0]};

wire [31:0] result_8  = mul_h ? padd_lhs_8  : 
    {psum[55:48],psum[ 39:32],psum[23:16],psum[ 7:0]};

wire [31:0] result_4  = mul_h ? padd_lhs_4  : 
    {psum[59:56], psum[51:48], psum[43:40], psum[35:32],
     psum[27:24], psum[19:16], psum[11: 8], psum[ 3: 0]};

wire [31:0] result_2  = mul_h ? padd_lhs_2  : 
    {psum[61:60], psum[57:56], psum[53:52], psum[49:48], 
     psum[45:44], psum[41:40], psum[37:36], psum[33:32], 
     psum[29:28], psum[25:24], psum[21:20], psum[17:16], 
     psum[13:12], psum[ 9: 8], psum[ 5: 4], psum[ 1: 0]};

assign result = 
    {32{pw_32}} & result_32 |
    {32{pw_16}} & result_16 |
    {32{pw_8 }} & result_8  |
    {32{pw_4 }} & result_4  |
    {32{pw_2 }} & result_2  ;

//
// Update the count register.
always @(posedge clock) begin
    if(!resetn) begin
        count <= 0;
    end else if(valid && !finish) begin
        count <= n_count;
    end else if(valid &&  finish) begin
        count <= 0;
    end else if(!valid) begin
        count <= 0;
    end
end

//
// Update the partial sum register
always @(posedge clock) begin
    if(!resetn) begin
        psum <= 0;
    end else if(valid && !finish) begin
        psum <= n_psum;
    end else if(valid &&  finish) begin
        psum <= 0;
    end else if(!valid) begin
        psum <= 0;
    end
end

//
// Packed adder instance
p_addsub i_paddsub (
.lhs    (padd_lhs   ), // Left hand input
.rhs    (padd_rhs   ), // Right hand input.
.pw     (pw         ), // Pack width to operate on
.sub    (1'b0       ), // Subtract if set, else add.
.c_out  (padd_carry ), // Carry out
.result (padd_result)  // Result of the operation
);

endmodule
