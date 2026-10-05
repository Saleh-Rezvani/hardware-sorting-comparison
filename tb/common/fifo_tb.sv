// Directed and randomized testbench for synchronous FIFO boundary conditions.
interface fifo_tb_if (
    input logic clk,
    input logic rst_n
);
    localparam int WIDTH = 8;
    localparam int DEPTH = 4; // Small depth forces fast boundary and wrap-around coverage.

    logic                      wr_en;
    logic [WIDTH-1:0]          wr_data;
    logic                      full;
    logic                      rd_en;
    logic [WIDTH-1:0]          rd_data;
    logic                      empty;
    logic [$clog2(DEPTH+1)-1:0] count;
endinterface : fifo_tb_if

module fifo_tb;
    import sorter_pkg::*;

    localparam int WIDTH      = 8;
    localparam int DEPTH      = 4;
    localparam int CLK_PERIOD = 10;

    logic clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    logic rst_n = 0;

    fifo_tb_if tb_if (.clk(clk), .rst_n(rst_n));

    int pass_count = 0;
    int fail_count = 0;
    int test_count = 0;

    logic [WIDTH-1:0] ref_queue [$];

    fifo #(
        .WIDTH (WIDTH),
        .DEPTH (DEPTH)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (tb_if.wr_en),
        .wr_data (tb_if.wr_data),
        .full    (tb_if.full),
        .rd_en   (tb_if.rd_en),
        .rd_data (tb_if.rd_data),
        .empty   (tb_if.empty),
        .count   (tb_if.count)
    );

    task automatic generator(input int num_random_tests);
        $display("\n--- Test: Fill to full ---");
        for (int i = 0; i < DEPTH; i++) begin
            driver(8'(i + 1));
        end
        monitor_flags(1'b1, 1'b0, DEPTH[$clog2(DEPTH+1)-1:0], "After filling");

        $display("\n--- Test: Overflow guard ---");
        // Overflow attempt must be dropped without corrupting existing FIFO entries.
        driver(8'hFF);
        monitor_flags(1'b1, 1'b0, DEPTH[$clog2(DEPTH+1)-1:0], "After overflow attempt");

        $display("\n--- Test: Drain to empty ---");
        for (int i = 0; i < DEPTH; i++) begin
            logic [WIDTH-1:0] expected;
            expected = 8'(i + 1);
            read_and_check(expected);
        end
        monitor_flags(1'b0, 1'b1, '0, "After draining");

        $display("\n--- Test: Underflow guard ---");
        // Underflow attempt must not wrap counter or advance read pointer.
        begin
            @(posedge clk);
            tb_if.rd_en = 1'b1;
            @(posedge clk);
            tb_if.rd_en = 1'b0;
            @(posedge clk);
            monitor_flags(1'b0, 1'b1, '0, "After underflow attempt");
        end

        $display("\n--- Test: Random write/read (%0d iterations) ---", num_random_tests);
        ref_queue.delete();
        for (int i = 0; i < num_random_tests; i++) begin
            logic [WIDTH-1:0] wdata;
            int action;
            wdata  = $urandom;
            action = $urandom_range(0, 2);

            case (action)
                0: begin
                    if (ref_queue.size() < DEPTH) begin
                        driver(wdata);
                        ref_queue.push_back(wdata);
                    end
                end
                1: begin
                    if (ref_queue.size() > 0) begin
                        logic [WIDTH-1:0] expected;
                        expected = ref_queue.pop_front();
                        read_and_check(expected);
                    end
                end
                2: begin
                    if (ref_queue.size() < DEPTH && ref_queue.size() > 0) begin
                        logic [WIDTH-1:0] expected;
                        logic [WIDTH-1:0] observed;
                        expected = ref_queue.pop_front();
                        @(posedge clk);
                        // Sample combinational rd_data before pulsing rd_en; rd_en advances rd_ptr synchronously.
                        observed = tb_if.rd_data;
                        tb_if.wr_en   = 1'b1;
                        tb_if.wr_data = wdata;
                        tb_if.rd_en   = 1'b1;
                        @(posedge clk);
                        tb_if.wr_en   = 1'b0;
                        tb_if.rd_en   = 1'b0;
                        ref_queue.push_back(wdata);
                        checkResults(observed, expected, "Simultaneous R/W");
                    end
                end
            endcase
        end

        $display("\n========================================");
        $display("=== RESULTS: %0d passed, %0d failed out of %0d ===",
                  pass_count, fail_count, test_count);
        $display("========================================");
        $finish;
    endtask : generator

    task automatic driver(input logic [WIDTH-1:0] data);
        @(posedge clk);
        tb_if.wr_en   = 1'b1;
        tb_if.wr_data = data;
        @(posedge clk);
        tb_if.wr_en   = 1'b0;
    endtask : driver

    task automatic read_and_check(input logic [WIDTH-1:0] expected);
        logic [WIDTH-1:0] observed;
        @(posedge clk);
        observed = tb_if.rd_data;
        tb_if.rd_en = 1'b1;
        @(posedge clk);
        tb_if.rd_en = 1'b0;
        checkResults(observed, expected, "Read data");
    endtask : read_and_check

    task automatic monitor(
        input logic                        exp_full,
        input logic                        exp_empty,
        input logic [$clog2(DEPTH+1)-1:0] exp_count,
        input string                       context_msg
    );
        @(posedge clk);
        checkResults_flags(tb_if.full, exp_full, tb_if.empty, exp_empty,
                           tb_if.count, exp_count, context_msg);
    endtask : monitor

    task automatic monitor_flags(
        input logic                        exp_full,
        input logic                        exp_empty,
        input logic [$clog2(DEPTH+1)-1:0] exp_count,
        input string                       context_msg
    );
        monitor(exp_full, exp_empty, exp_count, context_msg);
    endtask : monitor_flags

    task automatic checkResults(
        input logic [WIDTH-1:0] observed,
        input logic [WIDTH-1:0] expected,
        input string            context_msg
    );
        test_count++;
        if (observed === expected) begin
            pass_count++;
        end else begin
            fail_count++;
            $display("[FAIL] %s: expected=%0h, got=%0h (test %0d)",
                     context_msg, expected, observed, test_count);
        end
    endtask : checkResults

    task automatic checkResults_flags(
        input logic                        obs_full,
        input logic                        exp_full,
        input logic                        obs_empty,
        input logic                        exp_empty,
        input logic [$clog2(DEPTH+1)-1:0] obs_count,
        input logic [$clog2(DEPTH+1)-1:0] exp_count,
        input string                       context_msg
    );
        test_count++;
        if (obs_full === exp_full && obs_empty === exp_empty && obs_count === exp_count) begin
            pass_count++;
        end else begin
            fail_count++;
            $display("[FAIL] %s: full=%b(exp %b), empty=%b(exp %b), count=%0d(exp %0d) (test %0d)",
                     context_msg, obs_full, exp_full, obs_empty, exp_empty,
                     obs_count, exp_count, test_count);
        end
    endtask : checkResults_flags

    initial begin
        tb_if.wr_en   = 1'b0;
        tb_if.rd_en   = 1'b0;
        tb_if.wr_data = '0;

        rst_n = 0;
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD);

        generator(200);
    end

endmodule : fifo_tb
