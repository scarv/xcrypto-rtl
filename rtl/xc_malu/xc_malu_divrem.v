
//
// Handles instructions:
//  - div
//  - divu
//  - rem
//  - remu
//
module xc_malu_divrem (

input  wire         clock           ,
input  wire         resetn          ,

input  wire [31:0]  rs1             ,
input  wire [31:0]  rs2             ,

input  wire         valid           ,
input  wire         op_signed       ,
input  wire         flush           ,

input  wire [ 5:0]  count           ,
input  wire [63:0]  acc             , // Divisor
input  wire [31:0]  arg_0           , // Dividend
input  wire [31:0]  arg_1           , // Quotient

output wire [31:0]  padd_lhs        , // Left hand input
output wire [31:0]  padd_rhs        , // Right hand input.
output wire [ 0:0]  padd_sub        , // Subtract if set, else add.
input  wire [31:0]  padd_cout       , // Carry bits
input  wire [31:0]  padd_result     , // Result of the operation

output wire [63:0]  n_acc           ,
output wire [31:0]  n_arg_0         ,
output wire [31:0]  n_arg_1         ,
output wire         ready           

);

reg         div_run     ;
reg         div_done    ;

assign      ready       = div_done;

wire        signed_lhs  = (op_signed) && rs1[31];
wire        signed_rhs  = (op_signed) && rs2[31];

wire        div_start   = valid     && !div_run && !div_done;
wire        div_finished= (div_run && count == 31) || div_done;

wire [31:0] qmask       = (32'b1<<31  ) >> count  ;

wire        div_less    = acc <= {32'b0,arg_0};

assign      padd_lhs    = arg_0;
assign      padd_rhs    = acc [31:0];
assign      padd_sub    = 1'b1;

wire [63:0] divisor_start = 
    {(signed_rhs ? -{{32{rs2[31]}},rs2} : {32'b0,rs2}), 31'b0};


assign      n_acc       = div_start    ? divisor_start      :
                         !div_finished ? accumulator >> 1   :
                                         accumulator        ;

assign      n_arg_0     = div_start ? (signed_lhs ? -rs1 : rs1) :
                          div_less  ? padd_result               :
                                      arg_0                     ;

assign      n_arg_1     = div_start           ? 0               :
                          div_run && div_less ? arg_1 | qmask   :
                                                arg_1           ;

always @(posedge clock) begin
    if(!resetn   || flush) begin
        
        div_done <= 1'b0;
        div_run  <= 1'b0;

    end else if(div_done) begin
        
        div_done <= !flush;

    end else if(div_start) begin
        
        div_run  <= 1'b1;
        div_done <= 1'b0;

    end else if(div_run) begin

        if(div_finished) begin

            div_run  <= 1'b0;
            div_done <= 1'b1;

        end

    end
end

endmodule
