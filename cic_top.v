`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// N-th order CIC decimator, decimation R, differential delay M.
// Two's-complement wrap-around integrators, register width from Hogenauer:
//     BW = N*log2(R*M) + BIN
// R*M must be a power of two (gain = (R*M)^N is then a pure shift).
// Output is rounded, scaled and saturated to BOUT bits.
// -----------------------------------------------------------------------------
module cic_top #(
    parameter N         = 4,
    parameter R         = 2048,
    parameter M         = 1,
    parameter BIN       = 2,     // input width (signed)
    parameter BOUT      = 20,    // output width (max 20)
    parameter GAIN_BITS = 1      // extra left-shift of output if signal is small
)(
    input  wire                     clk,
    input  wire                     reset,    // synchronous, active high
    input  wire                     enable,
    input  wire signed [BIN-1:0]    din,
    output reg  signed [BOUT-1:0]   dout,
    output reg                      outready  // 1-clk pulse when dout is new
);

    localparam LOGRM = $clog2(R*M);
    localparam BW    = N*LOGRM + BIN;               // Hogenauer bound
    localparam SHIFT = N*LOGRM - (BOUT-1) - GAIN_BITS;
    localparam CW    = (R > 1) ? $clog2(R) : 1;

    // ------------------------------------------------------------------ integrators
    reg signed [BW-1:0] integ [0:N-1];
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < N; i = i + 1) integ[i] <= {BW{1'b0}};
        end else if (enable) begin
            integ[0] <= integ[0] + din;                       // din sign-extended
            for (i = 1; i < N; i = i + 1)
                integ[i] <= integ[i] + integ[i-1];
        end
    end

    // ------------------------------------------------------------------ downsampler
    reg  [CW-1:0]        cnt;
    reg  signed [BW-1:0] samp;
    reg  [N:0]           stb;            // strobe pipeline, one bit per comb stage
    wire                 take = enable && (cnt == R-1);

    always @(posedge clk) begin
        if (reset) begin
            cnt  <= {CW{1'b0}};
            samp <= {BW{1'b0}};
            stb  <= {(N+1){1'b0}};
        end else begin
            stb <= {stb[N-1:0], take};
            if (enable) begin
                if (cnt == R-1) begin
                    cnt  <= {CW{1'b0}};
                    samp <= integ[N-1];
                end else
                    cnt <= cnt + 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------ combs
    wire signed [BW-1:0] cin [0:N];
    assign cin[0] = samp;

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : COMB
            reg signed [BW-1:0] dly [0:M-1];
            reg signed [BW-1:0] cout;
            integer j;
            assign cin[g+1] = cout;
            always @(posedge clk) begin
                if (reset) begin
                    cout <= {BW{1'b0}};
                    for (j = 0; j < M; j = j + 1) dly[j] <= {BW{1'b0}};
                end else if (stb[g]) begin
                    cout   <= cin[g] - dly[M-1];
                    dly[0] <= cin[g];
                    for (j = 1; j < M; j = j + 1) dly[j] <= dly[j-1];
                end
            end
        end
    endgenerate

    // ------------------------------------------------------------------ scale / round / saturate
    localparam signed [BW-1:0] RNDC = {{(BW-1){1'b0}}, 1'b1} << (SHIFT-1);
    localparam signed [BW-1:0] MAXV = (1 <<< (BOUT-1)) - 1;
    localparam signed [BW-1:0] MINV = -(1 <<< (BOUT-1));

    wire signed [BW-1:0] rounded = cin[N] + RNDC;
    wire signed [BW-1:0] scaled  = rounded >>> SHIFT;

    always @(posedge clk) begin
        if (reset) begin
            dout     <= {BOUT{1'b0}};
            outready <= 1'b0;
        end else begin
            outready <= 1'b0;
            if (stb[N]) begin
                if      (scaled > MAXV) dout <= MAXV[BOUT-1:0];
                else if (scaled < MINV) dout <= MINV[BOUT-1:0];
                else                    dout <= scaled[BOUT-1:0];
                outready <= 1'b1;
            end
        end
    end

endmodule