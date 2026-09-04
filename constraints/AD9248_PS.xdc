# NexEBAZ4205_AD9248_PS constraints
# EBAZ4205 + 660Z069A_V13 IO board + AD9248 14-bit ADC
# 5열 건너뛰기: IO pos 6~15. ENCODE=터미널블록→D18, D19(6A) cut(ADC GND핀)

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

# AD9248 data (ADC → FPGA, 14비트 입력)
# 5열 건너뛰기: IO pos 6~15, D19(GND핀) cut
# 직접 연결 10비트: D0,D2,D4,D5,D6,D7,D9,D11,D12,D13
# 미연결 4비트 (PULLDOWN): D1(F20 HDMI), D3(F19 HDMI), D8(3.3V), D10(GND)
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {adc_data[0]}]
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {adc_data[1]}]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports {adc_data[2]}]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {adc_data[3]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {adc_data[4]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports {adc_data[5]}]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports {adc_data[6]}]
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {adc_data[7]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {adc_data[8]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {adc_data[9]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33 PULLDOWN true} [get_ports {adc_data[10]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {adc_data[11]}]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports {adc_data[12]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {adc_data[13]}]

# ── 비동기 클럭 도메인 선언 ────────────────────────────────────────────
set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins {u_ps7/design_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[0]}]] \
    -group [get_clocks -of_objects [get_pins u_clocking/mmcm_inst/CLKOUT0]] \
    -group [get_clocks -of_objects [get_pins u_clocking/mmcm_inst/CLKOUT1]]
