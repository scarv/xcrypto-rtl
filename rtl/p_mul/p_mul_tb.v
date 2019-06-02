
`define STR(x) `"x`"

`ifndef WAVE_FILE
    `define WAVE_FILE waves.vcd
`endif

//
// module: p_mul_tb
//
//  Randomised testbech for the p_mul module.
//  Using a simulation based approach for p_mul module, since BMC
//  approaches can't handle multiplication.
//
module p_mul_tb ();

reg         clock   ;
reg         resetn  ;

reg         valid   ;
wire        ready   ;

reg         mul_l   ;
wire        mul_h   = !mul_l;
reg         clmul   ;
reg  [4:0]  pw      ;

reg  [31:0] crs1    ;
reg  [31:0] crs2    ;

wire [31:0] result  ;
wire [31:0] expectation;

wire        output_valid = valid && ready;
reg  [2:0]  pw_rand ;

integer     clock_ticks  = 0;
parameter   max_ticks    = 10000;

// Initial values
initial begin

    $dumpfile(`STR(`WAVE_FILE));
    $dumpvars(0, p_mul_tb);


    resetn  = 1'b0;
    clock   = 1'b0;
    valid   = 1'b0;

    #40 resetn = 1'b1;
end

// Make the clock tick.
always @(clock) #20 clock <= !clock;

// Input stimulus generation
always @(posedge clock) begin

    clock_ticks = clock_ticks + 1;

    // Randomise inputs.
    if(!valid || (valid && ready)) begin
        crs1    <= ($random & 32'hFFFF_FFFF);
        crs2    <= ($random & 32'hFFFF_FFFF);
        valid   <= $random;
        
        pw      <= 5'b1;

        clmul   <= 1'b0;
        mul_l   <= $random;
    end

    if(clock_ticks > max_ticks) begin
        $finish;
    end

end

//
// Results checking
always @(posedge clock) begin

    if(valid && ready) begin

        if(result != expectation) begin

            $display("pw=%b, crs1=%d, crs2=%d",pw,crs1,crs2);
            $display("clmul=%d, mul_l=%d, mul_h=%d",clmul,mul_l,mul_h);
            $display("Expected: %h %d %b",expectation,expectation,expectation);
            $display("Got     : %h %d %b",result,result,result);

            #20 $finish();

        end

    end

end


//
// DUT instantiation.
p_mul i_dut(
.clock (clock ),
.resetn(resetn),
.valid (valid ),
.ready (ready ),
.mul_l (mul_l ),
.mul_h (mul_h ),
.clmul (clmul ),
.pw    (pw    ),
.crs1  (crs1  ),
.crs2  (crs2  ),
.result(result)
);


//
// Checker instantiation.
p_mul_checker i_p_mul_checker (
.mul_l (mul_l       ),
.mul_h (mul_h       ),
.clmul (clmul       ),
.pw    (pw          ),
.crs1  (crs1        ),
.crs2  (crs2        ),
.result(expectation )
);

endmodule

//
// module: p_mul_checker
//
//  Results checker for the pmul module.
//
module p_mul_checker (

input           mul_l   ,
input           mul_h   ,
input           clmul   ,
input  [4:0]    pw      ,

input  [31:0]   crs1    ,
input  [31:0]   crs2    ,

output [31:0]   result

);

//
// One-hot pack width wires
wire pw_32 = pw[0];
wire pw_16 = pw[1];
wire pw_8  = pw[2];
wire pw_4  = pw[3];
wire pw_2  = pw[4];

// Accumulator Register.
reg [63:0] acc;

assign result =
    mul_l   ? acc[31: 0]    :
    mul_h   ? acc[63:32]    :
              0             ;

always @(*) begin

    acc = 0;

    if(pw_32) begin

        if(clmul) begin

        end else begin

            acc = crs1 * crs2;

        end

    end

end


endmodule

