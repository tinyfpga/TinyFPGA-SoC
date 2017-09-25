/*
 * Wishbone adapter for Arlet's 6502 core: https://github.com/Arlet/verilog-6502
 */
module wb_6502_bridge #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 16
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    output                          stb_o,
    output                          we_o,
    output [WB_ADDR_WIDTH-1:0]      adr_o,
    output [WB_DATA_WIDTH-1:0]      dat_o,

    input                           ack_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    // 6502 interface
    input [15:0]                    address_bus,
    output [7:0]                    read_bus,
    input [7:0]                     write_bus,
    input                           write_enable,
    output                          ready
);
    reg req_in_progress;

    wire stall = req_in_progress && !ack_i;
    wire req_initiated = !stall;

    // outputs to wb
    assign stb_o = req_initiated;
    assign we_o = write_enable;
    assign adr_o = address_bus;
    assign dat_o = write_bus;

    // outputs to 6502
    assign read_bus = dat_i;
    assign ready = req_initiated;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            req_in_progress <= 0;

        end else begin
            if (ack_i) begin
                req_in_progress <= 0;
            end

            if (req_initiated) begin
                req_in_progress <= 1;
            end
        end
    end
endmodule

module wb_6502_bridge_test;
    // wishbone interface
    reg         clk_i;
    reg         rst_i;

    wire        stb_o;
    wire        we_o;
    wire [15:0] adr_o;
    wire [7:0]  dat_o;

    reg         ack_i;
    reg  [7:0]  dat_i;

    // 6502 interface
    reg  [15:0] address_bus;
    wire [7:0]  read_bus;
    reg  [7:0]  write_bus;
    reg         write_enable;
    wire        ready;

    wb_6502_bridge dut(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .stb_o(stb_o),
        .we_o(we_o),
        .adr_o(adr_o),
        .dat_o(dat_o),
        .ack_i(ack_i),
        .dat_i(dat_i),
        .address_bus(address_bus),
        .read_bus(read_bus),
        .write_bus(write_bus),
        .write_enable(write_enable),
        .ready(ready)
    );

    task clk;
        begin
            @(posedge clk_i);
        end
    endtask

    task run_clk(input integer cycles);
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1) begin
                clk();
            end
        end
    endtask

    task reset;
        begin
            rst_i <= 1'b1;
            run_clk(10);
            rst_i <= 1'b0;
        end
    endtask
    
    initial begin
        $dumpvars;
        ack_i <= 0;
        reset();
        
        run_clk(10);

        ack_i <= 1;
        run_clk(10);

        ack_i <= 0;
        run_clk(1);

        ack_i <= 1;
        run_clk(10);

        $finish(1);
    end

    initial begin
        clk_i <= 0;
        #1;

        while (1) begin
            clk_i <= !clk_i;
            #100;
        end
    end
endmodule


