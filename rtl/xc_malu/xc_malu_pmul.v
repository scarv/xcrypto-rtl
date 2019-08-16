
//
// Handles instructions:
//  - pmul
//  - pmulh
//
module xc_malu_pmul (

input  wire [31:0]  rs1             ,
input  wire [31:0]  rs2             ,

input  wire [ 5:0]  counter         ,
input  wire [63:0]  accumulator     ,
input  wire [31:0]  argument        ,

input  wire [ 4:0]  pw              ,

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.

input       [31:0]  padd_carry      , // Carry bits
input       [31:0]  padd_result     , // Result of the operation

output wire [63:0]  n_accumulator   ,
output wire [32:0]  n_argument      ,
output wire         finished        

);

//
// One-hot pack width wires
wire pw_16 = pw[1];
wire pw_8  = pw[2];
wire pw_4  = pw[3];
wire pw_2  = pw[4];

wire [5:0] counter_finish = {pw_16,pw_8,pw_4,pw_2,1'b0};

assign n_argument   = {1'b0, argument[31:1]};

assign finished     = counter == counter_finish;

wire add_en_16_0    = argument[ 0];
wire add_en_16_1    = argument[16];

wire add_en_8_0     = argument[ 0];
wire add_en_8_1     = argument[ 8];
wire add_en_8_2     = argument[16];
wire add_en_8_3     = argument[24];

wire add_en_4_0     = argument[ 0];
wire add_en_4_1     = argument[ 4];
wire add_en_4_2     = argument[ 8];
wire add_en_4_3     = argument[12];
wire add_en_4_4     = argument[16];
wire add_en_4_5     = argument[20];
wire add_en_4_6     = argument[24];
wire add_en_4_7     = argument[28];

wire add_en_2_0     = argument[ 0];
wire add_en_2_1     = argument[ 2];
wire add_en_2_2     = argument[ 4];
wire add_en_2_3     = argument[ 6];
wire add_en_2_4     = argument[ 8];
wire add_en_2_5     = argument[10];
wire add_en_2_6     = argument[12];
wire add_en_2_7     = argument[14];
wire add_en_2_8     = argument[16];
wire add_en_2_9     = argument[18];
wire add_en_2_10    = argument[20];
wire add_en_2_11    = argument[22];
wire add_en_2_12    = argument[24];
wire add_en_2_13    = argument[26];
wire add_en_2_14    = argument[28];
wire add_en_2_15    = argument[30];

// Mask for adding 16-bit values
wire [15:0] addm_16_0   = {16{add_en_16_0}};
wire [15:0] addm_16_1   = {16{add_en_16_1}};
wire [31:0] addm_16     = {addm_16_1, addm_16_0};

// Mask for adding 8-bit values
wire [ 7:0] addm_8_0    = {8{add_en_8_0}};
wire [ 7:0] addm_8_1    = {8{add_en_8_1}};
wire [ 7:0] addm_8_2    = {8{add_en_8_2}};
wire [ 7:0] addm_8_3    = {8{add_en_8_3}};
wire [31:0] addm_8      = {addm_8_3, addm_8_2,addm_8_1, addm_8_0};

// Mask for adding 4-bit values
wire [ 3:0] addm_4_0    = {4{add_en_4_0}};
wire [ 3:0] addm_4_1    = {4{add_en_4_1}};
wire [ 3:0] addm_4_2    = {4{add_en_4_2}};
wire [ 3:0] addm_4_3    = {4{add_en_4_3}};
wire [ 3:0] addm_4_4    = {4{add_en_4_4}};
wire [ 3:0] addm_4_5    = {4{add_en_4_5}};
wire [ 3:0] addm_4_6    = {4{add_en_4_6}};
wire [ 3:0] addm_4_7    = {4{add_en_4_7}};
wire [31:0] addm_4      = {addm_4_7, addm_4_6,addm_4_5, addm_4_4,
                           addm_4_3, addm_4_2,addm_4_1, addm_4_0};

// Mask for adding 2-bit values
wire [ 1:0] addm_2_0    = {2{add_en_2_0 }};
wire [ 1:0] addm_2_1    = {2{add_en_2_1 }};
wire [ 1:0] addm_2_2    = {2{add_en_2_2 }};
wire [ 1:0] addm_2_3    = {2{add_en_2_3 }};
wire [ 1:0] addm_2_4    = {2{add_en_2_4 }};
wire [ 1:0] addm_2_5    = {2{add_en_2_5 }};
wire [ 1:0] addm_2_6    = {2{add_en_2_6 }};
wire [ 1:0] addm_2_7    = {2{add_en_2_7 }};
wire [ 1:0] addm_2_8    = {2{add_en_2_8 }};
wire [ 1:0] addm_2_9    = {2{add_en_2_9 }};
wire [ 1:0] addm_2_10   = {2{add_en_2_10}};
wire [ 1:0] addm_2_11   = {2{add_en_2_11}};
wire [ 1:0] addm_2_12   = {2{add_en_2_12}};
wire [ 1:0] addm_2_13   = {2{add_en_2_13}};
wire [ 1:0] addm_2_14   = {2{add_en_2_14}};
wire [ 1:0] addm_2_15   = {2{add_en_2_15}};
wire [31:0] addm_2      = {addm_2_15, addm_2_14, addm_2_13, addm_2_12, 
                           addm_2_11, addm_2_10, addm_2_9 , addm_2_8 ,
                           addm_2_7 , addm_2_6 , addm_2_5 , addm_2_4 ,
                           addm_2_3 , addm_2_2 , addm_2_1 , addm_2_0 };

// Mask for the right hand packed adder input.
wire [31:0] padd_mask   =   {32{pw_16}} & addm_16   |
                            {32{pw_8 }} & addm_8    |
                            {32{pw_4 }} & addm_4    |
                            {32{pw_2 }} & addm_2    ;

// Inputs to the packed adder

wire [31:0] padd_lhs_16 = {accumulator[63:48], accumulator[31:16]};

wire [31:0] padd_lhs_8  =
    {accumulator[63:56], accumulator[47:40], accumulator[31:24], accumulator[15:8]};

wire [31:0] padd_lhs_4  = 
    {accumulator[63:60], accumulator[55:52], accumulator[47:44], accumulator[39:36], 
     accumulator[31:28], accumulator[23:20], accumulator[15:12], accumulator[ 7: 4]};

wire [31:0] padd_lhs_2  =
    {accumulator[63:62], accumulator[59:58], accumulator[55:54], accumulator[51:50], 
     accumulator[47:46], accumulator[43:42], accumulator[39:38], accumulator[35:34], 
     accumulator[31:30], accumulator[27:26], accumulator[23:22], accumulator[19:18], 
     accumulator[15:14], accumulator[11:10], accumulator[ 7: 6], accumulator[ 3: 2]};

assign padd_lhs    = 
    {32{pw_16}} & padd_lhs_16 |
    {32{pw_8 }} & padd_lhs_8  |
    {32{pw_4 }} & padd_lhs_4  |
    {32{pw_2 }} & padd_lhs_2  ;

assign padd_rhs    = rs1 & padd_mask;

assign        padd_sub    = 1'b0;

// Result of the packed addition operation
wire [31:0] cadd_carry  = 32'b0; //

wire [31:0] add_result =  padd_result;
wire [31:0] add_carry  =  padd_carry ;

wire [63:0] n_accumulator_16 = 
                        {add_carry[31],add_result[31:16],accumulator[47:33], 
                         add_carry[15],add_result[15: 0],accumulator[15:1 ]};

wire [63:0] n_accumulator_8  =
                        {add_carry[31],add_result[31:24],accumulator[55:49], 
                         add_carry[23],add_result[23:16],accumulator[39:33], 
                         add_carry[15],add_result[15: 8],accumulator[23:17], 
                         add_carry[ 7],add_result[ 7: 0],accumulator[ 7: 1]};

wire [63:0] n_accumulator_4  =
                        {add_carry[31],add_result[31:28],accumulator[59:57], 
                         add_carry[27],add_result[27:24],accumulator[51:49], 
                         add_carry[23],add_result[23:20],accumulator[43:41], 
                         add_carry[19],add_result[19:16],accumulator[35:33], 
                         add_carry[15],add_result[15:12],accumulator[27:25], 
                         add_carry[11],add_result[11: 8],accumulator[19:17], 
                         add_carry[ 7],add_result[ 7: 4],accumulator[11: 9], 
                         add_carry[ 3],add_result[ 3: 0],accumulator[ 3: 1]};

wire [63:0] n_accumulator_2  =
                        {add_carry[31],add_result[31:30],accumulator[61], 
                         add_carry[29],add_result[29:28],accumulator[57], 
                         add_carry[27],add_result[27:26],accumulator[53], 
                         add_carry[25],add_result[25:24],accumulator[49], 
                         add_carry[23],add_result[23:22],accumulator[45], 
                         add_carry[21],add_result[21:20],accumulator[41], 
                         add_carry[19],add_result[19:18],accumulator[37], 
                         add_carry[17],add_result[17:16],accumulator[33], 
                         add_carry[15],add_result[15:14],accumulator[29], 
                         add_carry[13],add_result[13:12],accumulator[25], 
                         add_carry[11],add_result[11:10],accumulator[21], 
                         add_carry[ 9],add_result[ 9: 8],accumulator[17], 
                         add_carry[ 7],add_result[ 7: 6],accumulator[13], 
                         add_carry[ 5],add_result[ 5: 4],accumulator[ 9], 
                         add_carry[ 3],add_result[ 3: 2],accumulator[ 5], 
                         add_carry[ 1],add_result[ 1: 0],accumulator[ 1]};

assign n_accumulator = 
    {64{pw_16}} & n_accumulator_16 |
    {64{pw_8 }} & n_accumulator_8  |
    {64{pw_4 }} & n_accumulator_4  |
    {64{pw_2 }} & n_accumulator_2  ;

wire [31:0] result_1_16 = {accumulator[47:32],accumulator[15:0]};

wire [31:0] result_1_8  = 
{accumulator[55:48],accumulator[ 39:32],accumulator[23:16],accumulator[ 7:0]};

wire [31:0] result_1_4  =
{accumulator[59:56], accumulator[51:48], accumulator[43:40], accumulator[35:32],
accumulator[27:24], accumulator[19:16], accumulator[11: 8], accumulator[ 3: 0]};

wire [31:0] result_1_2  =
{accumulator[61:60], accumulator[57:56], accumulator[53:52], accumulator[49:48], 
accumulator[45:44], accumulator[41:40], accumulator[37:36], accumulator[33:32], 
accumulator[29:28], accumulator[25:24], accumulator[21:20], accumulator[17:16], 
accumulator[13:12], accumulator[ 9: 8], accumulator[ 5: 4], accumulator[ 1: 0]};

endmodule
