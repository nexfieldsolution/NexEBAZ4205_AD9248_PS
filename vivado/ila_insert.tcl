# AD9248_PS ILA — ADC 캡처 신호 디버그
#
# 사용법 (Vivado GUI Tcl Console):
#   open_run synth_1
#   source vivado/ila_insert.tcl
#   launch_runs impl_1 -to_step write_bitstream -jobs 4
#   wait_on_run impl_1

create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH        4096  [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN         false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN        false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER       false [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL      true  [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2   [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0     [get_debug_cores u_ila_0]

# ILA 클록: FCLK_CLK0 (50 MHz, ENCODE와 동일 도메인)
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk \
    [get_nets -hier -filter {NAME =~ *FCLK_CLK0* && TYPE == "ClockNet"}]

# probe0: adc_sample [13:0] — offset-binary 캡처값
set adc_s_nets [lsort [get_nets -hier -filter {MARK_DEBUG == 1 && NAME =~ *adc_sample\[*}]]
set_property port_width [llength $adc_s_nets] [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 $adc_s_nets

# probe1: adc_sample_s [13:0] — signed (2의 보수) 변환값
create_debug_port u_ila_0 probe
set adc_ss_nets [lsort [get_nets -hier -filter {MARK_DEBUG == 1 && NAME =~ *adc_sample_s\[*}]]
set_property port_width [llength $adc_ss_nets] [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 $adc_ss_nets

set_property C_CLK_INPUT_FREQ_HZ 50000000 [get_debug_cores dbg_hub]

implement_debug_core
