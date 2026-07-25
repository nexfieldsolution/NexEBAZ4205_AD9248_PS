# NexEBAZ4205_OV5640_PS constraints
# EBAZ4205 + hellofpga IO board 20-pin camera connector

# HDMI (TMDS, hellofpga IO board)
set_property -dict {PACKAGE_PIN F20 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_N]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD TMDS_33} [get_ports HDMI_CLK_P]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[0]}]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[0]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[1]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {HDMI_P[1]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {HDMI_N[2]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {HDMI_P[2]}]

# OV5640 - hellofpga IO board 20-pin camera connector
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports ov5640_vsync]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports ov5640_href]
# camera RST → J20 점퍼 (XADC핀이지만 출력으로 사용)
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports ov5640_reset]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports ov5640_sioc]
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVCMOS33 PULLUP true} [get_ports ov5640_siod]
# D[0]: G19 (구 PWDN핀 재활용, 카메라 PWDN은 GND 직결)
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[0]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[1]}]
# D[2]: G20 (구 RST핀 재활용, 카메라 RST=J20 점퍼)
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[2]}]
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[3]}]
# D[4]: K18 (MRCC N-type, 데이터 입력으로 사용)
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[4]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[5]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[6]}]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports {ov5640_data[7]}]
# PCLK: J18 MRCC P-type, 카메라 온보드 크리스탈 54MHz
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports ov5640_pclk]
# PWDN: 카메라 모듈 GND 직결 → FPGA 출력은 dummy
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ov5640_pwdn]

# pclk: OV5640 54MHz (MRCC P-type J18 → BUFG)
create_clock -period 18.519 -name pclk [get_ports ov5640_pclk]

# ── 비동기 클럭 도메인 선언 ────────────────────────────────────────────
# FCLKCLK[0],CLKOUT0,CLKOUT1 클록과 pclk는 서로 비동기 클록이므로 타이밍분석을 제외한다
set_clock_groups -asynchronous \
    -group [get_clocks -of_objects [get_pins {u_ps7/design_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[0]}]] \
    -group [get_clocks -of_objects [get_pins u_clocking/mmcm_inst/CLKOUT0]] \
    -group [get_clocks -of_objects [get_pins u_clocking/mmcm_inst/CLKOUT1]] \
    -group [get_clocks pclk]

# pclk ↔ clk25_buf (CLKOUT1의 BUFG 출력 클록명)
set_clock_groups -asynchronous -group [get_clocks pclk] -group [get_clocks clk25_buf]
