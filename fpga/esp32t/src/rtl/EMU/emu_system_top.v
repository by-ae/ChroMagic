// emu_system_top.v

module emu_system_top
(
    input               hclk,
    input               pclk,
    input               xclk,
    input               reset_n,
    input               xreset,
    input               ss_save_toggle,
    input               ss_load_toggle,
    input               POWER_GOOD,
    input               maintenance_reset_h,
    input               virtual_attempt_reset_h,
    input               virtual_quiesce_h,
    output              virtual_quiesced_h,
    output              virtual_core_reset_h,
    
    input               customPaletteEna,
    input [63:0]        paletteBGIn,
    input [63:0]        paletteOBJ0In,
    input [63:0]        paletteOBJ1In,
    input               paletteOff,
    output              gbc_mode,
    output [63:0]       gpd,
    
    input               BTN_NODIAGONAL,
    input               BTN_A,
    input               BTN_B,
    input               BTN_DPAD_DOWN,
    input               BTN_DPAD_LEFT,
    input               BTN_DPAD_RIGHT,
    input               BTN_DPAD_UP,
    input               BTN_MENU,
    input               BTN_SEL,
    input               BTN_START,
    input               MENU_CLOSED,
    output              boot_rom_enabled,
    output  [15:0]      CART_A,
    output              CART_CLK,
    output              CART_CS,
    input   [7:0]       CART_D_IN,
    output  [7:0]       CART_D_OUT,
    output              CART_D_OE,
    output              CART_RD,
    inout               CART_RST,
    output              CART_WR,

    input               virtual_enable,
    input   [2:0]       virtual_mapper_select,
    input               virtual_mbc1m,
    input               virtual_mbc30,
    input   [7:0]       virtual_cart_type,
    input               virtual_has_ram,
    input   [3:0]       virtual_ram_mask,
    input   [8:0]       virtual_rom_mask,
    input  [32:0]       virtual_rtc_time,
    input               virtual_rtc_restore_write,
    input   [2:0]       virtual_rtc_restore_address,
    input  [15:0]       virtual_rtc_restore_data,
    output [28:0]       virtual_rtc_state,
    output              virtual_initialized,
    output              virtual_save_dirty,
    output              virtual_xrequest,
    output              virtual_xread,
    output [22:0]       virtual_xaddress,
    output [15:0]       virtual_xwritedata,
    output [10:0]       virtual_xlength,
    input               virtual_xwrite_next,
    input               virtual_xdone,
    input               virtual_xread_valid,
    input  [15:0]       virtual_xreaddata,
    input               virtual_snapshot_request_toggle,
    input   [6:0]       virtual_snapshot_block,
    input   [15:0]      virtual_snapshot_sequence,
    output              virtual_snapshot_ready,
    output  [15:0]      virtual_snapshot_ready_sequence,
    input               virtual_snapshot_qclk,
    input   [9:0]       virtual_snapshot_qaddress,
    output  [7:0]       virtual_snapshot_qdata,

    input               IR_RX,
    output              IR_LED,

    inout               LINK_CLK,
    input               LINK_IN,
    output              LINK_OUT,

    output [15:0]       left,
    output [15:0]       right,

    output lcd_on_int,
    output lcd_off_overwrite,
    
    input               LCD_INIT_DONE,
    output              gb_lcd_clkena,
    output [14:0]       gb_lcd_data,
    output [1:0]        gb_lcd_mode,
    output              gb_lcd_on,
    output              gb_lcd_vsync
    
);

    parameter SRSIZE = 15;

    reg [SRSIZE-1:0] BTN_DPAD_DOWN_sr;
    reg [SRSIZE-1:0] BTN_DPAD_UP_sr;
    reg [SRSIZE-1:0] BTN_DPAD_LEFT_sr;
    reg [SRSIZE-1:0] BTN_DPAD_RIGHT_sr;

    reg [SRSIZE-1:0] BTN_START_sr;
    reg [SRSIZE-1:0] BTN_SEL_sr;
    reg [SRSIZE-1:0] BTN_B_sr;
    reg [SRSIZE-1:0] BTN_A_sr;

    reg BTN_DPAD_DOWN_filtered;
    reg BTN_DPAD_UP_filtered;
    reg BTN_DPAD_LEFT_filtered;
    reg BTN_DPAD_RIGHT_filtered;
    reg BTN_START_filtered;
    reg BTN_SEL_filtered;
    reg BTN_B_filtered;
    reg BTN_A_filtered;
    
    reg BTN_DPAD_DOWN_filtered_dir;
    reg BTN_DPAD_UP_filtered_dir;
    reg BTN_DPAD_LEFT_filtered_dir;
    reg BTN_DPAD_RIGHT_filtered_dir;

    always@(posedge pclk)
    begin
        BTN_DPAD_DOWN_sr <= {BTN_DPAD_DOWN_sr[SRSIZE-2:0], BTN_DPAD_DOWN&~BTN_MENU&MENU_CLOSED};
        BTN_DPAD_UP_sr <= {BTN_DPAD_UP_sr[SRSIZE-2:0], BTN_DPAD_UP&~BTN_MENU&MENU_CLOSED};
        BTN_DPAD_LEFT_sr <= {BTN_DPAD_LEFT_sr[SRSIZE-2:0], BTN_DPAD_LEFT&~BTN_MENU&MENU_CLOSED};
        BTN_DPAD_RIGHT_sr <= {BTN_DPAD_RIGHT_sr[SRSIZE-2:0], BTN_DPAD_RIGHT&~BTN_MENU&MENU_CLOSED};
        BTN_START_sr <= {BTN_START_sr [SRSIZE-2:0], BTN_START&~BTN_MENU&MENU_CLOSED};
        BTN_SEL_sr <= {BTN_SEL_sr [SRSIZE-2:0], BTN_SEL&~BTN_MENU&MENU_CLOSED};
        BTN_A_sr <= {BTN_A_sr [SRSIZE-2:0], BTN_A&~BTN_MENU&MENU_CLOSED};
        BTN_B_sr <= {BTN_B_sr [SRSIZE-2:0], BTN_B&~BTN_MENU&MENU_CLOSED};

        BTN_DPAD_DOWN_filtered <= &BTN_DPAD_DOWN_sr[SRSIZE-1:1];
        BTN_DPAD_UP_filtered <= &BTN_DPAD_UP_sr[SRSIZE-1:1];
        BTN_DPAD_LEFT_filtered <= &BTN_DPAD_LEFT_sr[SRSIZE-1:1];
        BTN_DPAD_RIGHT_filtered <= &BTN_DPAD_RIGHT_sr[SRSIZE-1:1];
        BTN_START_filtered <= &BTN_START_sr[SRSIZE-1:1];
        BTN_SEL_filtered <= &BTN_SEL_sr[SRSIZE-1:1];
        BTN_A_filtered <= &BTN_A_sr[SRSIZE-1:1];
        BTN_B_filtered <= &BTN_B_sr[SRSIZE-1:1];
        
        if (BTN_NODIAGONAL) begin
            BTN_DPAD_DOWN_filtered_dir  <= BTN_DPAD_DOWN_filtered  & ~BTN_DPAD_UP_filtered & ~BTN_DPAD_LEFT_filtered_dir & ~BTN_DPAD_RIGHT_filtered_dir;
            BTN_DPAD_UP_filtered_dir    <= BTN_DPAD_UP_filtered    & ~BTN_DPAD_DOWN_filtered & ~BTN_DPAD_LEFT_filtered_dir & ~BTN_DPAD_RIGHT_filtered_dir;
            BTN_DPAD_LEFT_filtered_dir  <= BTN_DPAD_LEFT_filtered  & ~BTN_DPAD_RIGHT_filtered & ~BTN_DPAD_UP_filtered_dir & ~BTN_DPAD_DOWN_filtered_dir;
            BTN_DPAD_RIGHT_filtered_dir <= BTN_DPAD_RIGHT_filtered & ~BTN_DPAD_LEFT_filtered & ~BTN_DPAD_UP_filtered_dir & ~BTN_DPAD_DOWN_filtered_dir;
        end else begin
            BTN_DPAD_DOWN_filtered_dir  <= BTN_DPAD_DOWN_filtered  & ~BTN_DPAD_UP_filtered;
            BTN_DPAD_UP_filtered_dir    <= BTN_DPAD_UP_filtered    & ~BTN_DPAD_DOWN_filtered;
            BTN_DPAD_LEFT_filtered_dir  <= BTN_DPAD_LEFT_filtered  & ~BTN_DPAD_RIGHT_filtered;
            BTN_DPAD_RIGHT_filtered_dir <= BTN_DPAD_RIGHT_filtered & ~BTN_DPAD_LEFT_filtered;
        end
        
    end

    wire [3:0] btn_key = {
        BTN_DPAD_DOWN_filtered_dir, 
        BTN_DPAD_UP_filtered_dir,
        BTN_DPAD_LEFT_filtered_dir, 
        BTN_DPAD_RIGHT_filtered_dir
    }; 
     
    wire [3:0] dpad_key = {
        BTN_START_filtered,
        BTN_SEL_filtered,
        BTN_B_filtered,
        BTN_A_filtered
    };

    reg [3:0] joy_din;
    wire [1:0] joy_p54;
    always@(posedge hclk)
    begin
        case(joy_p54)
            2'b00: joy_din <= (~btn_key) & (~dpad_key); 
            2'b01: joy_din <= ~dpad_key;
            2'b10: joy_din <= ~btn_key; 
            2'b11: joy_din <= 4'hF;
        endcase
    end

    wire wr;
    wire rd;
    wire [7:0] CART_DOUT;
    wire nCS;

    wire cpu_speed;
    wire cpu_halt;
    wire cpu_stop;
    
    wire [7:0] CART_DIN_r1;
    wire [15:0] a;
    wire [2:0] TSTATEo;
    wire sleep_savestate;

    speedcontrol u_speedcontrol
    (
        .clk_sys     (hclk),
        .pause       (sleep_savestate),
        .speedup     (),
        .cart_act    (rd | wr),
        .DMA_on      (),
        .ce          (ce),
        .ce_2x       (ce_2x),
        .refresh     (),
        .ff_on       ()
    );

    wire sel_cram = a[15:13] == 3'b101;           // 8k cart ram at $a000
    wire cart_oe = (rd & ~a[15]) | (sel_cram & rd);

    assign CART_RST = 1'bZ;

    reg gbreset;
    reg gbreset_ungated;
    reg CART_RST_r1;
    reg CART_RST_r2;
    reg ce_2x_r1;
    always@(posedge hclk)
        ce_2x_r1 <= ce_2x;
        
    always@(posedge hclk or negedge reset_n)
    begin
        if(~reset_n)
        begin
            gbreset <= 1'd1;
            gbreset_ungated <= 1'd1;
        end
        else
        begin
            CART_RST_r1 <= CART_RST;
            CART_RST_r2 <= CART_RST_r1;
            gbreset_ungated <= ~LCD_INIT_DONE ? 1'b1 :
                              (~CART_RST_r2 && !virtual_enable);
            if(~ce_2x_r1 & ce_2x & ce)
                gbreset <= gbreset_ungated;
                
            if (MENU_CLOSED & BTN_MENU & BTN_A & BTN_B & BTN_START & BTN_SEL) gbreset <= 1'd1;
            
            if (~POWER_GOOD) gbreset <= 1'b1;
        end
    end
    
    wire DMA_on;
    wire hdma_active;
    reg virtual_enable_d;
    reg [3:0] virtual_mode_reset_hold;
    always @(posedge hclk or negedge reset_n) begin
        if (!reset_n) begin
            virtual_enable_d <= 1'b0;
            virtual_mode_reset_hold <= 4'd0;
        end else begin
            virtual_enable_d <= virtual_enable;
            if (virtual_enable != virtual_enable_d)
                virtual_mode_reset_hold <= 4'hf;
            else if (virtual_mode_reset_hold != 0)
                virtual_mode_reset_hold <= virtual_mode_reset_hold - 1'b1;
        end
    end
    wire virtual_mode_reset = virtual_mode_reset_hold != 0;
    wire gbreset_effective = gbreset | maintenance_reset_h |
        virtual_attempt_reset_h |
        virtual_mode_reset | (virtual_enable && !virtual_initialized);
    assign virtual_core_reset_h = gbreset_effective;
    cart u_cart
    (
       .hclk            (hclk           ),
       .pclk            (pclk           ),
       .ce              (ce             ),
       .ce_2x           (ce_2x          ),
       .gbreset         (gbreset_effective),
       .cpu_speed       (cpu_speed      ),
       .cpu_halt        (cpu_halt       ),
       .cpu_stop        (cpu_stop       ),
       .wr              (wr             ),
       .rd              (rd             ),
       .a               (a              ),
       .CART_DOUT       (CART_DOUT      ),
       .nCS             (nCS            ),
       .TSTATEo         (TSTATEo        ),
       .DMA_on          (DMA_on         ),
       .hdma_active     (hdma_active    ),
                                        
       .CART_A          (CART_A         ),
       .CART_CLK        (CART_CLK       ),
       .CART_CS         (CART_CS        ),
       .CART_D_IN       (CART_D_IN      ),
       .CART_D_OUT_PHY  (CART_D_OUT     ),
       .CART_D_OE       (CART_D_OE      ),
       .CART_RD         (CART_RD        ),
       .CART_WR         (CART_WR        ),
       .CART_DIN_r1     (CART_DIN_r1    )
    );

    wire sc_int_clock2;
    wire serial_clk_in;
    wire serial_clk_out;
    wire serial_data_out;
    
    reg LINK_IN_r1;
    reg LINK_CLK_r1;
    reg serial_clk_out_r1;
    reg sc_int_clock2_r1;
    reg serial_data_out_r1;
    always@(posedge hclk)
    begin
        LINK_IN_r1         <= LINK_IN;
        LINK_CLK_r1        <= LINK_CLK;
        serial_clk_out_r1  <= serial_clk_out;
        sc_int_clock2_r1   <= sc_int_clock2;
        serial_data_out_r1 <= serial_data_out;
    end

    assign LINK_CLK = sc_int_clock2_r1 ? serial_clk_out_r1 : 1'bZ;
    assign serial_clk_in = LINK_CLK_r1;

    wire serial_data_in = LINK_IN_r1;
    assign LINK_OUT = serial_data_out_r1;

    wire [63:0] SAVE_out_Din  ;
    wire [63:0] SAVE_out_Dout ;
    wire [25:0] SAVE_out_Adr  ;
    wire SAVE_out_rnw  ;                    
    wire SAVE_out_ena  ;                                    
    wire SAVE_out_done ; 
    
    reg ss_load = 1'b0;
    reg gbreset_1 = 1'b0;
    
    // synthesis translate_off
    always@(posedge hclk)
    begin
      gbreset_1 <= gbreset;
      ss_load   <= 1'b0;
      if (gbreset_1 && ~gbreset) ss_load <= 1'b1;
    end
    // synthesis translate_on

    reg [1:0] ss_save_sync;
    reg [1:0] ss_load_sync;
    reg ss_save_level;
    reg ss_load_level;
    always @(posedge hclk) begin
        if (!reset_n) begin
            ss_save_sync  <= 2'd0;
            ss_load_sync  <= 2'd0;
            ss_save_level <= 1'b0;
            ss_load_level <= 1'b0;
        end else begin
            ss_save_sync  <= {ss_save_sync[0], ss_save_toggle};
            ss_load_sync  <= {ss_load_sync[0], ss_load_toggle};
            ss_save_level <= ss_save_sync[1];
            ss_load_level <= ss_load_sync[1];
        end
    end
    wire ss_save_pulse = ss_save_sync[1] ^ ss_save_level;
    wire ss_load_pulse = ss_load_sync[1] ^ ss_load_level;

    wire        vc_xrequest;
    wire        vc_xread;
    wire [22:0] vc_xaddress;
    wire [15:0] vc_xwritedata;
    wire [10:0] vc_xlength;
    wire        ss_xrequest;
    wire        ss_xread;
    wire [22:0] ss_xaddress;
    wire [15:0] ss_xwritedata;
    wire [10:0] ss_xlength;
    wire        ss_xactive;

    assign virtual_xrequest   = ss_xactive ? ss_xrequest   : vc_xrequest;
    assign virtual_xread      = ss_xactive ? ss_xread      : vc_xread;
    assign virtual_xaddress   = ss_xactive ? ss_xaddress   : vc_xaddress;
    assign virtual_xwritedata = ss_xactive ? ss_xwritedata : vc_xwritedata;
    assign virtual_xlength    = ss_xactive ? ss_xlength    : vc_xlength;

    wire ss_xwrite_next = ss_xactive & virtual_xwrite_next;
    wire ss_xdone       = ss_xactive & virtual_xdone;
    wire ss_xread_valid = ss_xactive & virtual_xread_valid;
    wire vc_xwrite_next = ~ss_xactive & virtual_xwrite_next;
    wire vc_xdone       = ~ss_xactive & virtual_xdone;
    wire vc_xread_valid = ~ss_xactive & virtual_xread_valid;

    savestate_psram u_savestate_psram (
        .hclk        (hclk),
        .hreset      (~reset_n),
        .ena         (SAVE_out_ena),
        .rnw         (SAVE_out_rnw),
        .adr         (SAVE_out_Adr),
        .din         (SAVE_out_Din),
        .dout        (SAVE_out_Dout),
        .done        (SAVE_out_done),
        .xclk        (xclk),
        .xreset      (xreset),
        .xrequest    (ss_xrequest),
        .xread       (ss_xread),
        .xaddress    (ss_xaddress),
        .xwritedata  (ss_xwritedata),
        .xlength     (ss_xlength),
        .xwrite_next (ss_xwrite_next),
        .xdone       (ss_xdone),
        .xread_valid (ss_xread_valid),
        .xreaddata   (virtual_xreaddata),
        .xactive     (ss_xactive)
    );

    wire [15:0] snd_l;  
    wire [15:0] snd_r;  

    wire [7:0] virtual_cart_do;
    wire virtual_cart_oe;
    wire virtual_cart_wait;
    wire cart_wr_pulse;
    wire [31:0] virtual_rtc_timestamp;
    wire [47:0] virtual_rtc_saved_time;
    wire virtual_rtc_in_use;
    wire core_ce_cpu = cpu_speed ? ce_2x : ce;

    virtual_cart_runtime u_virtual_cart_runtime (
        .hclk(hclk),
        .xclk(xclk),
        .hreset(~reset_n),
        .xreset(xreset),
        .enable(virtual_enable),
        .quiesced(virtual_quiesced_h),
        .mapper_select(virtual_mapper_select),
        .mbc1m(virtual_mbc1m),
        .mbc30(virtual_mbc30),
        .cart_mbc_type(virtual_cart_type),
        .has_ram(virtual_has_ram),
        .ram_mask(virtual_ram_mask),
        .rom_mask(virtual_rom_mask),
        .rtc_time(virtual_rtc_time),
        .rtc_restore_write(virtual_rtc_restore_write),
        .rtc_restore_address(virtual_rtc_restore_address),
        .rtc_restore_data(virtual_rtc_restore_data),
        .ce_cpu(core_ce_cpu),
        .cart_addr(a[14:0]),
        .cart_a15(a[15]),
        .cart_rd(rd),
        .cart_wr_cycle(wr),
        .cart_wr_pulse(cart_wr_pulse),
        .cart_di(CART_DOUT),
        .nCS(nCS),
        .cart_do(virtual_cart_do),
        .cart_oe(virtual_cart_oe),
        .cart_wait(virtual_cart_wait),
        .initialized(virtual_initialized),
        .save_dirty(virtual_save_dirty),
        .xrequest(vc_xrequest),
        .xread(vc_xread),
        .xaddress(vc_xaddress),
        .xwritedata(vc_xwritedata),
        .xlength(vc_xlength),
        .xwrite_next(vc_xwrite_next),
        .xdone(vc_xdone),
        .xread_valid(vc_xread_valid),
        .xreaddata(virtual_xreaddata),
        .xsnapshot_request_toggle(virtual_snapshot_request_toggle),
        .xsnapshot_block(virtual_snapshot_block),
        .xsnapshot_sequence(virtual_snapshot_sequence),
        .xsnapshot_ready(virtual_snapshot_ready),
        .xsnapshot_ready_sequence(virtual_snapshot_ready_sequence),
        .qclk(virtual_snapshot_qclk),
        .qsnapshot_address(virtual_snapshot_qaddress),
        .qsnapshot_data(virtual_snapshot_qdata),
        .rtc_timestamp(virtual_rtc_timestamp),
        .rtc_saved_time(virtual_rtc_saved_time),
        .rtc_in_use(virtual_rtc_in_use)
    );

    assign virtual_rtc_state = virtual_rtc_saved_time[28:0];

    wire [7:0] selected_cart_do = virtual_enable
        ? virtual_cart_do : CART_DIN_r1;
    wire selected_cart_oe = virtual_enable ? virtual_cart_oe : cart_oe;

    gb u_gb(
        .reset(gbreset_effective),
        .clk_sys(hclk),
        .ce(ce),
        .ce_2x(ce_2x),

        .isGBC(1'd1),
        .real_cgb_boot(1'd0),
        .customPaletteEna(customPaletteEna),
        .paletteBGIn(paletteBGIn),
        .paletteOBJ0In(paletteOBJ0In),
        .paletteOBJ1In(paletteOBJ1In),

        .paletteOff(paletteOff),
        .gbc_mode(gbc_mode),
        .gpd(gpd),

        // cartridge interface
        // can adress up to 1MB ROM
        .ext_bus_addr(a[14:0]),
        .ext_bus_a15(a[15]),
        .cart_rd(rd),
        .cart_wr(wr),
        .cart_wr_pulse(cart_wr_pulse),
        .cart_do(selected_cart_do),
        .cart_di(CART_DOUT),
        .cart_oe(selected_cart_oe),
        .cart_wait(virtual_enable && virtual_cart_wait),
        .virtual_cart_mode(virtual_enable),
        .virtual_quiesce(virtual_quiesce_h),
        .virtual_quiesced(virtual_quiesced_h),
        .TSTATEo(TSTATEo),
        .TSTATE1(TSTATE1),
        .TSTATE2(TSTATE2),
        .TSTATE3(TSTATE3),
        .TSTATE4(TSTATE4),
        // WRAM or Cart RAM CS
        .nCS(nCS),

        .cgb_boot_download(1'd0),
        .dmg_boot_download(1'd0),
        .ioctl_wr(1'd0),
        .ioctl_addr(25'd0),
        .ioctl_dout(16'd0),

        // Bootrom features
        .boot_rom_enabled(boot_rom_enabled),

        .boot_gba_en(1'd0),
        .fast_boot_en(1'd0),
        // audio
        .audio_l(snd_l),
        .audio_r(snd_r),

        // Megaduck?
        .megaduck(1'd0),

        .IR_RX(IR_RX),
        .IR_LED(IR_LED),

        // lcd interface
        .lcd_clkena(gb_lcd_clkena),
        .lcd_data(gb_lcd_data),
        //      .lcd_data_gb(),
        .lcd_mode(gb_lcd_mode),
        .lcd_on(gb_lcd_on),
        .lcd_vsync(gb_lcd_vsync),

        .joy_p54(joy_p54),
        .joy_din(joy_din),

        .lcd_on_int(lcd_on_int),
        .lcd_off_overwrite(lcd_off_overwrite),

        .speed(cpu_speed),   //GBC
        .cpu_stop(cpu_stop),
        .cpu_halt(cpu_halt),
        .DMA_on(DMA_on),
        .hdma_active(hdma_active),
        .gg_reset(1'd0),
        .gg_en(1'd0),
        .gg_code(129'd0),
        .gg_available(),

        //serial port
        .sc_int_clock2(sc_int_clock2),
        .serial_clk_in(serial_clk_in),
        .serial_clk_out(serial_clk_out),
        .serial_data_in(serial_data_in),
        .serial_data_out(serial_data_out),

        // savestates
        .increaseSSHeaderCount(1'd0),
        .cart_ram_size(8'd0),
        .save_state(ss_save_pulse),
        .load_state(ss_load | ss_load_pulse),
        .savestate_number(2'd0),
        .sleep_savestate(sleep_savestate),

        .SaveStateExt_Din(), 
        .SaveStateExt_Adr(), 
        .SaveStateExt_wren(),
        .SaveStateExt_rst(), 
        .SaveStateExt_Dout(64'd0),
        .SaveStateExt_load(),

        .Savestate_CRAMAddr(),     
        .Savestate_CRAMRWrEn(),    
        .Savestate_CRAMWriteData(),
        .Savestate_CRAMReadData(8'd0),

        .SAVE_out_Din  (SAVE_out_Din ),    // data read from savestate
        .SAVE_out_Dout (SAVE_out_Dout),  // data written to savestate
        .SAVE_out_Adr  (SAVE_out_Adr ),    // all addresses are DWORD addresses!
        .SAVE_out_rnw  (SAVE_out_rnw ),     // read = 1, write = 0
        .SAVE_out_ena  (SAVE_out_ena ),     // one cycle high for each action
        .SAVE_out_done (SAVE_out_done),    // should be one cycle high when write is done or read value is valid

        .rewind_on(1'd0),
        .rewind_active(1'd0)
    );
    
    audio_filter_deterministic u_audio_filter
    (
       .reset    (~reset_n),
       .clk      (hclk),

       .core_l   (snd_l),
       .core_r   (snd_r),

       .filter_l (left),
       .filter_r (right)
    );
    
// synthesis translate_off
   wire DDRAM_CLK            ;
   wire DDRAM_BUSY           ;
   wire [7:0]  DDRAM_BURSTCNT;
   wire [28:0] DDRAM_ADDR    ;
   wire [63:0] DDRAM_DOUT    ;
   wire DDRAM_DOUT_READY     ;
   wire DDRAM_RD             ;
   wire [63:0] DDRAM_DIN     ;   
   wire [7:0]  DDRAM_BE      ;   
   wire DDRAM_WE             ;

   wire [27:1] ch1_addr;         
   wire [63:0] ch1_dout;         
   wire [63:0] ch1_din ;         
   wire [7:0]  ch1_be  ;         
   wire ch1_req        ;  
   wire ch1_rnw        ;  
   wire ch1_ready      ;  
    
   ddram iddram
   (
      .DDRAM_CLK        (hclk),      
      .DDRAM_BUSY       (DDRAM_BUSY),      
      .DDRAM_BURSTCNT   (DDRAM_BURSTCNT),  
      .DDRAM_ADDR       (DDRAM_ADDR),      
      .DDRAM_DOUT       (DDRAM_DOUT),      
      .DDRAM_DOUT_READY (DDRAM_DOUT_READY),
      .DDRAM_RD         (DDRAM_RD),        
      .DDRAM_DIN        (DDRAM_DIN),       
      .DDRAM_BE         (DDRAM_BE),        
      .DDRAM_WE         (DDRAM_WE),                
                
      .ch1_addr         (ch1_addr),        
      .ch1_dout         (ch1_dout),        
      .ch1_din          (ch1_din),  
      .ch1_be           (ch1_be),      
      .ch1_req          (ch1_req),         
      .ch1_rnw          (ch1_rnw),         
      .ch1_ready        (ch1_ready)
   );
   
   assign ch1_addr      = { SAVE_out_Adr[25:0], 1'b0 };
   assign ch1_din       = SAVE_out_Din;
   assign ch1_req       = SAVE_out_ena;
   assign ch1_rnw       = SAVE_out_rnw;
   assign ch1_be        = 8'hFF; // only required for increaseSSHeaderCount
   
   ddrram_model iddrram_model
   (
      .DDRAM_CLK        (hclk),      
      .DDRAM_BUSY       (DDRAM_BUSY),      
      .DDRAM_BURSTCNT   (DDRAM_BURSTCNT),  
      .DDRAM_ADDR       (DDRAM_ADDR),      
      .DDRAM_DOUT       (DDRAM_DOUT),      
      .DDRAM_DOUT_READY (DDRAM_DOUT_READY),
      .DDRAM_RD         (DDRAM_RD),        
      .DDRAM_DIN        (DDRAM_DIN),       
      .DDRAM_BE         (DDRAM_BE),        
      .DDRAM_WE         (DDRAM_WE)       
   );
// synthesis translate_on
    
endmodule
