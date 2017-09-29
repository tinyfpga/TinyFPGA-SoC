/*
 * Wishbone compliant 6522 Versatile Interface Adapter model.
 *
 * https://en.wikipedia.org/wiki/MOS_Technology_6522
 * http://archive.6502.org/datasheets/mos_6522_preliminary_nov_1977.pdf
 * http://www.westerndesigncenter.com/wdc/documentation/w65c22.pdf
 */
module wb_6522_via #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 4
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [WB_ADDR_WIDTH-1:0]       adr_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    output reg                      ack_o,
    output reg [WB_DATA_WIDTH-1:0]  dat_o,

    // interrupt interface
    output                          irq,

    // gpio interface
    inout [WB_DATA_WIDTH-1:0]       port_a,
    inout [WB_DATA_WIDTH-1:0]       port_b,

    // handshake and serial io
    inout                           ca2,
    input                           ca1,
    inout                           cb2,
    inout                           cb1
);
    initial ack_o = 0;
    initial dat_o = 0;

    reg [WB_DATA_WIDTH-1:0] IORB_R = 0;
    reg [WB_DATA_WIDTH-1:0] IORB_W = 0;
    reg [WB_DATA_WIDTH-1:0] IORA_R = 0;
    reg [WB_DATA_WIDTH-1:0] IORA_W = 0;
    reg [WB_DATA_WIDTH-1:0] DDRB = 0;
    reg [WB_DATA_WIDTH-1:0] DDRA = 0;
    reg [WB_DATA_WIDTH-1:0] T1CL_R = 0;
    reg [WB_DATA_WIDTH-1:0] T1CL_W = 0;
    reg [WB_DATA_WIDTH-1:0] T1CH = 0;
    reg [WB_DATA_WIDTH-1:0] T1LL = 0;
    reg [WB_DATA_WIDTH-1:0] T1LH = 0;
    reg [WB_DATA_WIDTH-1:0] T2CL_R = 0;
    reg [WB_DATA_WIDTH-1:0] T2CL_W = 0;
    reg [WB_DATA_WIDTH-1:0] T2CH = 0;
    reg [WB_DATA_WIDTH-1:0] SR = 0;
    reg [WB_DATA_WIDTH-1:0] ACR = 0;
    reg [WB_DATA_WIDTH-1:0] PCR = 0;
    reg [WB_DATA_WIDTH-1:0] IFR = 0;
    reg [WB_DATA_WIDTH-1:0] IER = 0;
    reg [WB_DATA_WIDTH-1:0] IORANH_R = 0;
    reg [WB_DATA_WIDTH-1:0] IORANH_W = 0;

    wire valid_cmd = !rst_i && stb_i;
    wire valid_write_cmd = valid_cmd && we_i;
    wire valid_read_cmd = valid_cmd && !we_i;
   
    wire port_a_input_latching_enabled = 0; // FIXME: need to assign this a value
    wire latch_port_a = 0; // FIXME: need to assign this a value
    wire port_b_input_latching_enabled = 0; // FIXME: need to assign this a value
    wire latch_port_b = 0; // FIXME: need to assign this a value

    // handle wishbone interface 
    always @(posedge clk_i) begin
        // flop input data depending on input latch settings
        if ((port_a_input_latching_enabled && latch_port_a) || !port_a_input_latching_enabled) begin
            IORA_R <= port_a;
        end

        if ((port_b_input_latching_enabled && latch_port_b) || !port_b_input_latching_enabled) begin
            IORB_R <= port_b;
        end

        // register read path
        if (valid_read_cmd) begin
            case (adr_i)
                4'h0: dat_o <= IORB_R;
                4'h1: dat_o <= IORA_R;
                4'h2: dat_o <= DDRB;
                4'h3: dat_o <= DDRA;
                4'h4: dat_o <= T1CL_R;
                4'h5: dat_o <= T1CH;
                4'h6: dat_o <= T1LL;
                4'h7: dat_o <= T1LH;
                4'h8: dat_o <= T2CL_R;
                4'h9: dat_o <= T2CH;
                4'ha: dat_o <= SR;
                4'hb: dat_o <= ACR;
                4'hc: dat_o <= PCR;
                4'hd: dat_o <= IFR;
                4'he: dat_o <= IER;
                4'hf: dat_o <= IORANH_R;
            endcase
        end

        // register write path
        if (valid_write_cmd) begin
            case (adr_i)
                4'h0: IORB_W <= dat_i;
                4'h1: IORA_W <= dat_i;
                4'h2: DDRB <= dat_i;
                4'h3: DDRA <= dat_i;
                4'h4: T1CL_W <= dat_i;
                4'h5: T1CH <= dat_i;
                4'h6: T1LL <= dat_i;
                4'h7: T1LH <= dat_i;
                4'h8: T2CL_W <= dat_i;
                4'h9: T2CH <= dat_i;
                4'ha: SR <= dat_i;
                4'hb: ACR <= dat_i;
                4'hc: PCR <= dat_i;
                4'hd: IFR <= dat_i;
                4'he: IER <= dat_i;
                4'hf: IORANH_W <= dat_i;
            endcase
        end

        // acknowledge valid commands
        ack_o <= valid_cmd;
    end

    // handle gpios
    genvar i;
    generate  
        for (i = 0; i < WB_DATA_WIDTH; i = i + 1) begin
            // DDR[i] == 0 -> DDR[i] is an input pin
            // DDR[i] == 1 -> DDR[i] is an output pin
            assign port_a[i] = DDRA[i] ? IORA_W[i] : 1'bz;
            assign port_b[i] = DDRB[i] ? IORB_W[i] : 1'bz;
        end
    endgenerate
endmodule
