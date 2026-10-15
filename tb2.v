`timescale 1ns / 1ps
module cic_tb();
    reg data [0:4096025];

    reg clk, reset, enable;
    wire outready;                       // CIC output valid (8 kHz)
    wire fir_valid;                      // FIR output valid (2 kHz)

    reg  signed [1:0]  bits;

    wire signed [19:0] cicout;
    wire signed [19:0] firout;           // was [92:0]

    initial begin
        $readmemh("hz500.mem", data);    // <-- change per tone
    end

    initial begin
        clk = 0;
        bits = 0;
        enable = 0;
        reset = 1;
        #51 reset = 0;
        enable = 1;
    end
    always #50 clk = ~clk;

    integer i;
    initial i = 0;

    integer fd1, fd2, fd3;
    initial begin
        fd1 = $fopen("bits.txt", "w");
        fd2 = $fopen("cic512_10.txt", "w");     // CIC stage output (8 kHz)
        fd3 = $fopen("fircomp_500.txt", "w");    // final output -> fft_2.m
    end

    always @(posedge clk) begin
        if (i < 4096026) begin
            if (i % 2 == 0) bits = {1'b0, data[i]};
            else            bits = {2{data[i]}};
            i <= i + 1;
        end else begin
            #250000;
            $finish;
        end
    end

    always @(posedge clk) $fwrite(fd1, "%d\n", bits);

    always @(posedge clk) begin
        if (outready)  $fwrite(fd2, "%d\n", $signed(cicout));
    end

    always @(posedge clk) begin
        if (fir_valid) $fwrite(fd3, "%d\n", $signed(firout));
    end

    cic_fir_top dut (
        .clk(clk), .reset(reset), .enable(enable), .bits(bits),
        .cicout(cicout), .cic_valid(outready),
        .firout(firout), .fir_valid(fir_valid)
    );
endmodule