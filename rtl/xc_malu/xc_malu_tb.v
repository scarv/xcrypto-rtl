
`define STR(x) `"x`"

`ifndef WAVE_FILE
    `define WAVE_FILE waves.vcd
`endif

//
// module: xc_malu_tb
//
//  Randomised testbech for the xc_malu module.
//  Using a simulation based approach for xc_malu module, since BMC
//  approaches can't handle multiplication.
//
module xc_malu_tb ();

reg          clock           ;
reg          resetn          ;

integer     test_count   = 0;
integer     clock_ticks  = 0;
parameter   max_ticks    = 100000;

// Initial values
initial begin

    $dumpfile(`STR(`WAVE_FILE));
    $dumpvars(0, xc_malu_tb);

    resetn  = 1'b0;
    clock   = 1'b0;

    #40 resetn = 1'b1;
end

// Make the clock tick.
always @(clock) #20 clock <= !clock;

// Count clock ticks so we finish.
always @(posedge clock) begin

    clock_ticks = clock_ticks + 1;

    if(clock_ticks > max_ticks) begin
        $display("%d tests performed.", test_count);
        $finish;
    end

end


endmodule

