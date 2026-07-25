`timescale 1ns / 1ps

module ov5640_capture(
    input pclk,
    input vsync,
    input href,
    input [7:0] d,
    output [19:0] addr,    // 0..921599 (1280×720 - 1)
    output [11:0] dout,
    output we
);
    reg [15:0] d_latch    = 16'd0;
    reg        byte_cnt   =  1'b0;
    reg [19:0] addr_reg   = 20'd0;
    reg [19:0] addr_latch = 20'd0;
    reg [11:0] dout_reg   = 12'd0;
    reg        we_reg     = 1'b0;

    assign addr = addr_latch;
    assign dout = dout_reg;
    assign we   = we_reg;

    // BGR565 HIGH-byte-first: HIGH(BBBBBGGG) 먼저, LOW(GGGRRRRR) 나중
    wire [15:0] pix16 = {d_latch[15:8], d};

    always @(posedge pclk) begin
        if (vsync) begin
            byte_cnt   <= 1'b0;
            addr_reg   <= 20'd0;
            addr_latch <= 20'd0;
            we_reg     <= 1'b0;
        end else if (href) begin
            byte_cnt <= ~byte_cnt;
            d_latch  <= {d, d_latch[15:8]};

            if (byte_cnt == 1'b1) begin
                dout_reg   <= {pix16[4:1], pix16[10:7], pix16[15:12]};  // R=[4:1], G=[10:7], B=[15:12]
                we_reg     <= 1'b1;
                addr_latch <= addr_reg;
                addr_reg   <= addr_reg + 1'b1;
            end else
                we_reg <= 1'b0;
        end else begin
            we_reg   <= 1'b0;
            byte_cnt <= 1'b0;
        end
    end

endmodule
