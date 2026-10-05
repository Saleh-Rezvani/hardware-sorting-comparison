// Global types and sizing defaults across sorter cores and wrappers.
package sorter_pkg;

    parameter int DATA_W     = 8;
    parameter int FIFO_DEPTH = 16;
    parameter int SORT_DEPTH = 8;

    typedef logic signed [DATA_W-1:0] word_t;

endpackage : sorter_pkg
