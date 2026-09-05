`timescale 1ns / 1ps

// AD9248 14-bit ADC capture
// Offset-binary: 0x2000=midscale(0V), 0x3FFF=+FS, 0x0000=-FS
// ENCODE(clk) rising edge → ADC latches analog input
// Output data appears after fixed pipeline latency (3 clocks typical)
module adc_capture (
    input             clk,        // = ENCODE (50 MHz)
    input  [13:0]     adc_raw,    // AD9248 parallel output (offset binary)
    output reg [13:0] sample,     // registered sample
    output reg [13:0] sample_s    // signed (two's complement, for DSP)
);
    always @(posedge clk) begin
        sample   <= adc_raw;
        sample_s <= {~adc_raw[13], adc_raw[12:0]};  // offset→signed: flip MSB
    end
endmodule
