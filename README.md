# NexEBAZ4205_OV5640_PS

EBAZ4205 + hellofpga IO board + OV5640 camera → Zynq PS DDR3 frame buffer → HDMI output

- OV5640 DVP 1280x720 RGB565 → AXI HP → PS DDR3 frame buffer → AXI HP → 1280x720 HDMI 풀해상도 출력
- Zynq PS bare metal (FSBL + standalone)
- PL: OV5640 capture + AXI master (write) + display timing + rgb2dvi (read)
- Vivado project: `vivado -mode batch -source vivado/build.tcl`

베이스: [NexEBAZ4205_OV5640_PL](https://github.com/nexfieldsolution/NexEBAZ4205_OV5640_PL) — PL only 버전에서 PS 통합으로 확장

##  실험 방법
- xsdb 콘솔에서 ps7_init.tcl을 로딩후 실행 
- vivado에서 biitstream을 업데이트 

또는 위의 두가지를 아래와 같이 한번에 
  cd /media/douglas/extssd/FPGA/Xilinx/NexEBAZ4205_OV5640_PS/
  xsdb
이후, xsdb console에서 
    connect
    targets 2
    rst -processor
    source /media/douglas/extssd/FPGA/Xilinx/NexEBAZ4205_OV5640_PS/vivado/project_1/ov5640_ps.gen/sources_1/bd/design_1/ip/design_1_processing_system7_0_0/ps7_init.tcl
    ps7_init
    ps7_post_config
    fpga -f /media/douglas/extssd/FPGA/Xilinx/NexEBAZ4205_OV5640_PS/vivado/project_1/ov5640_ps.runs/impl_1/top_ov5640_ps.bit

## DDR3 문제발생
- 내가 vivado board design에서 설정후 생성한 ps7_init.tcl로 실행하면 ddr3 ram read/write테스트에 문제가 있다
  어떤 문제?  ram의 상위 16비트가 쓰여지지 않는다.
  즉 다음과 같은 결과가 나온다 

    xsdb% mwr 0x11000000 0x12345678
    xsdb% mrd 0x11000000 1  
    11000000:   00005678   //상위 word가 제대로 쓰여지지 않는다.
- 원칙적으로 vivado설정을 다시 해야하니, 예전의 NexEBAZ4205_Zynq7000 프로젝트에서 사용하던 ps7_init.tcl과 비교해서 레지스터 설정상 차이점을 찾았다
  지금은 편법적으로 ./vivado/run_build.tcl 파일에서 특정 레지스터만 설정을 다시 하는 방법을 사용했다
  - ./vivado/run_build.tcl 파일 에서 tcl을 수정해서 gendir에 출력   
    # DDR PHY 타이밍 패치: Zynq7000 참조값으로 교정 (FCLK는 변경 안 함)
    foreach gen_dir {
        vivado/project_1/ov5640_ps.gen/sources_1/bd/design_1/ip/design_1_processing_system7_0_0/ps7_init.tcl
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

- 편법적이지만 이렇게 램설정을 변경해주고 나니, xsdb에서 정확히 32bit write/read가 된다

    xsdb% mwr 0x11000000 0x12345678
    xsdb% mrd 0x11000000 1  
    11000000:   12345678 

-> 이 부분은 vivado설정을 제대로 하거나 vitis 펌웨어에서 초기화시 반영하면 된다. 

## 작업 결과 1

- 320×240 영상 출력 OK (DDR3 프레임버퍼 → HDMI)
- AXI HP0 write / HP1 read 파이프라인 동작 확인 (xsdb mrd/mwr 검증)
- 1픽셀 오프셋 버그 수정 (addr_latch 추가, 2026.07.01)

| 기대 결과 | 현재 결과 |
|-----------|-----------|
| ![expect](NexEBAZ4205_OV5640_PS_expect.png) | ![result](NexEBAZ4205_OV5640_PS_result2.png) |

## 문제점 1

- **ddr3 설정문제 있슴** — ps7_init.tcl 생성과정에서 vivado에서 ddr3관련 설정이 잘못된 듯

  - **임시로  ./vivado/run_build.tcl 파일 에서 tcl을 수정해서 gendir에 출력 → 향후 PetaLinux에서 계속 디버깅**

- **출력해상도 문제** — ov5640은 1280x720, hdmi출력은 640x480, display framebuffer는 320x240임 
                    프레임버퍼 해상도는  NexEBAZ4205_OV5640_PL 소스에서 클론해서 프로젝트를 만든 때문, NexEBAZ4205_OV5640_PL에서는 bram에 fb를 할당했기 때문에 부득이 프레임버퍼의 사이즈를 줄였던것

## 카메라 Full해상도 출력
- ov5640_capture.v에서 crop 및  1/2 다운 샘플링 소스를 제거, 320x240 => 1280x760으로 수정 
- display.v에서 640x480으로 업샘플링 하던 소스를  => 1280x760 그대로 출력하도록 수정 

## 작업 결과 2
- 화면은 1024x720 으로 출력된다.
- 그러나 모자이크현상이 심하고, 3~5초 정도 지냐아 차츰 모자이크 현상이 점차 사라진다


## 문제점 2
- *** 모자이크 현상 *** 다시 발생 - axi writer / reader에서 전송대역폭이 낮음 
- 1 beat burst => 16 beats burst 수정 


## 작업 결과 3
- 모자이크현상은 사라졌으나 가로줄이 심하게 생기는 Tearing현상 생김

## 문제점 3
- *** 심한 가로줄 (Tearing) 현상 *** 발생

## Tearing 해결 (2026-07-25)

- 기존 커스텀 async FIFO → Xilinx XPM `xpm_fifo_async` (block RAM 기반, DEPTH=512, WIDTH=32) 로 교체
- 핑퐁 더블버퍼: FB0=0x1000_0000, FB1=0x1040_0000 (+4MB), buf_sel 토글
- Tearing 사라짐 확인

## 작업 결과 4 (2026-07-25)

- **1280×720@30 풀해상도 DDR3 프레임버퍼 → HDMI 출력 성공, Tearing 없음**

![result4](NexEBAZ4205_OV5640_PS_result4.png)

## 문제점 4 (미해결 / 하드웨어 한계)
- **오른쪽 끝 세로선**: 화면 우측 가장자리에 얇은 세로선 — 원인 미확정, 보류
- **흐릿한 화질** 사진과 같이 폰트를 알아보기 힘들 정도로 흐릿 하다. 
- **색상/노이즈**: 일부 데이터 핀이 XADC 핀에 연결되어 있고 커넥터 노이즈가 있어 색 재현 불완전
- **블러**: 렌즈 초점 또는 핀 노이즈에 기인한 것으로 추정


## 최종정리 
- **1280×720@30 풀 해상도 영상을 HDMI로 출력**하기 위해 PS의 DDR3에 프레임버퍼를 할당하고 AXI3 인터페이스를 구현했다. 
- 아쉽게도 최종 작업결과에서도 camera 영상이 흐릿하고 붉은 색상이 끼여있다.
  이것들은 EBAZ4205보드에 hellofpga.com의 IO보드를 꼿고 여기에 다시 OV5640모듈을 연결했고
  IO보드의 일부 핀들이 camera의 신호선으로 적합하지 않아서 jumper하는 과정에서 발생한 노이즈로 판단된다.
  이 문제들을 본질적인 것은 아니어서 이정도로 마무리한다.
  
## Status

- [x] Zynq PS Block Design 생성 (PS7 + DDR3 + AXI HP0/HP1)
- [x] top_ov5640_ps.v 완성
- [x] axi_hp0_writer.v — OV5640 → DDR3 write
- [x] axi_hp1_reader.v — DDR3 → display read
- [x] 320×240 영상 출력 동작 확인
- [x] 색상 문제 해결
- [x] 1280×720 풀해상도 프레임버퍼로 확장
- [x] Tearing 해결 (xpm_fifo_async + 핑퐁 버퍼)
- [ ] PetaLinux 부팅

## Architecture

```
OV5640 DVP (54MHz PCLK)
    ↓
PL: ov5640_capture → AXI HP0 write → DDR3 (1280×720×2 = 1.84MB/frame)
                                           ↓
PL: display timing (1280×720) ← AXI HP1 read
    ↓
rgb2dvi (Digilent) → HDMI
```

## Pin Map

### System

| Signal   | Pin | IOSTANDARD | Description        |
|----------|-----|------------|--------------------|
| CLK      | N18 | LVCMOS33   | 50MHz PL clock     |
| UART_TX  | H17 | LVCMOS33   | UART TX (CH340)    |

### HDMI (hellofpga IO board, TMDS)

| Signal      | Pin | IOSTANDARD | Description     |
|-------------|-----|------------|-----------------|
| HDMI_CLK_P  | F19 | TMDS_33    | TMDS clock +    |
| HDMI_CLK_N  | F20 | TMDS_33    | TMDS clock -    |
| HDMI_P[0]   | D19 | TMDS_33    | TMDS data0 +    |
| HDMI_N[0]   | D20 | TMDS_33    | TMDS data0 -    |
| HDMI_P[1]   | C20 | TMDS_33    | TMDS data1 +    |
| HDMI_N[1]   | B20 | TMDS_33    | TMDS data1 -    |
| HDMI_P[2]   | B19 | TMDS_33    | TMDS data2 +    |
| HDMI_N[2]   | A20 | TMDS_33    | TMDS data2 -    |

### OV5640 (hellofpga IO board 20-pin camera connector)

| Signal          | Pin | IOSTANDARD | Description                          |
|-----------------|-----|------------|--------------------------------------|
| ov5640_pclk     | J18 | LVCMOS33   | Pixel clock (MRCC P-type, 54MHz)     |
| ov5640_vsync    | M17 | LVCMOS33   | Vertical sync                        |
| ov5640_href     | N20 | LVCMOS33   | Horizontal ref                       |
| ov5640_data[0]  | G19 | LVCMOS33   | Pixel data bit 0 (구 PWDN핀 재활용)  |
| ov5640_data[1]  | L16 | LVCMOS33   | Pixel data bit 1                     |
| ov5640_data[2]  | G20 | LVCMOS33   | Pixel data bit 2 (구 RST핀 재활용)   |
| ov5640_data[3]  | L19 | LVCMOS33   | Pixel data bit 3                     |
| ov5640_data[4]  | K18 | LVCMOS33   | Pixel data bit 4 (MRCC N-type 재활용)|
| ov5640_data[5]  | J19 | LVCMOS33   | Pixel data bit 5                     |
| ov5640_data[6]  | K19 | LVCMOS33   | Pixel data bit 6                     |
| ov5640_data[7]  | H20 | LVCMOS33   | Pixel data bit 7                     |
| ov5640_sioc     | P18 | LVCMOS33   | I2C SCL                              |
| ov5640_siod     | M19 | LVCMOS33   | I2C SDA                              |
| ov5640_reset    | J20 | LVCMOS33   | Reset (active low, XADC출력으로 동작)|
| ov5640_pwdn     | L17 | LVCMOS33   | Power down — dummy (카메라 GND 직결) |
