/*
 * Wishbone compliant bus with support for one master and multiple slaves. 
 */  
module wb_bus #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 16,
    parameter WB_NUM_SLAVES = 1
) (
    // syscon
    input                                       clk_i,
    input                                       rst_i,

    // connection to wishbone master
    input                                       mstr_cyc_i,
    input                                       mstr_lock_i,
    input                                       mstr_stb_i,
    input                                       mstr_we_i,
    input  [WB_ADDR_WIDTH-1:0]                  mstr_adr_i,
    input  [WB_DATA_WIDTH-1:0]                  mstr_dat_i,

    output                                      mstr_stall_o,
    output                                      mstr_ack_o,
    output [WB_DATA_WIDTH-1:0]                  mstr_dat_o,

    // wishbone slave decode
    input [(WB_ADDR_WIDTH*WB_NUM_SLAVES)-1:0]   bus_slv_addr_decode_value,
    input [(WB_ADDR_WIDTH*WB_NUM_SLAVES)-1:0]   bus_slv_addr_decode_mask,

    // connection to wishbone slaves
    output [WB_NUM_SLAVES-1:0]                  slv_cyc_o,
    output [WB_NUM_SLAVES-1:0]                  slv_lock_o,
    output [WB_NUM_SLAVES-1:0]                  slv_stb_o,
    output [WB_NUM_SLAVES-1:0]                  slv_we_o,
    output [(WB_ADDR_WIDTH*WB_NUM_SLAVES)-1:0]  slv_adr_o,
    output [(WB_DATA_WIDTH*WB_NUM_SLAVES)-1:0]  slv_dat_o,

    input  [WB_NUM_SLAVES-1:0]                  slv_stall_i,
    input  [WB_NUM_SLAVES-1:0]                  slv_ack_i,
    input  [(WB_DATA_WIDTH*WB_NUM_SLAVES)-1:0]  slv_dat_i
);
    wor mstr_stall_o_wor;
    wor mstr_ack_o_wor;
    wor [WB_DATA_WIDTH-1:0] mstr_dat_o_wor;

    assign mstr_stall_o = mstr_stall_o_wor;
    assign mstr_ack_o = mstr_ack_o_wor;
    assign mstr_dat_o = mstr_dat_o_wor;

    wire [WB_NUM_SLAVES-1:0] req_slv_select;
    reg  [WB_NUM_SLAVES-1:0] ack_slv_select;

    always @(posedge clk_i) begin
        ack_slv_select <= req_slv_select;
    end

    genvar i;
    generate
        for (i = 0; i < WB_NUM_SLAVES; i = i + 1) begin
            // decode slave addresses
            assign req_slv_select[i] = 
                (bus_slv_addr_decode_value[i * WB_ADDR_WIDTH +: WB_ADDR_WIDTH]) == 
                (bus_slv_addr_decode_mask [i * WB_ADDR_WIDTH +: WB_ADDR_WIDTH] & mstr_adr_i);

            // drive slave signals
            assign slv_cyc_o[i] = mstr_cyc_i;
            assign slv_lock_o[i] = mstr_lock_i;
            assign slv_stb_o[i] = mstr_stb_i & req_slv_select[i];
            assign slv_we_o[i] = mstr_we_i;
            assign slv_adr_o[i * WB_ADDR_WIDTH +: WB_ADDR_WIDTH] = mstr_adr_i;
            assign slv_dat_o[i * WB_DATA_WIDTH +: WB_DATA_WIDTH] = mstr_dat_i;

            // drive master wor signals
            assign mstr_stall_o_wor = ack_slv_select[i] ? slv_stall_i[i] : 0;
            assign mstr_ack_o_wor = ack_slv_select[i] ? slv_ack_i[i] : 0;
            assign mstr_dat_o_wor = ack_slv_select[i] ? slv_dat_i[i * WB_DATA_WIDTH +: WB_DATA_WIDTH] : 0;
        end
    endgenerate
endmodule

