// Top-level sorting wrapper pipeline: Input FIFO -> Sorter Core -> Output FIFO.
module sorter_top
    import sorter_pkg::*;
#(
    parameter int DATA_W     = sorter_pkg::DATA_W,
    parameter int FIFO_DEPTH = sorter_pkg::FIFO_DEPTH,
    parameter int SORT_DEPTH = sorter_pkg::SORT_DEPTH
)(
    input  logic    clk,
    input  logic    rst_n,

    input  logic    wr_en,
    input  word_t   wr_data,
    output logic    full,

    input  logic    rd_en,
    output word_t   rd_data,
    output logic    empty,

    input  logic    last_in,
    output logic    busy
);

    logic   ififo_rd_en;
    word_t  ififo_rd_data;
    logic   ififo_empty;

    logic   ofifo_wr_en;
    word_t  ofifo_wr_data;
    logic   ofifo_full;

    fifo #(
        .WIDTH (DATA_W),
        .DEPTH (FIFO_DEPTH)
    ) input_fifo (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .full    (full),
        .rd_en   (ififo_rd_en),
        .rd_data (ififo_rd_data),
        .empty   (ififo_empty),
        .count   ()
    );

    sorter_if #(
        .DATA_W     (DATA_W),
        .SORT_DEPTH (SORT_DEPTH)
    ) core_if (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // NOTE: Temporary direct passthrough wiring for verification
    // before placing sorter cores.
    assign core_if.ready_in = !ififo_empty && !ofifo_full;
    assign ififo_rd_en      = core_if.ready_in && core_if.valid_in;

    assign core_if.valid_in = !ififo_empty;
    assign core_if.data_in  = ififo_rd_data;

    // Propagate last_in only after input FIFO drains to mark the final word of the stream.
    assign core_if.last_in  = last_in && ififo_empty;

    assign core_if.data_out  = core_if.data_in;
    assign core_if.valid_out = core_if.valid_in && core_if.ready_in;
    assign core_if.last_out  = core_if.last_in;
    assign core_if.busy      = 1'b0;

    assign ofifo_wr_en   = core_if.valid_out;
    assign ofifo_wr_data = core_if.data_out;
    assign busy          = core_if.busy;

    fifo #(
        .WIDTH (DATA_W),
        .DEPTH (FIFO_DEPTH)
    ) output_fifo (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (ofifo_wr_en),
        .wr_data (ofifo_wr_data),
        .full    (ofifo_full),
        .rd_en   (rd_en),
        .rd_data (rd_data),
        .empty   (empty),
        .count   ()
    );

endmodule : sorter_top
