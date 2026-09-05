# NexEBAZ4205_AD9248_PS - Vivado project creation
# 실행: vivado -mode batch -source vivado/build.tcl

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set ROOT_DIR   [file normalize [file join $SCRIPT_DIR ..]]
set PROJ_DIR   [file join $SCRIPT_DIR project_1]

create_project -force ad9248_ps $PROJ_DIR -part xc7z020clg400-1
set_property target_language Verilog [current_project]

# Source files
add_files [list \
    $ROOT_DIR/src/top_ad9248_ps.v \
    $ROOT_DIR/src/adc_capture.v \
    $ROOT_DIR/src/clocking.v \
    $ROOT_DIR/src/display.v]

# VHDL: rgb2dvi
add_files [glob $ROOT_DIR/src/rgb2dvi/*.vhd]
set_property file_type VHDL [get_files $ROOT_DIR/src/rgb2dvi/*.vhd]

# Block Design (PS7 + AXI HP0/HP1)
add_files $ROOT_DIR/vivado/bd/design_1.bd
set_property synth_checkpoint_mode None [get_files design_1.bd]
generate_target all [get_files design_1.bd]
set bd_wrapper [make_wrapper -files [get_files design_1.bd] -top]
add_files -norecurse $bd_wrapper

# Constraints
add_files -fileset constrs_1 $ROOT_DIR/constraints/AD9248_PS.xdc

# Top module
set_property top top_ad9248_ps [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: project created → $PROJ_DIR"
puts "INFO: run build: vivado -mode batch -source vivado/run_build.tcl"
