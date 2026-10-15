`timescale 1ns / 1ps
module cic_fir_top (
    input  wire                clk,
    input  wire                reset,
    input  wire                enable,
    input  wire signed [1:0]   bits,
    output wire signed [19:0]  cicout,
    output wire                cic_valid,
    output wire signed [19:0]  firout,
    output wire                fir_valid
);
    cic_top #(.N(4), .R(512), .M(1), .BIN(2), .BOUT(20)) u_cic (
        .clk(clk), .reset(reset), .enable(enable),
        .din(bits), .dout(cicout), .outready(cic_valid)
    );

    fir_comp #(.NTAPS(255), .AW(8), .DW(20), .CW(18), .FRAC(17),
               .DEC(4), .OW(20)) u_fir (
        .clk(clk), .reset(reset),
        .in_valid(cic_valid), .din(cicout),
        .dout(firout), .out_valid(fir_valid)
    );
endmodule