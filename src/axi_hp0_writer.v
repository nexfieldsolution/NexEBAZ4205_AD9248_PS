`timescale 1ns / 1ps
//
// axi_hp0_writer.v  —  OV5640 capture → AXI HP0 → DDR3 frame buffer (버스트 쓰기)
//
// 4픽셀(각 16bit)을 64bit으로 패킹 후 16-beat 버스트 쓰기
// 64픽셀/버스트, 처리량 ~32M픽셀/초 (카메라 27M픽셀/초 대비 충분)
// 버스트 주소 정렬: 64픽셀 × 2B = 128B → DDR3_BASE + n×128 (DDR3_BASE 128B 정렬 시 보장)
//

module axi_hp0_writer #(
    parameter [31:0] DDR3_BASE = 32'h1000_0000
  )(
    // ── Pixel input (PCLK ~54MHz) ──────────────────────────
    input             pclk,
    input      [19:0] pix_addr,
    input      [11:0] pix_data,
    input             pix_we,

    // ── 동적 프레임버퍼 베이스 주소 (핑퐁용, aclk 도메인) ──
    input      [31:0] base_addr,

    // ── AXI HP0 master (FCLK_CLK0 50MHz) ──────────────────
    input             aclk,
    input             aresetn,

    // AW 채널
    output reg [31:0] awaddr,
    output     [5:0]  awid,
    output     [3:0]  awlen,
    output     [2:0]  awsize,
    output     [1:0]  awburst,
    output     [1:0]  awlock,
    output     [3:0]  awcache,
    output     [2:0]  awprot,
    output     [3:0]  awqos,
    output reg        awvalid,
    input             awready,

    // W 채널
    output reg [63:0] wdata,
    output     [5:0]  wid,
    output     [7:0]  wstrb,
    output reg        wlast,
    output reg        wvalid,
    input             wready,

    // B 채널
    input      [5:0]  bid,
    input      [1:0]  bresp,
    input             bvalid,
    output            bready,

    output            fifo_empty    // FIFO 비었을 때 HIGH (aclk 도메인)
  );

  // ── 고정 AXI 신호 ──────────────────────────────────────────
  assign awid    = 6'd0;
  assign awlen   = 4'd15;      // 16 beats per burst
  assign awsize  = 3'b011;     // 8 bytes (64-bit bus)
  assign awburst = 2'b01;      // INCR
  assign awlock  = 2'b00;
  assign awcache = 4'b0011;
  assign awprot  = 3'b000;
  assign awqos   = 4'b0000;
  assign wid     = 6'd0;
  assign wstrb   = 8'hFF;      // 모든 바이트 유효
  assign bready  = 1'b1;

  // ── Async FIFO (PCLK write / ACLK read) ──────────────────
  // -------------------------------------------------
  //  Async FIFO (pclk → aclk) using XPM primitive
  // -------------------------------------------------
  // XPM async FIFO parameters (block RAM based)
  localparam FIFO_DEPTH   = 512;          // entries
  localparam FIFO_WIDTH   = 32;           // bits per entry ({pix_addr,pix_data})
  localparam FDWID = FIFO_WIDTH; // keep old name for compatibility
  // ----- FIFO signal declarations -----
  wire [FDWID-1:0] fifo_rdata; // data output from XPM FIFO
  wire           full, empty; // status flags from FIFO
  reg            fifo_pop = 0; // read enable used in FSM
  // XPM async FIFO instance
  xpm_fifo_async #(
                   .FIFO_MEMORY_TYPE ("block"),
                   .ECC_MODE         ("no_ecc"),
                   .WRITE_DATA_WIDTH (FIFO_WIDTH),
                   .READ_DATA_WIDTH  (FIFO_WIDTH),
                   .WR_DATA_COUNT_WIDTH (10),        // log2(FIFO_DEPTH)+1
                   .RD_DATA_COUNT_WIDTH (10),
                   .PROG_FULL_THRESH   (FIFO_DEPTH-1), // almost full
                   .PROG_EMPTY_THRESH  (3)               // almost empty
                 ) u_async_fifo (
                   .wr_clk   (pclk),
                   .rd_clk   (aclk),
                   .rst      (~aresetn),
                   .din      ({pix_addr, pix_data}),
                   .wr_en    (pix_we && !full),
                   .rd_en    (fifo_pop && !empty),
                   .dout     (fifo_rdata),
                   .full     (full),
                   .empty    (empty),
                   .prog_full (),
                   .prog_empty()
                 );

  // expose signals with original names used in the FSM
  assign fifo_full  = full;
  assign fifo_empty = empty;


  // ---------- Write side (pclk domain) ----------
  // FIFO read data is provided by XPM instance (fifo_rdata)
  wire [19:0] f_addr = fifo_rdata[31:12];
  wire [11:0] f_pix  = fifo_rdata[11:0];

  // No extra read‑pointer logic needed – XPM handles it


  // ── AXI 버스트 쓰기 상태기 (aclk) ────────────────────────
  localparam ST_IDLE = 3'd0;
  localparam ST_AW   = 3'd1;
  localparam ST_PACK = 3'd2;   // 4픽셀 → 64bit 패킹
  localparam ST_W    = 3'd3;   // W beat 전송
  localparam ST_B    = 3'd4;   // 응답 대기

  reg [2:0]  state    = ST_IDLE;
  reg [63:0] pack_buf = 64'd0;
  reg [1:0]  pix_cnt  = 2'd0;   // beat당 픽셀 카운터 0..3
  reg [3:0]  beat_cnt = 4'd0;   // 버스트당 beat 카운터 0..15

  always @(posedge aclk or negedge aresetn)
  begin
    if (!aresetn)
    begin
      state    <= ST_IDLE;
      awvalid  <= 1'b0;
      wvalid   <= 1'b0;
      wlast    <= 1'b0;
      fifo_pop <= 1'b0;
      pix_cnt  <= 2'd0;
      beat_cnt <= 4'd0;
    end
    else
    begin
      fifo_pop <= 1'b0;

      case (state)

        // ── IDLE: 버스트 시작 대기 ─────────────────────────
        ST_IDLE:
        begin
          if (!fifo_empty)
          begin
            awaddr  <= base_addr + {11'd0, f_addr, 1'b0};  // pix_addr × 2
            awvalid <= 1'b1;
            pix_cnt  <= 2'd0;
            beat_cnt <= 4'd0;
            state   <= ST_AW;
          end
        end

        // ── AW: 주소 채널 핸드셰이크 ──────────────────────
        ST_AW:
        begin
          if (awvalid && awready)
          begin
            awvalid <= 1'b0;
            state   <= ST_PACK;
          end
        end

        // ── PACK: 픽셀 4개 → 64bit 패킹 ──────────────────
        ST_PACK:
        begin
          if (!fifo_empty)
          begin
            fifo_pop <= 1'b1;
            case (pix_cnt)
              2'd0:
                pack_buf[15:0]  <= {4'd0, f_pix};
              2'd1:
                pack_buf[31:16] <= {4'd0, f_pix};
              2'd2:
                pack_buf[47:32] <= {4'd0, f_pix};
              2'd3:
                pack_buf[63:48] <= {4'd0, f_pix};
            endcase
            if (pix_cnt == 2'd3)
            begin
              pix_cnt <= 2'd0;
              state   <= ST_W;
            end
            else
            begin
              pix_cnt <= pix_cnt + 2'd1;
            end
          end
        end

        // ── W: 데이터 beat 전송 ───────────────────────────
        ST_W:
        begin
          wdata  <= pack_buf;
          wvalid <= 1'b1;
          wlast  <= (beat_cnt == 4'd15);
          if (wvalid && wready)
          begin
            wvalid <= 1'b0;
            wlast  <= 1'b0;
            if (beat_cnt == 4'd15)
            begin
              beat_cnt <= 4'd0;
              state    <= ST_B;
            end
            else
            begin
              beat_cnt <= beat_cnt + 4'd1;
              state    <= ST_PACK;
            end
          end
        end

        // ── B: 쓰기 응답 대기 ─────────────────────────────
        ST_B:
        begin
          if (bvalid)
            state <= ST_IDLE;
        end

        default:
          state <= ST_IDLE;
      endcase
    end
  end

endmodule
