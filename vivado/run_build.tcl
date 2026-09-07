# 프로젝트 생성 → 합성 → 구현 → 비트파일
source vivado/build.tcl
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# DDR PHY 타이밍 패치: Zynq7000 참조값으로 교정
foreach gen_dir {
    vivado/project_1/ad9248_ps.gen/sources_1/bd/design_1/ip/design_1_processing_system7_0_0/ps7_init.tcl
} {
    if {[file exists $gen_dir]} {
        exec sed -i \
            -e "s/0x0004159B/0x0004159E/g" \
            -e "s/0x452458D3/0x406458D3/g" \
            -e "s/0x00029000/0x0003B805/g" \
            -e "s/0x00000080/0x00000085/g" \
            -e "s/0x000000F9/0x00000143/g" \
            -e "s/0x000000C0/0x000000C5/g" \
            $gen_dir
        puts "Patched: $gen_dir"
    }
}

# XSA 내보내기 (Vitis 플랫폼용)
write_hw_platform -fixed -force -include_bit vivado/ad9248_ps.xsa
puts "INFO: XSA exported → vivado/ad9248_ps.xsa"
