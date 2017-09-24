/*
 * Simple Wishbone compliant RAM module.
 */
module wb_ram #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 9,
    parameter WB_ALWAYS_READ = 1,
    parameter RAM_DEPTH = 512
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [WB_ADDR_WIDTH-1:0]       adr_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    output reg                      ack_o,
    output reg [WB_DATA_WIDTH-1:0]  dat_o
);
    reg [WB_DATA_WIDTH-1:0] ram [RAM_DEPTH-1:0];

    wire valid_cmd = !rst_i && stb_i;
    wire valid_write_cmd = valid_cmd && we_i;
    wire valid_read_cmd = valid_cmd && !we_i;

    always @(posedge clk_i) begin
        if (valid_read_cmd || WB_ALWAYS_READ) begin
            dat_o <= ram[adr_i];
        end

        if (valid_write_cmd) begin
            ram[adr_i] <= dat_i;
        end

        ack_o <= valid_cmd;
    end
endmodule
