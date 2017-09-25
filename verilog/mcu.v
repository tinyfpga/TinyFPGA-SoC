

module mcu (
    input clock,
    input reset,

    inout [7:0] porta,
    inout [7:0] portb
);
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Arlet 6502 Core
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    // 6502 cpu interface
    wire [15:0] address_bus; 
    wire [7:0] read_bus;    
    wire [7:0] write_bus;  
    wire write_enable;    
    wire irq = 1'b0;            
    wire nmi = 1'b0;           
    wire ready;        

    cpu cpu_inst (
        .clk(clock),
        .reset(reset),
        .AB(address_bus),
        .DI(read_bus),
        .DO(write_bus),
        .WE(write_enable),
        .IRQ(irq),
        .NMI(nmi),
        .RDY(ready)
    );

    // 6502 wishbone interface
    wire cpu_stb_o;
    wire cpu_we_o;
    wire [15:0] cpu_adr_o;
    wire [7:0] cpu_dat_o;
    wire cpu_ack_i;
    wire [7:0] cpu_dat_i;
    
    wb_6502_bridge wb_6502_bridge_inst (
        .clk_i(clock),
        .rst_i(reset),
        .stb_o(cpu_stb_o),
        .we_o(cpu_we_o),
        .adr_o(cpu_adr_o),
        .dat_o(cpu_dat_o),
        .ack_i(cpu_ack_i),
        .dat_i(cpu_dat_i),
        .address_bus(address_bus),
        .read_bus(read_bus),
        .write_bus(write_bus),
        .write_enable(write_enable),
        .ready(ready)
    );



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// RAM
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire ram_stb_i;
    wire ram_we_i;
    wire [15:0] ram_adr_i;
    wire [7:0] ram_dat_i;
    wire ram_ack_o;
    wire [7:0] ram_dat_o;

    wb_ram #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(9),
        .WB_ALWAYS_READ(1),
        .RAM_DEPTH(512)
    ) main_ram (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(ram_stb_i),
        .we_i(ram_we_i),
        .adr_i(ram_adr_i),
        .dat_i(ram_dat_i),
        .ack_o(ram_ack_o),
        .dat_o(ram_dat_o)
    );

    integer i;
    initial begin 
        for (i = 0; i < 512; i = i + 1) begin 
            main_ram.ram[i] = 0; 
        end
    end



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// ROM
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire rom_stb_i;
    wire rom_we_i;
    wire [15:0] rom_adr_i;
    wire [7:0] rom_dat_i;
    wire rom_ack_o;
    wire [7:0] rom_dat_o;

    wb_ram #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(9),
        .WB_ALWAYS_READ(1),
        .RAM_DEPTH(512)
    ) main_rom (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(rom_stb_i),
        .we_i(rom_we_i),
        .adr_i(rom_adr_i),
        .dat_i(rom_dat_i),
        .ack_o(rom_ack_o),
        .dat_o(rom_dat_o)
    );

    integer j;
    initial begin 
        for (j = 0; j < 512; j = j + 1) begin 
            main_rom.ram[j] = 0; 
        end

        main_rom.ram[0] = 8'ha9; 
        main_rom.ram[1] = 8'hff; 
        main_rom.ram[2] = 8'h8d;
        main_rom.ram[3] = 8'h00; 
        main_rom.ram[4] = 8'hf0; 
        main_rom.ram[5] = 8'ha9; 
        main_rom.ram[6] = 8'h01; 
        main_rom.ram[7] = 8'hee; 
        main_rom.ram[8] = 8'h02; 
        main_rom.ram[9] = 8'hf0; 
        main_rom.ram[10] = 8'h4c; // JMP
        main_rom.ram[11] = 8'h07;
        main_rom.ram[12] = 8'hfe;

        main_rom.ram[9'h1fe] = 8'h00;
        main_rom.ram[9'h1ff] = 8'hfe;
    end



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// PORTA
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire porta_stb_i;
    wire porta_we_i;
    wire [15:0] porta_adr_i;
    wire [7:0] porta_dat_i;
    wire porta_ack_o;
    wire [7:0] porta_dat_o;

    wb_gpio #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(2)
    ) porta_inst (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(porta_stb_i),
        .we_i(porta_we_i),
        .adr_i(porta_adr_i),
        .dat_i(porta_dat_i),
        .ack_o(porta_ack_o),
        .dat_o(porta_dat_o),
        .gpio(porta)
    );



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// PORTB
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wire portb_stb_i;
    wire portb_we_i;
    wire [15:0] portb_adr_i;
    wire [7:0] portb_dat_i;
    wire portb_ack_o;
    wire [7:0] portb_dat_o;

    wb_gpio #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(2)
    ) portb_inst (
        .clk_i(clock),
        .rst_i(reset),
        .stb_i(portb_stb_i),
        .we_i(portb_we_i),
        .adr_i(portb_adr_i),
        .dat_i(portb_dat_i),
        .ack_o(portb_ack_o),
        .dat_o(portb_dat_o),
        .gpio(portb)
    );



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Wishbone Bus
    ///
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    wb_bus #(
        .WB_DATA_WIDTH(8),
        .WB_ADDR_WIDTH(16),
        .WB_NUM_SLAVES(4)
    ) bus (
        // syscon
        .clk_i(clock),
        .rst_i(reset),

        // connection to wishbone master
        .mstr_stb_i(cpu_stb_o),
        .mstr_we_i(cpu_we_o),
        .mstr_adr_i(cpu_adr_o),
        .mstr_dat_i(cpu_dat_o),
        .mstr_ack_o(cpu_ack_i),
        .mstr_dat_o(cpu_dat_i),

        // wishbone slave decode         RAM         ROM       PORTA         PORTB
        .bus_slv_addr_decode_value({16'h0000,   16'hFE00,   16'hF000,     16'hF004}),
        .bus_slv_addr_decode_mask ({16'hFE00,   16'hFE00,   16'hFFFC,     16'hFFFC}),

        // connection to wishbone slaves
        .slv_stb_o                ({ram_stb_i,  rom_stb_i,  porta_stb_i,  portb_stb_i}),
        .slv_we_o                 ({ram_we_i,   rom_we_i,   porta_we_i,   portb_we_i}),
        .slv_adr_o                ({ram_adr_i,  rom_adr_i,  porta_adr_i,  portb_adr_i}),
        .slv_dat_o                ({ram_dat_i,  rom_dat_i,  porta_dat_i,  portb_dat_i}),
        .slv_ack_i                ({ram_ack_o,  rom_ack_o,  porta_ack_o,  portb_ack_o}),
        .slv_dat_i                ({ram_dat_o,  rom_dat_o,  porta_dat_o,  portb_dat_o})
    );
endmodule

module mcu_test;
    reg clock;
    reg reset;
    wire [7:0] porta;
    wire [7:0] portb;

    mcu dut(
        .clock(clock),
        .reset(reset),
        .porta(porta),
        .portb(portb)
    );

    initial begin
        clock <= 0;
        #100;

        while (1) begin
            clock <= !clock;
            #100;
        end
    end

    initial begin
        reset <= 1;

        #1000;

        reset <= 0;
    end

    initial begin
        $dumpvars;
    end
endmodule
