% Generates fir_coef_rom.v for fir_comp.v  (coefficient design only)
clear; clc;

R1 = 512;  N = 4;  M = 1;            % CIC parameters used in cic_fir_top.v
fs1   = 8000;                        % CIC output rate
fs_in = fs1 * R1;                    % 4.096 MHz
NTAPS = 63;  CW = 18;  FRAC = CW-1; AW = ceil(log2(NTAPS));
fpass = 950; fstop = 1150;          % Hz, tune these

cicmag = @(f) abs(sin(pi*max(f,1e-6)*M/fs1) ./ ...
    (R1*M*sin(pi*max(f,1e-6)*M/fs_in))).^N;

% equiripple fit to 1/|CIC| in the passband, 0 in the stopband
K = 40; fb = linspace(0, fpass, K+1); gap = 1e-3*fpass/K;
F = []; A = []; W = [];
for k = 1:K
    F = [F fb(k) fb(k+1)-gap];
    A = [A 1/cicmag(fb(k)) 1/cicmag(fb(k+1)-gap)];
    W = [W 10];
end
F = [F fstop fs1/2];  A = [A 0 0];  W = [W 1];
h  = firpm(NTAPS-1, F/(fs1/2), A, W);
hq = round(h * 2^FRAC);
assert(max(abs(hq)) < 2^(CW-1), 'coefficient overflow');

% optional check plot
[Hf, fh] = freqz(hq/2^FRAC, 1, 8192, fs1);
plot(fh, 20*log10(abs(Hf).*cicmag(fh))); grid on; xlim([0 4000]);
xlabel('Hz'); ylabel('dB'); title('CIC x FIR');

% write Verilog ROM
fid = fopen('fir_coef_rom.v','w');
fprintf(fid,'`timescale 1ns / 1ps\n');
fprintf(fid,'module fir_coef_rom #(parameter AW = %d, parameter CW = %d)(\n', AW, CW);
fprintf(fid,'    input  wire [AW-1:0] addr,\n    output reg signed [CW-1:0] coef);\n');
fprintf(fid,'    always @(*) begin\n        case (addr)\n');
for k = 0:NTAPS-1
    fprintf(fid,'            %d: coef = %d;\n', k, hq(k+1));
end
fprintf(fid,'            default: coef = 0;\n        endcase\n    end\nendmodule\n');
fclose(fid);