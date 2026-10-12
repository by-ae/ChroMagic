// savestate_psram.sv
//
// Stores one Game Boy savestate in the 8 MB PSRAM until power-off.
// The MiSTer core emits 64-bit beats on SAVE_out with dword addresses
// based at 58720256 (slot 0). A beat at address A lands at byte
// 0x700000 + ((A - 58720256) << 2). That window is 256 KB and ends at
// 0x740000, above the framebuffer (0x00000 / 0x10000) and the virtual
// cart ROM/save (0x020000 / 0x420000).
//
// The beat is four 16-bit PSRAM words on the virtual-cart master. The
// caller muxes that master while xactive is high. The core is paused
// for the transfer, so a physical cart is not reading PSRAM then.

module savestate_psram (
    input               hclk,
    input               hreset,
    input               ena,
    input               rnw,
    input       [25:0]  adr,
    input       [63:0]  din,
    output reg  [63:0]  dout,
    output reg          done,

    input               xclk,
    input               xreset,
    output reg          xrequest,
    output reg          xread,
    output reg  [22:0]  xaddress,
    output      [15:0]  xwritedata,
    output      [10:0]  xlength,
    input               xwrite_next,
    input               xdone,
    input               xread_valid,
    input       [15:0]  xreaddata,
    output reg          xactive
);

    localparam [22:0] STATE_BASE = 23'h700000;
    localparam [25:0] SLOT_BASE  = 26'd58720256;

    reg        h_req;
    reg [63:0] h_din;
    reg [25:0] h_adr;
    reg        h_rnw;
    reg        h_busy;
    reg        ack_sync1;
    reg        ack_sync2;
    reg        ack_seen;

    reg        x_ack;
    reg [63:0] x_cap_din;
    reg        x_cap_rnw;
    reg [63:0] x_dout;
    reg [1:0]  word;
    reg [1:0]  h_req_sync;
    reg        h_req_seen;

    localparam ST_IDLE = 1'b0;
    localparam ST_WAIT = 1'b1;
    reg        state;

    wire [25:0] beat_rel  = h_adr - SLOT_BASE;
    wire [22:0] beat_addr = STATE_BASE + {beat_rel[20:0], 2'b00};

    assign xlength = 11'd8;
    assign xwritedata = (word == 2'd0) ? x_cap_din[15:0] :
                        (word == 2'd1) ? x_cap_din[31:16] :
                        (word == 2'd2) ? x_cap_din[47:32] :
                                         x_cap_din[63:48];

    always @(posedge hclk) begin
        done <= 1'b0;
        if (hreset) begin
            h_req     <= 1'b0;
            h_busy    <= 1'b0;
            ack_sync1 <= 1'b0;
            ack_sync2 <= 1'b0;
            ack_seen  <= 1'b0;
        end else begin
            ack_sync1 <= x_ack;
            ack_sync2 <= ack_sync1;
            if (!h_busy && ena) begin
                h_busy <= 1'b1;
                h_din  <= din;
                h_adr  <= adr;
                h_rnw  <= rnw;
                h_req  <= ~h_req;
            end else if (h_busy && (ack_sync2 != ack_seen)) begin
                ack_seen <= ack_sync2;
                dout     <= x_dout;
                done     <= 1'b1;
                h_busy   <= 1'b0;
            end
        end
    end

    always @(posedge xclk) begin
        xrequest <= 1'b0;
        if (xreset) begin
            state      <= ST_IDLE;
            xactive    <= 1'b0;
            x_ack      <= 1'b0;
            word       <= 2'd0;
            h_req_sync <= 2'd0;
            h_req_seen <= 1'b0;
            xread      <= 1'b1;
            xaddress   <= 23'd0;
        end else begin
            h_req_sync <= {h_req_sync[0], h_req};
            case (state)
                ST_IDLE: begin
                    xactive <= 1'b0;
                    if (h_req_sync[1] != h_req_seen) begin
                        h_req_seen <= h_req_sync[1];
                        x_cap_din  <= h_din;
                        x_cap_rnw  <= h_rnw;
                        xaddress   <= beat_addr;
                        xread      <= h_rnw;
                        word       <= 2'd0;
                        xrequest   <= 1'b1;
                        xactive    <= 1'b1;
                        state      <= ST_WAIT;
                    end
                end
                ST_WAIT: begin
                    if (!x_cap_rnw && xwrite_next && (word != 2'd3))
                        word <= word + 2'd1;
                    if (x_cap_rnw && xread_valid) begin
                        case (word)
                            2'd0: x_dout[15:0]  <= xreaddata;
                            2'd1: x_dout[31:16] <= xreaddata;
                            2'd2: x_dout[47:32] <= xreaddata;
                            default: x_dout[63:48] <= xreaddata;
                        endcase
                        if (word != 2'd3)
                            word <= word + 2'd1;
                    end
                    if (xdone) begin
                        xactive <= 1'b0;
                        x_ack   <= ~x_ack;
                        state   <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
