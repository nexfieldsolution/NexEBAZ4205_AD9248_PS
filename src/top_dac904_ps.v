`timescale 1ns / 1ps

module top_dac904_ps (
    // PS7 DDR
    inout  [14:0]   DDR_addr,
    inout  [2:0]    DDR_ba,
    inout           DDR_cas_n,
    inout           DDR_ck_n,
    inout           DDR_ck_p,
    inout           DDR_cke,
    inout           DDR_cs_n,
    inout  [3:0]    DDR_dm,
    inout  [31:0]   DDR_dq,
    inout  [3:0]    DDR_dqs_n,
    inout  [3:0]    DDR_dqs_p,
    inout           DDR_odt,
    inout           DDR_ras_n,
    inout           DDR_reset_n,
    inout           DDR_we_n,
    // PS7 FIXED_IO
    inout           FIXED_IO_ddr_vrn,
    inout           FIXED_IO_ddr_vrp,
    inout  [53:0]   FIXED_IO_mio,
    inout           FIXED_IO_ps_clk,
    inout           FIXED_IO_ps_porb,
    inout           FIXED_IO_ps_srstb,

    // HDMI output (TMDS) - 향후 파형 표시
    output          HDMI_CLK_N,
    output          HDMI_CLK_P,
    output [2:0]    HDMI_N,
    output [2:0]    HDMI_P,

    // DAC904 interface
    output          dac_clk,
    output [13:0]   dac_data
);

    wire FCLK_CLK0;

    // ----------------------------------------------------------------
    // AXI HP0 wires (tie-off)
    // ----------------------------------------------------------------
    wire [31:0] hp0_awaddr;  wire [5:0] hp0_awid;   wire [3:0] hp0_awlen;
    wire [2:0]  hp0_awsize;  wire [1:0] hp0_awburst; wire [1:0] hp0_awlock;
    wire [3:0]  hp0_awcache; wire [2:0] hp0_awprot;  wire [3:0] hp0_awqos;
    wire        hp0_awvalid; wire       hp0_awready;
    wire [63:0] hp0_wdata;   wire [5:0] hp0_wid;     wire [7:0] hp0_wstrb;
    wire        hp0_wlast;   wire       hp0_wvalid;   wire       hp0_wready;
    wire [5:0]  hp0_bid;     wire [1:0] hp0_bresp;    wire       hp0_bvalid;
    wire        hp0_bready;
    wire [31:0] hp0_araddr;  wire [5:0] hp0_arid;    wire [3:0] hp0_arlen;
    wire [2:0]  hp0_arsize;  wire [1:0] hp0_arburst;  wire [1:0] hp0_arlock;
    wire [3:0]  hp0_arcache; wire [2:0] hp0_arprot;   wire [3:0] hp0_arqos;
    wire        hp0_arvalid; wire       hp0_arready;
    wire [63:0] hp0_rdata;   wire [5:0] hp0_rid;      wire [1:0] hp0_rresp;
    wire        hp0_rlast;   wire       hp0_rvalid;    wire       hp0_rready;

    // ----------------------------------------------------------------
    // AXI HP1 wires (tie-off)
    // ----------------------------------------------------------------
    wire [31:0] hp1_awaddr;  wire [5:0] hp1_awid;   wire [3:0] hp1_awlen;
    wire [2:0]  hp1_awsize;  wire [1:0] hp1_awburst; wire [1:0] hp1_awlock;
    wire [3:0]  hp1_awcache; wire [2:0] hp1_awprot;  wire [3:0] hp1_awqos;
    wire        hp1_awvalid; wire       hp1_awready;
    wire [63:0] hp1_wdata;   wire [5:0] hp1_wid;     wire [7:0] hp1_wstrb;
    wire        hp1_wlast;   wire       hp1_wvalid;   wire       hp1_wready;
    wire [5:0]  hp1_bid;     wire [1:0] hp1_bresp;    wire       hp1_bvalid;
    wire        hp1_bready;
    wire [31:0] hp1_araddr;  wire [5:0] hp1_arid;    wire [3:0] hp1_arlen;
    wire [2:0]  hp1_arsize;  wire [1:0] hp1_arburst;  wire [1:0] hp1_arlock;
    wire [3:0]  hp1_arcache; wire [2:0] hp1_arprot;   wire [3:0] hp1_arqos;
    wire        hp1_arvalid; wire       hp1_arready;
    wire [63:0] hp1_rdata;   wire [5:0] hp1_rid;      wire [1:0] hp1_rresp;
    wire        hp1_rlast;   wire       hp1_rvalid;    wire       hp1_rready;

    assign hp0_awvalid = 1'b0;  assign hp0_awaddr  = 32'd0;
    assign hp0_awid    = 6'd0;  assign hp0_awlen   = 4'd0;
    assign hp0_awsize  = 3'd0;  assign hp0_awburst = 2'd0;
    assign hp0_awlock  = 2'd0;  assign hp0_awcache = 4'd0;
    assign hp0_awprot  = 3'd0;  assign hp0_awqos   = 4'd0;
    assign hp0_wvalid  = 1'b0;  assign hp0_wdata   = 64'd0;
    assign hp0_wid     = 6'd0;  assign hp0_wstrb   = 8'd0;
    assign hp0_wlast   = 1'b0;  assign hp0_bready  = 1'b1;
    assign hp0_arvalid = 1'b0;  assign hp0_araddr  = 32'd0;
    assign hp0_arid    = 6'd0;  assign hp0_arlen   = 4'd0;
    assign hp0_arsize  = 3'd0;  assign hp0_arburst = 2'd0;
    assign hp0_arlock  = 2'd0;  assign hp0_arcache = 4'd0;
    assign hp0_arprot  = 3'd0;  assign hp0_arqos   = 4'd0;
    assign hp0_rready  = 1'b1;

    assign hp1_awvalid = 1'b0;  assign hp1_awaddr  = 32'd0;
    assign hp1_awid    = 6'd0;  assign hp1_awlen   = 4'd0;
    assign hp1_awsize  = 3'd0;  assign hp1_awburst = 2'd0;
    assign hp1_awlock  = 2'd0;  assign hp1_awcache = 4'd0;
    assign hp1_awprot  = 3'd0;  assign hp1_awqos   = 4'd0;
    assign hp1_wvalid  = 1'b0;  assign hp1_wdata   = 64'd0;
    assign hp1_wid     = 6'd0;  assign hp1_wstrb   = 8'd0;
    assign hp1_wlast   = 1'b0;  assign hp1_bready  = 1'b1;
    assign hp1_arvalid = 1'b0;  assign hp1_araddr  = 32'd0;
    assign hp1_arid    = 6'd0;  assign hp1_arlen   = 4'd0;
    assign hp1_arsize  = 3'd0;  assign hp1_arburst = 2'd0;
    assign hp1_arlock  = 2'd0;  assign hp1_arcache = 4'd0;
    assign hp1_arprot  = 3'd0;  assign hp1_arqos   = 4'd0;
    assign hp1_rready  = 1'b1;

    // ----------------------------------------------------------------
    // PS7 block design instance
    // ----------------------------------------------------------------
    design_1_wrapper u_ps7 (
        .DDR_addr           (DDR_addr),
        .DDR_ba             (DDR_ba),
        .DDR_cas_n          (DDR_cas_n),
        .DDR_ck_n           (DDR_ck_n),
        .DDR_ck_p           (DDR_ck_p),
        .DDR_cke            (DDR_cke),
        .DDR_cs_n           (DDR_cs_n),
        .DDR_dm             (DDR_dm),
        .DDR_dq             (DDR_dq),
        .DDR_dqs_n          (DDR_dqs_n),
        .DDR_dqs_p          (DDR_dqs_p),
        .DDR_odt            (DDR_odt),
        .DDR_ras_n          (DDR_ras_n),
        .DDR_reset_n        (DDR_reset_n),
        .DDR_we_n           (DDR_we_n),
        .FIXED_IO_ddr_vrn   (FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp   (FIXED_IO_ddr_vrp),
        .FIXED_IO_mio       (FIXED_IO_mio),
        .FIXED_IO_ps_clk    (FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb   (FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb  (FIXED_IO_ps_srstb),
        .FCLK_CLK0          (FCLK_CLK0),
        // AXI HP0
        .S_AXI_HP0_0_awaddr  (hp0_awaddr),  .S_AXI_HP0_0_awid    (hp0_awid),
        .S_AXI_HP0_0_awlen   (hp0_awlen),   .S_AXI_HP0_0_awsize  (hp0_awsize),
        .S_AXI_HP0_0_awburst (hp0_awburst), .S_AXI_HP0_0_awlock  (hp0_awlock),
        .S_AXI_HP0_0_awcache (hp0_awcache), .S_AXI_HP0_0_awprot  (hp0_awprot),
        .S_AXI_HP0_0_awqos   (hp0_awqos),   .S_AXI_HP0_0_awvalid (hp0_awvalid),
        .S_AXI_HP0_0_awready (hp0_awready),
        .S_AXI_HP0_0_wdata   (hp0_wdata),   .S_AXI_HP0_0_wid     (hp0_wid),
        .S_AXI_HP0_0_wstrb   (hp0_wstrb),   .S_AXI_HP0_0_wlast   (hp0_wlast),
        .S_AXI_HP0_0_wvalid  (hp0_wvalid),  .S_AXI_HP0_0_wready  (hp0_wready),
        .S_AXI_HP0_0_bid     (hp0_bid),     .S_AXI_HP0_0_bresp   (hp0_bresp),
        .S_AXI_HP0_0_bvalid  (hp0_bvalid),  .S_AXI_HP0_0_bready  (hp0_bready),
        .S_AXI_HP0_0_araddr  (hp0_araddr),  .S_AXI_HP0_0_arid    (hp0_arid),
        .S_AXI_HP0_0_arlen   (hp0_arlen),   .S_AXI_HP0_0_arsize  (hp0_arsize),
        .S_AXI_HP0_0_arburst (hp0_arburst), .S_AXI_HP0_0_arlock  (hp0_arlock),
        .S_AXI_HP0_0_arcache (hp0_arcache), .S_AXI_HP0_0_arprot  (hp0_arprot),
        .S_AXI_HP0_0_arqos   (hp0_arqos),   .S_AXI_HP0_0_arvalid (hp0_arvalid),
        .S_AXI_HP0_0_arready (hp0_arready),
        .S_AXI_HP0_0_rdata   (hp0_rdata),   .S_AXI_HP0_0_rid     (hp0_rid),
        .S_AXI_HP0_0_rresp   (hp0_rresp),   .S_AXI_HP0_0_rlast   (hp0_rlast),
        .S_AXI_HP0_0_rvalid  (hp0_rvalid),  .S_AXI_HP0_0_rready  (hp0_rready),
        // AXI HP1
        .S_AXI_HP1_0_awaddr  (hp1_awaddr),  .S_AXI_HP1_0_awid    (hp1_awid),
        .S_AXI_HP1_0_awlen   (hp1_awlen),   .S_AXI_HP1_0_awsize  (hp1_awsize),
        .S_AXI_HP1_0_awburst (hp1_awburst), .S_AXI_HP1_0_awlock  (hp1_awlock),
        .S_AXI_HP1_0_awcache (hp1_awcache), .S_AXI_HP1_0_awprot  (hp1_awprot),
        .S_AXI_HP1_0_awqos   (hp1_awqos),   .S_AXI_HP1_0_awvalid (hp1_awvalid),
        .S_AXI_HP1_0_awready (hp1_awready),
        .S_AXI_HP1_0_wdata   (hp1_wdata),   .S_AXI_HP1_0_wid     (hp1_wid),
        .S_AXI_HP1_0_wstrb   (hp1_wstrb),   .S_AXI_HP1_0_wlast   (hp1_wlast),
        .S_AXI_HP1_0_wvalid  (hp1_wvalid),  .S_AXI_HP1_0_wready  (hp1_wready),
        .S_AXI_HP1_0_bid     (hp1_bid),     .S_AXI_HP1_0_bresp   (hp1_bresp),
        .S_AXI_HP1_0_bvalid  (hp1_bvalid),  .S_AXI_HP1_0_bready  (hp1_bready),
        .S_AXI_HP1_0_araddr  (hp1_araddr),  .S_AXI_HP1_0_arid    (hp1_arid),
        .S_AXI_HP1_0_arlen   (hp1_arlen),   .S_AXI_HP1_0_arsize  (hp1_arsize),
        .S_AXI_HP1_0_arburst (hp1_arburst), .S_AXI_HP1_0_arlock  (hp1_arlock),
        .S_AXI_HP1_0_arcache (hp1_arcache), .S_AXI_HP1_0_arprot  (hp1_arprot),
        .S_AXI_HP1_0_arqos   (hp1_arqos),   .S_AXI_HP1_0_arvalid (hp1_arvalid),
        .S_AXI_HP1_0_arready (hp1_arready),
        .S_AXI_HP1_0_rdata   (hp1_rdata),   .S_AXI_HP1_0_rid     (hp1_rid),
        .S_AXI_HP1_0_rresp   (hp1_rresp),   .S_AXI_HP1_0_rlast   (hp1_rlast),
        .S_AXI_HP1_0_rvalid  (hp1_rvalid),  .S_AXI_HP1_0_rready  (hp1_rready)
    );

    // ── 클럭 생성: FCLK_CLK0(50MHz) → 74.25MHz(HDMI) + 25MHz ────
    wire clk_74m25;
    wire clk_25;

    clocking u_clocking (
        .CLK_50   (FCLK_CLK0),
        .CLK_74M25(clk_74m25),
        .CLK_25   (clk_25)
    );

    // ── DAC904: DDS 모듈 구현 전 placeholder ─────────────────────
    // dac_clk: 50MHz (FCLK_CLK0) → 향후 MMCM 출력으로 교체
    assign dac_clk  = FCLK_CLK0;
    assign dac_data = 14'd0;

    // ── HDMI: 향후 파형 표시 (현재 blank 출력) ───────────────────
    rgb2dvi #(
        .kClkPrimitive ("MMCM"),
        .kClkRange     (2)
    ) u_rgb2dvi (
        .PixelClk    (clk_74m25),
        .TMDS_Clk_n  (HDMI_CLK_N),
        .TMDS_Clk_p  (HDMI_CLK_P),
        .TMDS_Data_n (HDMI_N),
        .TMDS_Data_p (HDMI_P),
        .aRst        (1'b0),
        .vid_pData   (24'd0),
        .vid_pHSync  (1'b0),
        .vid_pVDE    (1'b0),
        .vid_pVSync  (1'b0)
    );

endmodule
