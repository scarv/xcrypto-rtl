
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
reg         mul_h   ;
reg         clmul   ;
reg  [4:0]  pw      ;

reg  [31:0] crs1    ;
reg  [31:0] crs2    ;

wire [31:0] result  ;

wire        output_valid = valid && ready;
reg  [2:0]  pw_rand ;

integer     clock_ticks  = 0;
parameter   max_ticks    = 100;

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
        crs1    <= 1;
        crs2    <= 4;
        valid   <= $random;
        
        pw      <= 5'b1;

        clmul   <= 1'b0;
        mul_l   <= 1'b1;
        mul_h   <= 1'b0;
    end

    if(clock_ticks > max_ticks) begin
        $finish;
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


endmodule
