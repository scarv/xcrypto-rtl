
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
module xc_malu (

input  wire         clock           ,
input  wire         resetn          ,

input  wire [31:0]  rs1             , //
input  wire [31:0]  rs2             , //
input  wire [31:0]  rs3             , //

input  wire         flush           , // Flush state / pipeline progress
input  wire         valid           , // Inputs valid.

input  wire         uop_div         , //
input  wire         uop_divu        , //
input  wire         uop_rem         , //
input  wire         uop_remu        , //
input  wire         uop_mul         , //
input  wire         uop_mulu        , //
input  wire         uop_mulsu       , //
input  wire         uop_clmul       , //
input  wire         uop_pmul        , //
input  wire         uop_pclmul      , //
input  wire         uop_madd        , //
input  wire         uop_msub        , //
input  wire         uop_macc        , //
input  wire         uop_mmul        , //

input  wire         pw_32           , // 32-bit width packed elements.
input  wire         pw_16           , // 16-bit width packed elements.
input  wire         pw_8            , //  8-bit width packed elements.
input  wire         pw_4            , //  4-bit width packed elements.
input  wire         pw_2            , //  2-bit width packed elements.

output wire [63:0]  result          , // 64-bit result
output wire         ready             // Outputs ready.

);


//
// Submodule interface wires
// -----------------------------------------------------------------

wire         insn_divrem    =
    uop_do_div    || uop_do_divu   || uop_do_rem    || uop_do_remu    ;

wire         insn_mdr        =
    insn_divrem   ||
    uop_do_mul    || uop_do_mulu   || uop_do_mulsu  || uop_do_clmul  ||
    uop_do_pmul   || uop_do_pclmul ; 

wire         do_div          = uop_do_div   ; //
wire         do_divu         = uop_do_divu  ; //
wire         do_rem          = uop_do_rem   ; //
wire         do_remu         = uop_do_remu  ; //
wire         do_mul          = uop_do_mul   ; //
wire         do_mulu         = uop_do_mulu  ; //
wire         do_mulsu        = uop_do_mulsu ; //
wire         do_clmul        = uop_do_clmul ; //
wire         do_pmul         = uop_do_pmul  ; //
wire         do_pclmul       = uop_do_pclmul; //

wire [63:0]  mdr_n_acc       ; // Next accumulator value
wire [31:0]  mdr_n_arg_0     ; // Next arg 0 value
wire [31:0]  mdr_n_arg_1     ; // Next arg 1 value
wire [31:0]  mdr_padd_lhs    ; // Packed adder left input
wire [31:0]  mdr_padd_rhs    ; // Packed adder right input
wire         mdr_padd_sub    ; // Packed adder subtract?
wire         mdr_padd_cin    ; // Packed adder carry in
wire         mdr_padd_cen    ; // Packed adder carry enable.
wire [63:0]  mdr_result      ; // 64-bit result
wire         mdr_ready       ; // Outputs ready.

//
// Result Multiplexing
// -----------------------------------------------------------------

assign       result  = {64{insn_mdr}} & mdr_result;

//
// Packed Adder Interface
// -----------------------------------------------------------------

wire [31:0] padd_lhs = {32{insn_mdr}} & mdr_padd_lhs;
                       
wire [31:0] padd_rhs = {32{insn_mdr}} & mdr_padd_rhs;
                       
wire        padd_sub =     insn_mdr  && mdr_padd_sub;
                       
wire        padd_cin =     insn_mdr  && mdr_padd_cin;
                      
wire        padd_cen =     insn_mdr  && mdr_padd_cen;

wire [ 4:0] padd_pw  = {pw_2, pw_4, pw_8, pw_16, pw_32};

wire [31:0] padd_cout   ;
wire [31:0] padd_result ;

//
// Control FSM
// -----------------------------------------------------------------

reg [5:0] fsm;
reg [5:0] n_fsm;

localparam FSM_INIT = 0;
localparam FSM_MDR  = 1;

wire fsm_init = fsm == FSM_INIT;
wire fsm_mdr  = fsm == FSM_MDR ;

always @(*) begin case(fsm)

FSM_INIT: begin
    if(valid && insn_mdr) n_fsm <= FSM_MDR   ;
    else                  n_fsm <= FSM_INIT  ;
end

FSM_MDR: begin
    if(mdr_ready) n_fsm <= FSM_INIT ;
    else          n_fsm <= FSM_MDR  ;
end



endcase end

always @(posedge clock) begin
    if(!resetn || flush) begin
        fsm <= FSM_INIT;
    end else begin
        fsm <= n_fsm;
    end
end

//
// Register State
// -----------------------------------------------------------------

reg  [ 5:0] count    ;   // State / step counter.
wire [ 5:0] n_count  = count + 1;
wire        count_en = fsm_mdr;

reg  [63:0] acc         ; // Accumulator

wire [63:0] n_acc    = {64{insn_mdr}} & mdr_n_acc   ;
                     
reg  [31:0] arg0        ; // Misc intermediate variable

wire [31:0] n_arg0   = {32{insn_mdr}} & mdr_n_arg_0 ;
                     
reg  [31:0] arg1        ; // Misc intermediate variable

wire [31:0] n_arg1   = {32{insn_mdr}} & mdr_n_arg_1 ;

reg         carry       ;
wire        n_carry  = 0;

always @(posedge clock) begin
    if(!resetn || flush) begin
        count <= 0;
        acc   <= 0;
        arg0  <= 0;
        arg1  <= 0;
        carry <= 0;
    end else if(fsm_init && valid) begin
        acc   <= insn_divrem ? n_acc  : 0     ;
        arg0  <= insn_divrem ? n_arg0 : rs2   ;
    end else if(count_en && !ready) begin
        count <= n_count;
        acc   <= n_acc  ;
        arg0  <= n_arg0 ;
        arg1  <= n_arg1 ;
        carry <= n_carry;
    end
end

//
// Are we finished yet?
// -----------------------------------------------------------------

assign ready = insn_mdr && mdr_ready;

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

xc_malu_muldivrem i_malu_muldivrem (
.clock      (clock          ),
.resetn     (resetn         ),
.rs1        (rs1            ), //
.rs2        (rs2            ), //
.rs3        (rs3            ), //
.flush      (flush          ), // Flush state / pipeline progress
.valid      (valid          ), // Inputs valid.
.do_div     (do_div         ), //
.do_divu    (do_divu        ), //
.do_rem     (do_rem         ), //
.do_remu    (do_remu        ), //
.do_mul     (do_mul         ), //
.do_mulu    (do_mulu        ), //
.do_mulsu   (do_mulsu       ), //
.do_clmul   (do_clmul       ), //
.do_pmul    (do_pmul        ), //
.do_pclmul  (do_pclmul      ), //
.pw_32      (pw_32          ), // 32-bit width packed elements.
.pw_16      (pw_16          ), // 16-bit width packed elements.
.pw_8       (pw_8           ), //  8-bit width packed elements.
.pw_4       (pw_4           ), //  4-bit width packed elements.
.pw_2       (pw_2           ), //  2-bit width packed elements.
.count      (count          ), // Current count value
.acc        (acc            ), // Current accumulator value
.arg_0      (arg_0          ), // Current arg 0 value
.arg_1      (arg_1          ), // Current arg 1 value
.n_acc      (mdr_n_acc      ), // Next accumulator value
.n_arg_0    (mdr_n_arg_0    ), // Next arg 0 value
.n_arg_1    (mdr_n_arg_1    ), // Next arg 1 value
.padd_lhs   (mdr_padd_lhs   ), // Packed adder left input
.padd_rhs   (mdr_padd_rhs   ), // Packed adder right input
.padd_sub   (mdr_padd_sub   ), // Packed adder subtract?
.padd_cin   (mdr_padd_cin   ), // Packed adder carry in
.padd_cen   (mdr_padd_cen   ), // Packed adder carry enable.
.padd_cout  (padd_cout      ),
.padd_result(padd_result    ),
.result     (mdr_result     ), // 64-bit result
.ready      (mdr_ready      )  // Outputs ready.
);


endmodule

