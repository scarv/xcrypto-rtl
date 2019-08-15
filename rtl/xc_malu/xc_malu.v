
//
// module: xc_malu
//
//  Implements a multi-cycle arithmetic logic unit for some of
//  the bigger / more complex instructions in XCrypto.
//
module xc_malu (

input  wire         clock           ,
input  wire         resetn          ,

input  wire [31:0]  rs1             , //
input  wire [31:0]  rs2             , //
input  wire [31:0]  rs3             , //

input  wire         valid           , // Inputs valid.
input  wire         flush           , // Flush state / pipeline progress
output wire         ready           , // Outputs ready.

input  wire         insn_mul        , // Variant of the MUL instruction.
input  wire         insn_pmul       , // Variant of the PMUL instruction.
input  wire         insn_div        , // Variant of divide
input  wire         insn_rem        , // Variant of remainder
input  wire         insn_macc       , // Accumulate
input  wire         insn_madd       , // Add 3
input  wire         insn_msub       , // Subtract 3

input  wire [ 4:0]  pw              , // Pack width to operate on
input  wire         lhs_sign        , // MULHSU variant.
input  wire         rhs_sign        , // Unsigned instruction variant.
input  wire         carryless       , // Do carryless [p]mul
input  wire         drem_unsigned , // unsigned division/remainder.

output wire [31:0]  result_1        , // High 32 bits of result.
output wire [31:0]  result_0          // Low 32-bits of result.

);


//
// Intermediate Wires
// ----------------------------------------------------------------------

// One-hot pack width wires
wire pw_16 = pw[1];
wire pw_8  = pw[2];
wire pw_4  = pw[3];
wire pw_2  = pw[4];

wire [31:0]  mul_padd_lhs       ; // Left hand input
wire [31:0]  mul_padd_rhs       ; // Right hand input.
wire [ 0:0]  mul_padd_sub       ; // Subtract if set, else add.
wire [63:0]  mul_n_accumulator  ;
wire [32:0]  mul_n_argument     ;
wire         mul_n_carry        ;
wire         mul_finished       ;

wire         insn_drem         = insn_div || insn_rem;

wire [31:0]  drem_padd_lhs     ; // Left hand input
wire [31:0]  drem_padd_rhs     ; // Right hand input.
wire [ 0:0]  drem_padd_sub     ; // Subtract if set, else add.
wire [31:0]  drem_padd_carry   ; // Carry bits
wire [31:0]  drem_padd_result  ; // Result of the operation
wire [63:0]  drem_n_accumulator;
wire [32:0]  drem_n_argument   ;
wire         drem_n_carry      ;
wire         drem_finished     ;
wire [31:0]  drem_result       ;

wire [31:0]  pmul_padd_lhs      ; // Left hand input
wire [31:0]  pmul_padd_rhs      ; // Right hand input.
wire [ 0:0]  pmul_padd_sub      ; // Subtract if set, else add.
wire [63:0]  pmul_n_accumulator ;
wire [32:0]  pmul_n_argument    ;
wire         pmul_n_carry       ;
wire         pmul_finished      ;

wire [31:0]  pmul_result_0_16 = {accumulator[32+:16],accumulator[0 +:16]};
wire [31:0]  pmul_result_1_16 = {accumulator[48+:16],accumulator[16+:16]};

wire [31:0]  pmul_result_0_8  = {accumulator[48+: 8],accumulator[32+: 8], 
                                 accumulator[16+: 8],accumulator[0 +: 8]};

wire [31:0]  pmul_result_1_8  = {accumulator[56+: 8],accumulator[40+: 8], 
                                 accumulator[24+: 8],accumulator[ 8+: 8]};

wire [31:0]  pmul_result_0_4  = {accumulator[56+: 4],accumulator[48+: 4], 
                                 accumulator[40+: 4],accumulator[32+: 4],
                                 accumulator[24+: 4],accumulator[16+: 4],
                                 accumulator[ 8+: 4],accumulator[ 0+: 4]};
wire [31:0]  pmul_result_1_4  = {accumulator[60+: 4],accumulator[52+: 4], 
                                 accumulator[44+: 4],accumulator[36+: 4],
                                 accumulator[28+: 4],accumulator[20+: 4],
                                 accumulator[12+: 4],accumulator[ 4+: 4]};

wire [31:0]  pmul_result_0_2  = {accumulator[60+: 2],accumulator[56+: 2], 
                                 accumulator[52+: 2],accumulator[48+: 2],
                                 accumulator[44+: 2],accumulator[40+: 2],
                                 accumulator[36+: 2],accumulator[32+: 2],
                                 accumulator[28+: 2],accumulator[24+: 2],
                                 accumulator[20+: 2],accumulator[16+: 2],
                                 accumulator[12+: 2],accumulator[ 8+: 2],
                                 accumulator[ 4+: 2],accumulator[ 0+: 2]};
wire [31:0]  pmul_result_1_2  = {accumulator[62+: 2],accumulator[58+: 2], 
                                 accumulator[54+: 2],accumulator[50+: 2],
                                 accumulator[46+: 2],accumulator[42+: 2],
                                 accumulator[38+: 2],accumulator[34+: 2],
                                 accumulator[30+: 2],accumulator[26+: 2],
                                 accumulator[22+: 2],accumulator[18+: 2],
                                 accumulator[14+: 2],accumulator[10+: 2],
                                 accumulator[ 6+: 2],accumulator[ 2+: 2]};

wire [31:0] pmul_result_0     = {32{pw_16}} & pmul_result_0_16 |
                                {32{pw_8 }} & pmul_result_0_8  |
                                {32{pw_4 }} & pmul_result_0_4  |
                                {32{pw_2 }} & pmul_result_0_2  ;

wire [31:0] pmul_result_1     = {32{pw_16}} & pmul_result_1_16 |
                                {32{pw_8 }} & pmul_result_1_8  |
                                {32{pw_4 }} & pmul_result_1_4  |
                                {32{pw_2 }} & pmul_result_1_2  ;


wire [31:0] adder_lhs   = {32{insn_mul  }} &  mul_padd_lhs  |
                          {32{insn_pmul }} & pmul_padd_lhs  |
                          {32{insn_drem }} & drem_padd_lhs  ;

wire [31:0] adder_rhs   = {32{insn_mul  }} &  mul_padd_rhs  |
                          {32{insn_pmul }} & pmul_padd_rhs  |
                          {32{insn_drem }} & drem_padd_rhs  ;

wire        adder_cin   =     insn_mul    &&  mul_padd_sub  ||
                              insn_pmul   && pmul_padd_sub  ||
                              insn_drem   && drem_padd_sub  ;

wire        adder_c_en  = !carryless;

wire [31:0] adder_cout  ;
wire [31:0] adder_result;

//
// State
// ----------------------------------------------------------------------

reg  [ 5:0] counter         ;
reg         carry           ;
reg  [63:0] accumulator     ;
reg  [31:0] argument        ;

wire [ 5:0] n_counter       = counter + 1;

wire        n_carry         =     insn_mul   &&  mul_n_carry        |
                                  insn_pmul  && pmul_n_carry        |
                                  insn_drem  && drem_n_carry        ;

wire [63:0] n_accumulator   = {64{insn_mul }} &  mul_n_accumulator  |
                              {64{insn_pmul}} & pmul_n_accumulator  |
                              {64{insn_drem}} & drem_n_accumulator  ;

wire [31:0] n_argument      = {32{insn_mul }} &  mul_n_argument     |
                              {32{insn_pmul}} & pmul_n_argument     |
                              {32{insn_drem}} & drem_n_argument     ;

assign      ready           = insn_mul  &&  mul_finished    ||
                              insn_pmul && pmul_finished    ||
                              insn_drem && drem_finished    ;

assign      {result_1,result_0} = 
    insn_pmul ? {pmul_result_1, pmul_result_0} :
    insn_drem ? {32'b0        , drem_result  } :
                accumulator                    ;

reg         count_en        ;

always @(posedge clock) begin
    if(!resetn || flush) begin
        count_en <= 1'b0;
    end else if(valid && !count_en) begin
        count_en <= 1'b1;
    end
end

always @(posedge clock) begin
    if(!resetn || flush) begin
        counter     <=  6'b0;
        carry       <=  1'b0;
        accumulator <= 64'b0;
        argument    <= 32'b0;
    end else if(valid && !count_en) begin
        accumulator <= insn_div || insn_rem ? n_accumulator : 0     ;
        argument    <= insn_div || insn_rem ? n_argument    : rs2   ;
    end else if(count_en && !ready) begin
        counter     <= n_counter    ;
        carry       <= n_carry      ;
        accumulator <= n_accumulator;
        argument    <= n_argument   ;
    end
end


//
// Submodule instances
// ----------------------------------------------------------------------

// "Normal" multipler
xc_malu_mul i_malu_mul (
.rs1             (rs1               ),
.rs2             (rs2               ),
.counter         (counter           ),
.accumulator     (accumulator       ),
.argument        (argument          ),
.carry           (carry             ),
.lhs_sign        (lhs_sign          ),
.rhs_sign        (rhs_sign          ),
.padd_lhs        (mul_padd_lhs      ), // Left hand input
.padd_rhs        (mul_padd_rhs      ), // Right hand input.
.padd_sub        (mul_padd_sub      ), // Subtract if set, else add.
.padd_carry      (adder_cout        ), // Carry bits
.padd_result     (adder_result      ), // Result of the operation
.n_counter       (n_counter         ),
.n_accumulator   (mul_n_accumulator ),
.n_argument      (mul_n_argument    ),
.n_carry         (mul_n_carry       ),
.finished        (mul_finished      )
);

// Packed Multiplier
xc_malu_pmul i_malu_pmul (
.rs1             (rs1               ),
.rs2             (rs2               ),
.counter         (counter           ),
.accumulator     (accumulator       ),
.argument        (argument          ),
.carry           (carry             ),
.pw              (pw                ),
.lhs_sign        (lhs_sign          ),
.rhs_sign        (rhs_sign          ),
.padd_lhs        (pmul_padd_lhs     ), // Left hand input
.padd_rhs        (pmul_padd_rhs     ), // Right hand input.
.padd_sub        (pmul_padd_sub     ), // Subtract if set, else add.
.padd_carry      (adder_cout        ), // Carry bits
.padd_result     (adder_result      ), // Result of the operation
.n_counter       (n_counter         ),
.n_accumulator   (pmul_n_accumulator),
.n_argument      (pmul_n_argument   ),
.n_carry         (pmul_n_carry      ),
.finished        (pmul_finished     )
);


xc_malu_divrem i_malu_divrem (
.clock          (clock          ),
.resetn         (resetn         ),
.rs1            (rs1            ),
.rs2            (rs2            ),
.valid          (valid          ),
.div            (insn_div       ),
.rem            (insn_rem       ),
.op_unsigned    (drem_unsigned  ),
.flush          (flush          ),
.counter        (counter        ),
.accumulator    (accumulator    ),
.argument       (argument       ),
.carry          (carry          ),
.lhs_sign       (lhs_sign       ),
.rhs_sign       (rhs_sign       ),
.padd_lhs       (drem_padd_lhs        ), // Left hand input
.padd_rhs       (drem_padd_rhs        ), // Right hand input.
.padd_sub       (drem_padd_sub        ), // Subtract if set, else add.
.padd_carry     (adder_cout           ), // Carry bits
.padd_result    (adder_result         ), // Result of the operation
.n_counter      (n_counter            ),
.n_accumulator  (drem_n_accumulator   ),
.n_argument     (drem_n_argument      ),
.n_carry        (drem_n_carry         ),
.finished       (drem_finished        ),
.result         (drem_result          )
);

p_addsub i_adder (
.lhs    (adder_lhs    ), // Left hand input
.rhs    (adder_rhs    ), // Right hand input.
.pw     (pw           ), // Pack width to operate on
.sub    (adder_cin    ), // Subtract if set, else add.
.c_en   (adder_c_en   ), // Enable(set) all carry bits.
.c_out  (adder_cout   ), // Carry bits
.result (adder_result )  // Result of the operation
);

endmodule

//
// --------------------------------------------------------------------------
//


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
input  wire         carry           ,

input  wire         lhs_sign        ,
input  wire         rhs_sign        ,

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.

input       [31:0]  padd_carry      , // Carry bits
input       [31:0]  padd_result     , // Result of the operation

input  wire [ 5:0]  n_counter       ,
output wire [63:0]  n_accumulator   ,
output wire [32:0]  n_argument      ,
output wire         n_carry         ,
output wire         finished        

);

assign finished  = counter == 32;

assign n_carry   = 1'b0;

wire          add_en     = argument[0];

wire          sub_last   = rs2[31] && n_counter == 32 && rhs_sign;

wire [32:0]   add_lhs    = {lhs_sign && accumulator[63], accumulator[63:32]};
wire [32:0]   add_rhs    = add_en ? {lhs_sign && rs1[31], rs1} : 0 ;

assign        padd_lhs   = add_lhs[31:0];
assign        padd_rhs   = add_rhs[31:0];
assign        padd_sub   = sub_last;

wire          add_32     = add_lhs[32] + 
                           add_rhs[32] +
                           sub_last    + padd_carry[31];

wire   [32:0] add_result = {add_32, padd_result};

assign n_accumulator     = {add_result, accumulator[31:1]};

assign n_argument        = {1'b0, argument[31:1]};

endmodule

//
// --------------------------------------------------------------------------
//

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
input  wire         carry           ,

input  wire [ 4:0]  pw              ,
input  wire         lhs_sign        ,
input  wire         rhs_sign        ,

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.

input       [31:0]  padd_carry      , // Carry bits
input       [31:0]  padd_result     , // Result of the operation

input  wire [ 5:0]  n_counter       ,
output wire [63:0]  n_accumulator   ,
output wire [32:0]  n_argument      ,
output wire         n_carry         ,
output wire         finished        

);

//
// One-hot pack width wires
wire pw_16 = pw[1];
wire pw_8  = pw[2];
wire pw_4  = pw[3];
wire pw_2  = pw[4];

wire [5:0] counter_finish = {pw_16,pw_8,pw_4,pw_2,1'b0};

assign n_carry      = 1'b0;
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

//
// --------------------------------------------------------------------------
//

module xc_malu_divrem (

input  wire         clock           ,
input  wire         resetn          ,

input  wire [31:0]  rs1             ,
input  wire [31:0]  rs2             ,

input  wire         valid           ,
input  wire         div             ,
input  wire         rem             ,
input  wire         op_unsigned     ,
input  wire         flush           ,

input  wire [ 5:0]  counter         ,
input  wire [63:0]  accumulator     ,
input  wire [31:0]  argument        ,
input  wire         carry           ,

input  wire         lhs_sign        ,
input  wire         rhs_sign        ,

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.

input  wire [31:0]  padd_carry      , // Carry bits
input  wire [31:0]  padd_result     , // Result of the operation

input  wire [ 5:0]  n_counter       ,
output wire [63:0]  n_accumulator   ,
output wire [32:0]  n_argument      ,
output wire         n_carry         ,
output wire         finished        ,

output wire [31:0]  result

);

wire        i_div       = div && !op_unsigned && valid;
wire        i_divu      = div &&  op_unsigned && valid;
wire        i_rem       = rem && !op_unsigned && valid;
wire        i_remu      = rem &&  op_unsigned && valid;

wire        r_div       = i_div || i_divu;
wire        r_rem       = i_rem || i_remu;

assign      n_carry     = 0;

reg         div_run     ;
reg         div_done    ;

assign      finished = div_done;

wire        is_divrem   = i_div || i_divu || i_rem || i_remu;
wire        signed_lhs  = (i_div || i_rem) && rs1[31];
wire        signed_rhs  = (i_div || i_rem) && rs2[31];

wire        div_start   = is_divrem && !div_run && !div_done;
wire        div_finished= (div_run && counter== 31) || div_done;

reg  [31:0] quotient    ;
reg         outsign     ;

wire [31:0] qmask       = (32'b1<<31  )     >> counter  ;

wire        div_less    = accumulator <= {32'b0,argument};

assign      padd_lhs    = argument;
assign      padd_rhs    = accumulator[31:0];
assign      padd_sub    = 1'b1;

wire [63:0] divisor_start = 
    {(signed_rhs ? -{{32{rs2[31]}},rs2} : {32'b0,rs2}), 31'b0};


assign      n_accumulator = div_start       ? divisor_start :
                            !div_finished   ? accumulator >> 1  :
                                              accumulator ;

assign      n_argument    = div_start       ? (signed_lhs ? -rs1 : rs1) :
                            div_less        ? padd_result               :
                                              argument                  ;

always @(posedge clock) begin
    if(!resetn   || flush) begin
        
        div_done <= 1'b0;
        div_run  <= 1'b0;
        quotient <= 0;
        outsign  <= 1'b0;

    end else if(div_done) begin
        
        div_done <= !flush;

    end else if(div_start) begin
        
        div_run  <= 1'b1;
        div_done <= 1'b0;
        quotient <= 0;
        outsign  <= (i_div && (rs1[31] != rs2[31]) && |rs2) ||
                    (i_rem && rs1[31]);

    end else if(div_run) begin

        if(div_less) begin
        
            quotient <= quotient | qmask  ;

        end

        if(div_finished) begin

            div_run  <= 1'b0;
            div_done <= 1'b1;

        end

    end
end


//
// Result multiplexing
//

wire [31:0] dividend_out = outsign ? -argument : argument;
wire [31:0] quotient_out = outsign ? -quotient : quotient;

`ifdef RISCV_FORMAL_ALTOPS

wire [31:0] mulhsu_fml_result = 
    $signed(rs1) - $signed({1'b0,rs2});

// Alternative computations for riscv-formal framework.
assign result =
    {32{i_div   }} & ((rs1 - rs2) ^ 32'h7f85_29ec ) |
    {32{i_divu  }} & ((rs1 - rs2) ^ 32'h10e8_fd70 ) |
    {32{i_rem   }} & ((rs1 - rs2) ^ 32'h8da6_8fa5 ) |
    {32{i_remu  }} & ((rs1 - rs2) ^ 32'h3138_d0e1 ) ;

`else

assign result =
    {32{r_rem }} & dividend_out         |
    {32{r_div }} & quotient_out         ;

`endif

endmodule

