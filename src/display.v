`timescale 1ns / 1ps

module display #(
    parameter CAM_COLS = 320,   // 소스 프레임버퍼 열 수
    parameter CAM_ROWS = 240    // 소스 프레임버퍼 행 수
)(
    input clk74m25,
    output [3:0] vga_red,
    output [3:0] vga_green,
    output [3:0] vga_blue,
    output vga_hsync,
    output vga_vsync,
    output vga_de,              // data enable for rgb2dvi (high during active pixels)
    output [10:0] cam_col,     // 소스 열 0..CAM_COLS-1 (1사이클 선행, axi_hp1_reader 연결)
    output [9:0]  cam_row,     // 소스 행 0..CAM_ROWS-1 (1사이클 선행, axi_hp1_reader 연결)
    input  [11:0] frame_pixel,
    input         camera_active
);
    // HDMI 1280x720 @ 60Hz timing (CEA-861 format 4, pixel clock 74.25MHz)
    localparam DISP_H    = 1280;
    localparam DISP_V    = 720;
    localparam H_SCALE   = DISP_H / CAM_COLS;  // H 업스케일 배율 (power-of-2 권장)
    localparam V_SCALE   = DISP_V / CAM_ROWS;  // V 업스케일 배율 (임의 정수)

    localparam hRez       = DISP_H;
    localparam hStartSync = DISP_H + 110;
    localparam hEndSync   = DISP_H + 110 + 40;
    localparam hMaxCount  = 1650;

    localparam vRez       = DISP_V;
    localparam vStartSync = DISP_V + 5;
    localparam vEndSync   = DISP_V + 5 + 5;
    localparam vMaxCount  = 750;

    reg [10:0] hCounter = 11'd0;
    reg  [9:0] vCounter = 10'd0;

    reg [3:0] r_out, g_out, b_out;
    reg hs_out, vs_out, de_out;

    wire [10:0] hNext = (hCounter == hMaxCount - 1) ? 11'd0 : hCounter + 1;
    wire  [9:0] vNext = (hCounter == hMaxCount - 1) ?
                        ((vCounter == vMaxCount - 1) ? 10'd0 : vCounter + 1) : vCounter;

    // H 업스케일: hNext / H_SCALE → cam_col (H_SCALE이 2의 거듭제곱이면 시프트로 합성)
    assign cam_col = hNext / H_SCALE;

    // V 업스케일: mod-V_SCALE 카운터로 cam_row 계산
    reg [9:0] cam_row_r = 10'd0;
    reg [3:0] row_cnt   = 4'd0;   // V_SCALE 최대 15까지 지원

    always @(posedge clk74m25) begin
        if (hCounter == hMaxCount - 1) begin
            if (vCounter == vMaxCount - 1) begin
                cam_row_r <= 10'd0;
                row_cnt   <= 4'd0;
            end else begin
                if (row_cnt == V_SCALE - 1) begin
                    cam_row_r <= cam_row_r + 1;
                    row_cnt   <= 4'd0;
                end else
                    row_cnt <= row_cnt + 1;
            end
        end
    end

    assign cam_row = cam_row_r;

    // ----------------------------------------------------------
    // 컬러바 테스트 패턴 (카메라 없을 때 표시)
    // ----------------------------------------------------------
    wire [2:0] bar_idx = hCounter[9:7];
    reg [3:0] bar_r, bar_g, bar_b;
    always @(*) begin
        case (bar_idx)
            3'd0: {bar_r, bar_g, bar_b} = {4'h0, 4'h0, 4'h0}; // 검정
            3'd1: {bar_r, bar_g, bar_b} = {4'h0, 4'h0, 4'hF}; // 파랑
            3'd2: {bar_r, bar_g, bar_b} = {4'hF, 4'h0, 4'h0}; // 빨강
            3'd3: {bar_r, bar_g, bar_b} = {4'hF, 4'h0, 4'hF}; // 자홍
            3'd4: {bar_r, bar_g, bar_b} = {4'h0, 4'hF, 4'h0}; // 초록
            3'd5: {bar_r, bar_g, bar_b} = {4'h0, 4'hF, 4'hF}; // 청록
            3'd6: {bar_r, bar_g, bar_b} = {4'hF, 4'hF, 4'h0}; // 노랑
            3'd7: {bar_r, bar_g, bar_b} = {4'hF, 4'hF, 4'hF}; // 흰색
        endcase
    end

    always @(posedge clk74m25) begin
        if (hCounter == hMaxCount - 1) begin
            hCounter <= 11'd0;
            if (vCounter == vMaxCount - 1)
                vCounter <= 10'd0;
            else
                vCounter <= vCounter + 1;
        end else begin
            hCounter <= hCounter + 1;
        end

        // 1280x720 positive sync (CEA-861)
        hs_out <= (hCounter >= hStartSync) && (hCounter < hEndSync);
        vs_out <= (vCounter >= vStartSync) && (vCounter < vEndSync);
        de_out <= (hCounter < hRez) && (vCounter < vRez);

        if (hCounter < hRez && vCounter < vRez) begin
            if (!camera_active) begin
                r_out <= bar_r;
                g_out <= bar_g;
                b_out <= bar_b;
            end else begin
                r_out <= frame_pixel[11:8];
                g_out <= frame_pixel[7:4];
                b_out <= frame_pixel[3:0];
            end
        end else begin
            r_out <= 4'h0;
            g_out <= 4'h0;
            b_out <= 4'h0;
        end
    end

    assign vga_red    = r_out;
    assign vga_green  = g_out;
    assign vga_blue   = b_out;
    assign vga_hsync  = hs_out;
    assign vga_vsync  = vs_out;
    assign vga_de     = de_out;

endmodule
