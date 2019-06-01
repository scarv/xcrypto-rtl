
//
// module: p_shfrot
//
//  Barrel implementation of the packed shift/rotate instructions.
//
module p_shfrot (

input  [31:0] crs1  , // Source register 1
input  [ 4:0] shamt , // Shift amount (immediate or source register 2)

input  [ 4:0] pw    , // Pack width to operate on

input         shift , // Shift left/right
input         rotate, // Rotate left/right
input         left  , // Shift/roate left
input         right , // Shift/rotate right

output reg [31:0] result  // Operation result

);

wire w_32 = pw[0];
wire w_16 = pw[1];
wire w_8  = pw[2];
wire w_4  = pw[3];
wire w_2  = pw[4];

// 32-bit elements
wire [31:0] w_32_sl = crs1 << shamt;

wire [31:0] w_32_sr = crs1 >> shamt;

wire [31:0] w_32_rl = {crs1,crs1} >> (32-shamt);

wire [31:0] w_32_rr = {crs1,crs1} >> (   shamt);

// 16-bit elements
wire [15:0] w_16_sl_0 = crs1[15: 0] << shamt;
wire [15:0] w_16_sl_1 = crs1[31:16] << shamt;
wire [31:0] w_16_sl   = {w_16_sl_1, w_16_sl_0};

wire [15:0] w_16_sr_0 = crs1[15: 0] >> shamt;
wire [15:0] w_16_sr_1 = crs1[31:16] >> shamt;
wire [31:0] w_16_sr   = {w_16_sr_1, w_16_sr_0};

wire [31:0] w_16_rl_0 = {crs1[15: 0],crs1[15: 0]} >> (32-shamt);
wire [31:0] w_16_rl_1 = {crs1[31:16],crs1[31:16]} >> (32-shamt);
wire [31:0] w_16_rl   = {w_16_rl_1[15:0], w_16_rl_0[15:0]};

wire [31:0] w_16_rr_0 = {crs1[15: 0],crs1[15: 0]} >> (   shamt);
wire [31:0] w_16_rr_1 = {crs1[31:16],crs1[31:16]} >> (   shamt);
wire [31:0] w_16_rr   = {w_16_rr_1[15:0], w_16_rr_0[15:0]};

// 8-bit elements
wire [15:0] w_8_sl_0  = crs1[ 7: 0] << shamt;
wire [15:0] w_8_sl_1  = crs1[15: 8] << shamt;
wire [15:0] w_8_sl_2  = crs1[23:16] << shamt;
wire [15:0] w_8_sl_3  = crs1[31:24] << shamt;
wire [31:0] w_8_sl    = {w_8_sl_3,w_8_sl_2,w_8_sl_1, w_8_sl_0};

wire [15:0] w_8_sr_0  = crs1[ 7: 0] >> shamt;
wire [15:0] w_8_sr_1  = crs1[15: 8] >> shamt;
wire [15:0] w_8_sr_2  = crs1[23:16] >> shamt;
wire [15:0] w_8_sr_3  = crs1[31:24] >> shamt;
wire [31:0] w_8_sr    = {w_8_sr_3,w_8_sr_2,w_8_sr_1, w_8_sr_0};

wire [15:0] w_8_rl_0  = {crs1[ 7: 0],crs1[ 7: 0]} >> (32-shamt);
wire [15:0] w_8_rl_1  = {crs1[15: 8],crs1[15: 8]} >> (32-shamt);
wire [15:0] w_8_rl_2  = {crs1[23:16],crs1[23:16]} >> (32-shamt);
wire [15:0] w_8_rl_3  = {crs1[31:24],crs1[31:24]} >> (32-shamt);
wire [31:0] w_8_rl    = {w_8_rl_3[ 7:0], w_8_rl_2[ 7:0],
                         w_8_rl_1[ 7:0], w_8_rl_0[ 7:0]};

wire [15:0] w_8_rr_0  = {crs1[ 7: 0],crs1[ 7: 0]} >> (   shamt);
wire [15:0] w_8_rr_1  = {crs1[15: 8],crs1[15: 8]} >> (   shamt);
wire [15:0] w_8_rr_2  = {crs1[23:16],crs1[23:16]} >> (   shamt);
wire [15:0] w_8_rr_3  = {crs1[31:24],crs1[31:24]} >> (   shamt);
wire [31:0] w_8_rr    = {w_8_rr_3[ 7:0], w_8_rr_2[ 7:0],
                         w_8_rr_1[ 7:0], w_8_rr_0[ 7:0]};

// 4-bit elements
wire [ 3:0] w_4_sl_0  = crs1[ 3: 0] << shamt;
wire [ 3:0] w_4_sl_1  = crs1[ 7: 4] << shamt;
wire [ 3:0] w_4_sl_2  = crs1[11: 8] << shamt;
wire [ 3:0] w_4_sl_3  = crs1[15:12] << shamt;
wire [ 3:0] w_4_sl_4  = crs1[19:16] << shamt;
wire [ 3:0] w_4_sl_5  = crs1[23:20] << shamt;
wire [ 3:0] w_4_sl_6  = crs1[27:24] << shamt;
wire [ 3:0] w_4_sl_7  = crs1[31:28] << shamt;
wire [31:0] w_4_sl    = {w_4_sl_7,w_4_sl_6,w_4_sl_5, w_4_sl_4,
                         w_4_sl_3,w_4_sl_2,w_4_sl_1, w_4_sl_0};

wire [ 3:0] w_4_sr_0  = crs1[ 3: 0] >> shamt;
wire [ 3:0] w_4_sr_1  = crs1[ 7: 4] >> shamt;
wire [ 3:0] w_4_sr_2  = crs1[11: 8] >> shamt;
wire [ 3:0] w_4_sr_3  = crs1[15:12] >> shamt;
wire [ 3:0] w_4_sr_4  = crs1[19:16] >> shamt;
wire [ 3:0] w_4_sr_5  = crs1[23:20] >> shamt;
wire [ 3:0] w_4_sr_6  = crs1[27:24] >> shamt;
wire [ 3:0] w_4_sr_7  = crs1[31:28] >> shamt;
wire [31:0] w_4_sr    = {w_4_sr_7,w_4_sr_6,w_4_sr_5, w_4_sr_4,
                         w_4_sr_3,w_4_sr_2,w_4_sr_1, w_4_sr_0};

wire [15:0] w_4_rl_0  = {crs1[ 3: 0],crs1[ 3: 0]} >> (32-shamt);
wire [15:0] w_4_rl_1  = {crs1[ 7: 4],crs1[ 7: 4]} >> (32-shamt);
wire [15:0] w_4_rl_2  = {crs1[11: 8],crs1[11: 8]} >> (32-shamt);
wire [15:0] w_4_rl_3  = {crs1[15:12],crs1[15:12]} >> (32-shamt);
wire [15:0] w_4_rl_4  = {crs1[19:16],crs1[19:16]} >> (32-shamt);
wire [15:0] w_4_rl_5  = {crs1[23:20],crs1[23:20]} >> (32-shamt);
wire [15:0] w_4_rl_6  = {crs1[27:24],crs1[27:24]} >> (32-shamt);
wire [15:0] w_4_rl_7  = {crs1[31:28],crs1[31:28]} >> (32-shamt);
wire [31:0] w_4_rl    = {w_4_rl_7[ 3:0], w_4_rl_6[ 3:0],
                         w_4_rl_5[ 3:0], w_4_rl_4[ 3:0],
                         w_4_rl_3[ 3:0], w_4_rl_2[ 3:0],
                         w_4_rl_1[ 3:0], w_4_rl_0[ 3:0]};

wire [15:0] w_4_rr_0  = {crs1[ 3: 0],crs1[ 3: 0]} >> (   shamt);
wire [15:0] w_4_rr_1  = {crs1[ 7: 4],crs1[ 7: 4]} >> (   shamt);
wire [15:0] w_4_rr_2  = {crs1[11: 8],crs1[11: 8]} >> (   shamt);
wire [15:0] w_4_rr_3  = {crs1[15:12],crs1[15:12]} >> (   shamt);
wire [15:0] w_4_rr_4  = {crs1[19:16],crs1[19:16]} >> (   shamt);
wire [15:0] w_4_rr_5  = {crs1[23:20],crs1[23:20]} >> (   shamt);
wire [15:0] w_4_rr_6  = {crs1[27:24],crs1[27:24]} >> (   shamt);
wire [15:0] w_4_rr_7  = {crs1[31:28],crs1[31:28]} >> (   shamt);
wire [31:0] w_4_rr    = {w_4_rr_7[ 3:0], w_4_rr_6[ 3:0],
                         w_4_rr_5[ 3:0], w_4_rr_4[ 3:0],
                         w_4_rr_3[ 3:0], w_4_rr_2[ 3:0],
                         w_4_rr_1[ 3:0], w_4_rr_0[ 3:0]};

// 2-bit elements
wire [ 1:0] w_2_sl_0  = crs1[ 1: 0] << shamt;
wire [ 1:0] w_2_sl_1  = crs1[ 3: 2] << shamt;
wire [ 1:0] w_2_sl_2  = crs1[ 5: 4] << shamt;
wire [ 1:0] w_2_sl_3  = crs1[ 7: 6] << shamt;
wire [ 1:0] w_2_sl_4  = crs1[ 9: 8] << shamt;
wire [ 1:0] w_2_sl_5  = crs1[11:10] << shamt;
wire [ 1:0] w_2_sl_6  = crs1[13:12] << shamt;
wire [ 1:0] w_2_sl_7  = crs1[15:14] << shamt;
wire [ 1:0] w_2_sl_8  = crs1[17:16] << shamt;
wire [ 1:0] w_2_sl_9  = crs1[19:18] << shamt;
wire [ 1:0] w_2_sl_10 = crs1[21:20] << shamt;
wire [ 1:0] w_2_sl_11 = crs1[23:22] << shamt;
wire [ 1:0] w_2_sl_12 = crs1[25:24] << shamt;
wire [ 1:0] w_2_sl_13 = crs1[27:26] << shamt;
wire [ 1:0] w_2_sl_14 = crs1[29:28] << shamt;
wire [ 1:0] w_2_sl_15 = crs1[31:30] << shamt;
wire [31:0] w_2_sl    = {w_2_sl_15,w_2_sl_14,w_2_sl_13, w_2_sl_12,
                         w_2_sl_11,w_2_sl_10,w_2_sl_9 , w_2_sl_8 ,
                         w_2_sl_7 ,w_2_sl_6 ,w_2_sl_5 , w_2_sl_4 ,
                         w_2_sl_3 ,w_2_sl_2 ,w_2_sl_1 , w_2_sl_0 };

wire [ 1:0] w_2_sr_0  = crs1[ 1: 0] >> shamt;
wire [ 1:0] w_2_sr_1  = crs1[ 3: 2] >> shamt;
wire [ 1:0] w_2_sr_2  = crs1[ 5: 4] >> shamt;
wire [ 1:0] w_2_sr_3  = crs1[ 7: 6] >> shamt;
wire [ 1:0] w_2_sr_4  = crs1[ 9: 8] >> shamt;
wire [ 1:0] w_2_sr_5  = crs1[11:10] >> shamt;
wire [ 1:0] w_2_sr_6  = crs1[13:12] >> shamt;
wire [ 1:0] w_2_sr_7  = crs1[15:14] >> shamt;
wire [ 1:0] w_2_sr_8  = crs1[17:16] >> shamt;
wire [ 1:0] w_2_sr_9  = crs1[19:18] >> shamt;
wire [ 1:0] w_2_sr_10 = crs1[21:20] >> shamt;
wire [ 1:0] w_2_sr_11 = crs1[23:22] >> shamt;
wire [ 1:0] w_2_sr_12 = crs1[25:24] >> shamt;
wire [ 1:0] w_2_sr_13 = crs1[27:26] >> shamt;
wire [ 1:0] w_2_sr_14 = crs1[29:28] >> shamt;
wire [ 1:0] w_2_sr_15 = crs1[31:30] >> shamt;
wire [31:0] w_2_sr    = {w_2_sr_15,w_2_sr_14,w_2_sr_13, w_2_sr_12,
                         w_2_sr_11,w_2_sr_10,w_2_sr_9 , w_2_sr_8 ,
                         w_2_sr_7 ,w_2_sr_6 ,w_2_sr_5 , w_2_sr_4 ,
                         w_2_sr_3 ,w_2_sr_2 ,w_2_sr_1 , w_2_sr_0 };

wire [ 3:0] w_2_rl_0  = {crs1[ 1: 0],crs1[ 1: 0]} >> {32-shamt};
wire [ 3:0] w_2_rl_1  = {crs1[ 3: 2],crs1[ 3: 2]} >> {32-shamt};
wire [ 3:0] w_2_rl_2  = {crs1[ 5: 4],crs1[ 5: 4]} >> {32-shamt};
wire [ 3:0] w_2_rl_3  = {crs1[ 7: 6],crs1[ 7: 6]} >> {32-shamt};
wire [ 3:0] w_2_rl_4  = {crs1[ 9: 8],crs1[ 9: 8]} >> {32-shamt};
wire [ 3:0] w_2_rl_5  = {crs1[11:10],crs1[11:10]} >> {32-shamt};
wire [ 3:0] w_2_rl_6  = {crs1[13:12],crs1[13:12]} >> {32-shamt};
wire [ 3:0] w_2_rl_7  = {crs1[15:14],crs1[15:14]} >> {32-shamt};
wire [ 3:0] w_2_rl_8  = {crs1[17:16],crs1[17:16]} >> {32-shamt};
wire [ 3:0] w_2_rl_9  = {crs1[19:18],crs1[19:18]} >> {32-shamt};
wire [ 3:0] w_2_rl_10 = {crs1[21:20],crs1[21:20]} >> {32-shamt};
wire [ 3:0] w_2_rl_11 = {crs1[23:22],crs1[23:22]} >> {32-shamt};
wire [ 3:0] w_2_rl_12 = {crs1[25:24],crs1[25:24]} >> {32-shamt};
wire [ 3:0] w_2_rl_13 = {crs1[27:26],crs1[27:26]} >> {32-shamt};
wire [ 3:0] w_2_rl_14 = {crs1[29:28],crs1[29:28]} >> {32-shamt};
wire [ 3:0] w_2_rl_15 = {crs1[31:30],crs1[31:30]} >> {32-shamt};
wire [31:0] w_2_rl    = {w_2_rl_15,w_2_rl_14,w_2_rl_13, w_2_rl_12,
                         w_2_rl_11,w_2_rl_10,w_2_rl_9 , w_2_rl_8 ,
                         w_2_rl_7 ,w_2_rl_6 ,w_2_rl_5 , w_2_rl_4 ,
                         w_2_rl_3 ,w_2_rl_2 ,w_2_rl_1 , w_2_rl_0 };

wire [ 3:0] w_2_rr_0  = {crs1[ 1: 0],crs1[ 1: 0]} >> {   shamt};
wire [ 3:0] w_2_rr_1  = {crs1[ 3: 2],crs1[ 3: 2]} >> {   shamt};
wire [ 3:0] w_2_rr_2  = {crs1[ 5: 4],crs1[ 5: 4]} >> {   shamt};
wire [ 3:0] w_2_rr_3  = {crs1[ 7: 6],crs1[ 7: 6]} >> {   shamt};
wire [ 3:0] w_2_rr_4  = {crs1[ 9: 8],crs1[ 9: 8]} >> {   shamt};
wire [ 3:0] w_2_rr_5  = {crs1[11:10],crs1[11:10]} >> {   shamt};
wire [ 3:0] w_2_rr_6  = {crs1[13:12],crs1[13:12]} >> {   shamt};
wire [ 3:0] w_2_rr_7  = {crs1[15:14],crs1[15:14]} >> {   shamt};
wire [ 3:0] w_2_rr_8  = {crs1[17:16],crs1[17:16]} >> {   shamt};
wire [ 3:0] w_2_rr_9  = {crs1[19:18],crs1[19:18]} >> {   shamt};
wire [ 3:0] w_2_rr_10 = {crs1[21:20],crs1[21:20]} >> {   shamt};
wire [ 3:0] w_2_rr_11 = {crs1[23:22],crs1[23:22]} >> {   shamt};
wire [ 3:0] w_2_rr_12 = {crs1[25:24],crs1[25:24]} >> {   shamt};
wire [ 3:0] w_2_rr_13 = {crs1[27:26],crs1[27:26]} >> {   shamt};
wire [ 3:0] w_2_rr_14 = {crs1[29:28],crs1[29:28]} >> {   shamt};
wire [ 3:0] w_2_rr_15 = {crs1[31:30],crs1[31:30]} >> {   shamt};
wire [31:0] w_2_rr    = {w_2_rr_15,w_2_rr_14,w_2_rr_13, w_2_rr_12,
                         w_2_rr_11,w_2_rr_10,w_2_rr_9 , w_2_rr_8 ,
                         w_2_rr_7 ,w_2_rr_6 ,w_2_rr_5 , w_2_rr_4 ,
                         w_2_rr_3 ,w_2_rr_2 ,w_2_rr_1 , w_2_rr_0 };

always @(*) begin

    result = 0;

    if(w_32) begin
        if(shift) begin
            if(left) begin
                result = w_32_sl;
            end else if(right) begin
                result = w_32_sr;
            end
        end else if(rotate) begin
            if(left) begin
                result = w_32_rl;
            end else if(right) begin
                result = w_32_rr;
            end
        end
    end
    
    if(w_16) begin
        if(shift) begin
            if(left) begin
                result = w_16_sl;
            end else if(right) begin
                result = w_16_sr;
            end
        end else if(rotate) begin
            if(left) begin
                result = w_16_rl;
            end else if(right) begin
                result = w_16_rr;
            end
        end
    end
    
    if(w_8) begin
        if(shift) begin
            if(left) begin
                result = w_8_sl;
            end else if(right) begin
                result = w_8_sr;
            end
        end else if(rotate) begin
            if(left) begin
                result = w_8_rl;
            end else if(right) begin
                result = w_8_rr;
            end
        end
    end
    
    if(w_4) begin
        if(shift) begin
            if(left) begin
                result = w_4_sl;
            end else if(right) begin
                result = w_4_sr;
            end
        end else if(rotate) begin
            if(left) begin
                result = w_4_rl;
            end else if(right) begin
                result = w_4_rr;
            end
        end
    end
    
    if(w_2) begin
        if(shift) begin
            if(left) begin
                result = w_2_sl;
            end else if(right) begin
                result = w_2_sr;
            end
        end else if(rotate) begin
            if(left) begin
                result = w_2_rl;
            end else if(right) begin
                result = w_2_rr;
            end
        end
    end

end

endmodule
