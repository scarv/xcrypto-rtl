
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

always @(posedge clock) begin
    pw_rand <= $unsigned($random) % 5;
end

integer     clock_ticks  = 0;
parameter   max_ticks    = 10000;

// Initial values
initial begin

    $dumpfile(`STR(`WAVE_FILE));
    $dumpvars(0, p_mul_tb);

    pw_rand = 0;
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
        crs1    <= 32'h10; //($random & 32'hFFFF_FFFF);
        crs2    <= 32'h10; //($random & 32'hFFFF_FFFF);
        valid   <= $random;
        
        if(pw_rand == 0) begin
            pw      <= 5'b00001;
        end else if(pw_rand == 1) begin
            pw      <= 5'b00010;
        end else if(pw_rand == 2) begin
            pw      <= 5'b00100;
        end else if(pw_rand == 3) begin
            pw      <= 5'b01000;
        end else if(pw_rand == 4) begin
            pw      <= 5'b10000;
        end

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

wire [31:0] psum_16_1 = crs1[31:16] * crs2[31:16];
wire [31:0] psum_16_0 = crs1[15: 0] * crs2[15: 0];

wire [15:0] psum_8_3  = crs1[31:24] * crs2[31:24];
wire [15:0] psum_8_2  = crs1[23:16] * crs2[23:16];
wire [15:0] psum_8_1  = crs1[15: 8] * crs2[15: 8];
wire [15:0] psum_8_0  = crs1[ 7: 0] * crs2[ 7: 0];

wire [ 7:0] psum_4_7  = crs1[31:28] * crs2[31:28];
wire [ 7:0] psum_4_6  = crs1[27:24] * crs2[27:24];
wire [ 7:0] psum_4_5  = crs1[23:20] * crs2[23:20];
wire [ 7:0] psum_4_4  = crs1[19:16] * crs2[19:16];
wire [ 7:0] psum_4_3  = crs1[15:12] * crs2[15:12];
wire [ 7:0] psum_4_2  = crs1[11: 8] * crs2[11: 8];
wire [ 7:0] psum_4_1  = crs1[ 7: 4] * crs2[ 7: 4];
wire [ 7:0] psum_4_0  = crs1[ 3: 0] * crs2[ 3: 0];

wire [ 3:0] psum_2_15 = crs1[31:30] * crs2[31:30];
wire [ 3:0] psum_2_14 = crs1[29:28] * crs2[29:28];
wire [ 3:0] psum_2_13 = crs1[27:26] * crs2[27:26];
wire [ 3:0] psum_2_12 = crs1[25:24] * crs2[25:24];
wire [ 3:0] psum_2_11 = crs1[23:22] * crs2[23:22];
wire [ 3:0] psum_2_10 = crs1[21:20] * crs2[21:20];
wire [ 3:0] psum_2_9  = crs1[19:18] * crs2[19:18];
wire [ 3:0] psum_2_8  = crs1[17:16] * crs2[17:16];
wire [ 3:0] psum_2_7  = crs1[15:14] * crs2[15:14];
wire [ 3:0] psum_2_6  = crs1[13:12] * crs2[13:12];
wire [ 3:0] psum_2_5  = crs1[11:10] * crs2[11:10];
wire [ 3:0] psum_2_4  = crs1[ 9: 8] * crs2[ 9: 8];
wire [ 3:0] psum_2_3  = crs1[ 7: 6] * crs2[ 7: 6];
wire [ 3:0] psum_2_2  = crs1[ 5: 4] * crs2[ 5: 4];
wire [ 3:0] psum_2_1  = crs1[ 3: 2] * crs2[ 3: 2];
wire [ 3:0] psum_2_0  = crs1[ 1: 0] * crs2[ 1: 0];

always @(*) begin

    acc = 0;

    if(pw_32) begin

        if(clmul) begin

        end else begin

            acc = crs1 * crs2;

        end

    end
    
    if(pw_16) begin

        if(clmul) begin

        end else begin

            acc = {psum_16_1[31:16], psum_16_0[31:16], 
                   psum_16_1[15: 0], psum_16_0[15: 0]};

        end

    end
    
    if(pw_8) begin

        if(clmul) begin

        end else begin

            acc = {
                psum_8_3[15:8],psum_8_2[15:8],psum_8_1[15:8],psum_8_0[15:8],
                psum_8_3[ 7:0],psum_8_2[ 7:0],psum_8_1[ 7:0],psum_8_0[ 7:0]
            };

        end

    end
    
    if(pw_4) begin

        if(clmul) begin

        end else begin

            acc = {
                psum_4_7[7:4],psum_4_6[7:4],psum_4_5[7:4],psum_4_4[7:4],
                psum_4_3[7:4],psum_4_2[7:4],psum_4_1[7:4],psum_4_0[7:4],
                psum_4_7[3:0],psum_4_6[3:0],psum_4_5[3:0],psum_4_4[3:0],
                psum_4_3[3:0],psum_4_2[3:0],psum_4_1[3:0],psum_4_0[3:0]
            };

        end

    end
    
    if(pw_2) begin

        if(clmul) begin

        end else begin

            acc = {
                psum_2_15[3:2],psum_2_14[3:2],psum_2_13[3:2],psum_2_12[3:2],
                psum_2_11[3:2],psum_2_10[3:2],psum_2_9 [3:2],psum_2_8 [3:2],
                psum_2_7 [3:2],psum_2_6 [3:2],psum_2_5 [3:2],psum_2_4 [3:2],
                psum_2_3 [3:2],psum_2_2 [3:2],psum_2_1 [3:2],psum_2_0 [3:2],
                psum_2_15[1:0],psum_2_14[1:0],psum_2_13[1:0],psum_2_12[1:0],
                psum_2_11[1:0],psum_2_10[1:0],psum_2_9 [1:0],psum_2_8 [1:0],
                psum_2_7 [1:0],psum_2_6 [1:0],psum_2_5 [1:0],psum_2_4 [1:0],
                psum_2_3 [1:0],psum_2_2 [1:0],psum_2_1 [1:0],psum_2_0 [1:0]
            };

        end

    end

end


endmodule

