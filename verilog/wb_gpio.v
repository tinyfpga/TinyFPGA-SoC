/*
 * Wishbone compliant GPIO port similiar to AVR ports.
 */
module wb_gpio #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 2
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

    // gpio interface
    inout [WB_DATA_WIDTH-1:0]       gpio
);
    reg [WB_DATA_WIDTH-1:0] data_direction_register;
    reg [WB_DATA_WIDTH-1:0] input_data_register;
    reg [WB_DATA_WIDTH-1:0] output_data_register;

    wire valid_cmd = !rst_i && stb_i;
    wire valid_write_cmd = valid_cmd && we_i;
    wire valid_read_cmd = valid_cmd && !we_i;
   
    // handle wishbone interface 
    always @(posedge clk_i) begin
        // always flop input data
        input_data_register <= gpio;

        // register read path
        if (valid_read_cmd) begin
            case (adr_i)
                0: begin
                    dat_o <= data_direction_register;
                end

                1: begin
                    dat_o <= input_data_register;
                end

                2: begin
                    dat_o <= output_data_register;
                end
            endcase
        end

        // register write path
        if (valid_write_cmd) begin
            case (adr_i)
                0: begin
                    data_direction_register <= dat_i;
                end

                2: begin
                    output_data_register <= dat_i;
                end
            endcase
        end

        // acknowledge valid commands
        ack_o <= valid_cmd;
    end

    // handle gpio
    genvar i;
    generate  
        for (i = 0; i < WB_DATA_WIDTH; i = i + 1) begin
            assign gpio = data_direction_register[i] ? 1'bz : output_data_register[i];
        end
    endgenerate
endmodule
