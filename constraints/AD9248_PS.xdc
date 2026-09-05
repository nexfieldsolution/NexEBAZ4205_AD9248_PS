# NexEBAZ4205_AD9248_PS constraints
# EBAZ4205 + 660Z069A_V13 IO board + AD9248 14-bit ADC
# 4열 건너뛰기: IO pos 5~14
# ENCODE: D20(pos5B)→뒷면점프→D18(pos5A), OEB: M19 점프선
# cut핀: D19(6A,HDMI_P[0]), F20(7B,HDMI_CLK-), F19(8B,HDMI_CLK+), 3.3V(11A), GND(12A)
# 점프선 5비트: D0→P19, D3→N17, D5→P20, D10→P18, D12→U20

# HDMI (TMDS)
set_property -dict {PACKAGE_PIN F20 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_N]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_P]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[0]}]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[0]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[1]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {HDMI_P[1]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[2]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[2]}]

# AD9248 ENCODE 클록 (FPGA → ADC, ODDR 출력)
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports adc_encode]

# AD9248 OEB (Output Enable Bar, active-low, FPGA → ADC)
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33} [get_ports adc_oeb]

# AD9248 data (ADC → FPGA, 14비트 입력)
# 직접 연결 9비트: D1(H18), D2(E19), D4(K17), D6(J18), D7(G20), D8(H20), D9(G19), D11(J19), D13(K18)
# 점프선 5비트:    D0(P19), D3(N17), D5(P20), D10(P18), D12(U20)
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports {adc_data[0]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {adc_data[1]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {adc_data[2]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {adc_data[3]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports {adc_data[4]}]
set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVCMOS33} [get_ports {adc_data[5]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {adc_data[6]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports {adc_data[7]}]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports {adc_data[8]}]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {adc_data[9]}]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {adc_data[10]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {adc_data[11]}]
set_property -dict {PACKAGE_PIN U20 IOSTANDARD LVCMOS33} [get_ports {adc_data[12]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {adc_data[13]}]

# ── 비동기 클럭 도메인 선언 ────────────────────────────────────────────
set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins {u_ps7/design_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[0]}]] \
    -group [get_clocks -of_objects [get_pins u_clocking/mmcm_inst/CLKOUT0]] \
    -group [get_clocks -of_objects [get_pins u_clocking/mmcm_inst/CLKOUT1]]
