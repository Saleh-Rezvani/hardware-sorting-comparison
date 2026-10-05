// Synchronous circular FIFO with combinational read and parameterized depth.
module fifo
    import sorter_pkg::*;
#(
    parameter int WIDTH = DATA_W,
    parameter int DEPTH = FIFO_DEPTH
)(
    input  logic                      clk,
    input  logic                      rst_n,

    input  logic                      wr_en,
    input  logic [WIDTH-1:0]          wr_data,
    output logic                      full,

    input  logic                      rd_en,
    output logic [WIDTH-1:0]          rd_data,
    output logic                      empty,

    output logic [$clog2(DEPTH+1)-1:0] count
);

    logic [WIDTH-1:0] mem [DEPTH];

    localparam int PTR_W = $clog2(DEPTH);
    logic [PTR_W-1:0] wr_ptr;
    logic [PTR_W-1:0] rd_ptr;

    logic [$clog2(DEPTH+1)-1:0] count_r;

    assign count = count_r;
    assign full  = (count_r == DEPTH[$clog2(DEPTH+1)-1:0]);
    assign empty = (count_r == '0);

    // Combinational read
    assign rd_data = mem[rd_ptr];

    // Explicit compare at DEPTH-1 ensures correct wrap when DEPTH is not a power of 2.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
            wr_ptr      <= (wr_ptr == PTR_W'(DEPTH - 1)) ? '0 : wr_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr <= (rd_ptr == PTR_W'(DEPTH - 1)) ? '0 : rd_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_r <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10:   count_r <= count_r + 1'b1;
                2'b01:   count_r <= count_r - 1'b1;
                default: count_r <= count_r;
            endcase
        end
    end

endmodule : fifo
