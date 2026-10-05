// Common streaming handshake interface connecting sorter cores to wrapper FIFOs.
// Handshake rule: a transfer occurs on posedge clk only when valid and ready are asserted together.
interface sorter_if
    import sorter_pkg::*;
#(
    parameter int DATA_W     = sorter_pkg::DATA_W,
    parameter int SORT_DEPTH = sorter_pkg::SORT_DEPTH
)(
    input logic clk,
    input logic rst_n
);

    word_t data_in;
    logic  valid_in;
    logic  ready_in;
    logic  last_in;

    word_t data_out;
    logic  valid_out;
    logic  ready_out;
    logic  last_out;

    logic  busy;

    modport core (
        input  clk, rst_n,
        input  data_in, valid_in, last_in, ready_out,
        output ready_in, data_out, valid_out, last_out, busy
    );

    modport top (
        input  clk, rst_n,
        output data_in, valid_in, last_in, ready_out,
        input  ready_in, data_out, valid_out, last_out, busy
    );

endinterface : sorter_if
