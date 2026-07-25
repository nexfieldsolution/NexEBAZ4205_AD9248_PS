`timescale 1ns / 1ps
//
// axi_hp1_reader.v  —  DDR3 프레임버퍼 → AXI HP1 → 디스플레이 라인 버퍼
//
// 1280x720 픽셀 중 요청된 소스 행(src_row)을 DDR3에서 버스트 읽어
// 1280×16 라인 버퍼에 저장. disp_clk 도메인에서 src_col로 1사이클 레이턴시로 출력.
//
// 버스트: arlen=15 (16beat) × arsize=011 (8B) = 128B = 64픽셀
//   행당 20버스트 → 1280픽셀. aclk(50MHz)에서 ≈7.5μs / 행 표시시간 ≈17.5μs(74.25MHz)
//
// CDC: src_row 변화를 토글+2FF 동기화로 aclk 도메인에 전달
//

module axi_hp1_reader #(
    parameter [31:0] DDR3_BASE = 32'h1000_0000
)(
    // ── 동적 프레임버퍼 베이스 주소 (핑퐁용, aclk 도메인) ──
    input      [31:0] base_addr,

    // ── 디스플레이 인터페이스 (disp_clk = 74.25 MHz) ───────────────
    input              disp_clk,
    input      [9:0]   src_row,      // 현재 요청 소�� 행 0..719 (1사이클 선행)
    input      [10:0]  src_col,      // 현재 요청 소스 열 0..1279 (1사이클 선행)
    output     [11:0]  frame_pixel,  // 1사이클 레이턴시 픽셀 출력

    // ── AXI HP1 읽기 마스터 (aclk = 50 MHz) ────��───────────────
    input             aclk,
    input             aresetn,
    // AR 채널
    output reg [31:0] araddr,
    output     [5:0]  arid,
    output     [3:0]  arlen,
    output     [2:0]  arsize,
    output     [1:0]  arburst,
    output     [1:0]  arlock,
    output     [3:0]  arcache,
    output     [2:0]  arprot,
    output     [3:0]  arqos,
    output reg        arvalid,
    input             arready,
    // R 채널
    input      [63:0] rdata,
    input      [5:0]  rid,
    input      [1:0]  rresp,
    input             rlast,
    input             rvalid,
    output            rready
);

// ── 고정 AXI 신호 ──────────────────────────────────────────────
assign arid    = 6'd0;
assign arlen   = 4'd15;      // 16 beats per burst
assign arsize  = 3'b011;     // 8 bytes (64-bit bus)
assign arburst = 2'b01;      // INCR
assign arlock  = 2'b00;
assign arcache = 4'b0011;    // Bufferable
assign arprot  = 3'b000;
assign arqos   = 4'd0;
assign rready  = 1'b1;       // 읽기 데이터 항상 수락

// ── 라인 버퍼: 320×64-bit (RAMB36) ─────────────────────────────
// 64-bit entry = 4픽셀×16bit. 한 클럭 1 write로 BRAM 추론 가능.
// 읽기는 disp_clk, 쓰기는 aclk → TDP BRAM.
(* RAM_STYLE = "block" *)
reg [63:0] line_buf [0:319];

// disp_clk: 동기 읽기 (1사이클 레이턴시)
reg [63:0] rd_word;
reg  [1:0] pix_sel_r;

always @(posedge disp_clk) begin
    rd_word   <= line_buf[src_col[10:2]];
    // rd_word   <= (src_col[10:2] < 9'd160) ? 64'hF000F000F000F000  // 왼쪽 빨강
    //                                        : 64'h000F000F000F000F;  // 오른쪽 파랑
    pix_sel_r <= src_col[1:0];
end

wire [15:0] rd_pix = (pix_sel_r == 2'd0) ? rd_word[15:0]  :
                     (pix_sel_r == 2'd1) ? rd_word[31:16] :
                     (pix_sel_r == 2'd2) ? rd_word[47:32] :
                                           rd_word[63:48];
assign frame_pixel = rd_pix[11:0];

// ── CDC: src_row 변화 → aclk 도메인 전달 (토글 + 2FF) ──────────
reg [9:0] src_row_d = 10'd0;
reg       req_tog   = 1'b0;
reg [9:0] req_row   = 10'd0;

always @(posedge disp_clk) begin
    src_row_d <= src_row;
    if (src_row != src_row_d) begin
        req_row <= src_row;
        req_tog <= ~req_tog;
    end
end

reg [1:0] tog_sync = 2'b00;
reg [9:0] row_sync = 10'd0;
always @(posedge aclk) begin
    tog_sync <= {tog_sync[0], req_tog};
    row_sync <= req_row;
end

wire       fetch_req = tog_sync[0] ^ tog_sync[1];
wire [9:0] fetch_row = row_sync;

// ─�� AXI 읽기 ��태기 (aclk) ─────────────────────────────────────
localparam ST_IDLE = 2'd0;
localparam ST_AR   = 2'd1;
localparam ST_R    = 2'd2;

reg [1:0]  state     = ST_IDLE;
reg [9:0]  rd_row    = 10'd0;
reg [4:0]  burst_cnt = 5'd0;   // 0..19 (20 bursts per row)
reg [8:0]  wr_col    = 9'd0;   // 0..319 (64-bit 워드 단위)

// 새 요청 래치 (busy 중 도착한 요청을 최신 행으로 갱신)
reg        pending     = 1'b1;   // 리셋 후 행 0 즉시 패치
reg [9:0]  pending_row = 10'd0;

// row_base = DDR3_BASE + rd_row × 2560  (2560 = 1280픽셀 × 2바이트)
// 2560 = 2048 + 512 = (1<<11) + (1<<9)
// 행 2560바이트는 128B의 배수 → 버스트 정렬 ✓
wire [31:0] row_base = base_addr
    + {11'd0, rd_row, 11'd0}    // rd_row × 2048
    + {13'd0, rd_row,  9'd0};   // rd_row × 512

// burst_off = burst_cnt × 128
wire [31:0] burst_off = {20'd0, burst_cnt, 7'd0};

// // rdata 대신 테스트 패턴 (BRAM 읽기/쓰기 경로 테스트)
// wire [63:0] rdata_test = (wr_col < 9'd160) ? 64'h0F000F000F000F00   // 빨강
//                                             : 64'h000F000F000F000F;  // 파랑

// BRAM 쓰기: aresetn 없는 별도 블록 → BRAM 추론 가능
always @(posedge aclk)
    if (rvalid && (state == ST_R)) begin
        line_buf[wr_col] <= rdata;
        // line_buf[wr_col] <= rdata_test;
    end
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state       <= ST_IDLE;
        arvalid     <= 1'b0;
        burst_cnt   <= 5'd0;
        wr_col      <= 9'd0;
        pending     <= 1'b1;
        pending_row <= 10'd0;
    end else begin
        if (fetch_req) begin
            pending     <= 1'b1;
            pending_row <= fetch_row;
        end

        case (state)

        ST_IDLE: begin
            if (pending) begin
                rd_row    <= pending_row;
                pending   <= 1'b0;
                burst_cnt <= 5'd0;
                wr_col    <= 9'd0;
                state     <= ST_AR;
            end
        end

        ST_AR: begin
            araddr  <= row_base + burst_off;
            arvalid <= 1'b1;
            if (arvalid && arready) begin
                arvalid <= 1'b0;
                state   <= ST_R;
            end
        end

        ST_R: begin
            if (rvalid) begin
                wr_col <= wr_col + 9'd1;
                if (rlast) begin
                    if (burst_cnt == 5'd19)
                        state <= ST_IDLE;
                    else begin
                        burst_cnt <= burst_cnt + 5'd1;
                        state     <= ST_AR;
                    end
                end
            end
        end

        default: state <= ST_IDLE;
        endcase
    end
end

endmodule
