`timescale 1ns / 1ps
module fir_coef_rom #(parameter AW = 6, parameter CW = 18)(
    input  wire [AW-1:0] addr,
    output reg signed [CW-1:0] coef);
    always @(*) begin
        case (addr)
            0: coef = -683;
            1: coef = 3501;
            2: coef = -1426;
            3: coef = -1623;
            4: coef = -793;
            5: coef = 246;
            6: coef = 1069;
            7: coef = 1267;
            8: coef = 649;
            9: coef = -497;
            10: coef = -1465;
            11: coef = -1546;
            12: coef = -530;
            13: coef = 1051;
            14: coef = 2156;
            15: coef = 1888;
            16: coef = 183;
            17: coef = -1994;
            18: coef = -3146;
            19: coef = -2218;
            20: coef = 570;
            21: coef = 3603;
            22: coef = 4711;
            23: coef = 2555;
            24: coef = -2238;
            25: coef = -6992;
            26: coef = -8155;
            27: coef = -3232;
            28: coef = 7584;
            29: coef = 21061;
            30: coef = 32193;
            31: coef = 36499;
            32: coef = 32193;
            33: coef = 21061;
            34: coef = 7584;
            35: coef = -3232;
            36: coef = -8155;
            37: coef = -6992;
            38: coef = -2238;
            39: coef = 2555;
            40: coef = 4711;
            41: coef = 3603;
            42: coef = 570;
            43: coef = -2218;
            44: coef = -3146;
            45: coef = -1994;
            46: coef = 183;
            47: coef = 1888;
            48: coef = 2156;
            49: coef = 1051;
            50: coef = -530;
            51: coef = -1546;
            52: coef = -1465;
            53: coef = -497;
            54: coef = 649;
            55: coef = 1267;
            56: coef = 1069;
            57: coef = 246;
            58: coef = -793;
            59: coef = -1623;
            60: coef = -1426;
            61: coef = 3501;
            62: coef = -683;
            default: coef = 0;
        endcase
    end
endmodule
