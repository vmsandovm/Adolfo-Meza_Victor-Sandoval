package mdrs_tester_pkg;
    import MDRS_pkg::*;
    import mdrs_ref_model_pkg::*;

    class mdrs_tester #(parameter int DW = 10);
        virtual mdrs_if #(DW) vif;
        mdrs_ref_model #(DW) model;

        int pass    [4];
        int fail    [4];
        string name [4] = '{"MULT", "DIV", "SQRT", "SQUARE"};

        function new(virtual mdrs_if #(DW) vif);
            this.vif = vif;
            model    = new();
            foreach (pass[i]) begin pass[i] = 0; fail[i] = 0; end
        endfunction

        task reset();
            vif.rst = 1'b0; vif.load = 1'b0; vif.data = '0; vif.operation = '0;
            repeat (3) @(negedge vif.clk);
            vif.rst = 1'b1;
        endtask

        //un load: op y data con load en alto durante un ciclo
        local task send(input logic [1:0] op, input int value);
            vif.data = value[DW-1:0]; vif.operation = op; vif.load = 1'b1;
            @(negedge vif.clk);
            vif.load = 1'b0;
        endtask

        //protocolo completo: X con load, Y con load si hace falta, espera ready y revisa
        local task run_op(input logic [1:0] op, input int x, input int y);
            mdrs_expected_t e;
            e = model.predict(op, x, y);

            while (!(vif.ready && vif.loadX)) @(negedge vif.clk);
            send(op, x);
            if (op == OP_MULT || op == OP_DIV) begin
                if (!vif.loadY || vif.ready) $display("PROTOCOLO: loadY=%b ready=%b esperando Y", vif.loadY, vif.ready);
                send(op, y);
            end
            while (!vif.ready) @(negedge vif.clk);

            if (model.check(e, vif.result, vif.remainder, vif.error)) begin
                pass[op]++;
                $display("OK    %-6s x=%0d y=%0d -> r=%0d rem=%0d e=%b",
                         name[op], x, y, $signed(vif.result), $signed(vif.remainder), vif.error);
            end
            else begin
                fail[op]++;
                $display("FALLA %-6s x=%0d y=%0d -> r=%0d rem=%0d e=%b (esperado r=%0d rem=%0d e=%b)",
                         name[op], x, y, $signed(vif.result), $signed(vif.remainder), vif.error,
                         e.result, e.remainder, e.error);
            end
        endtask

        task mult  (input int x, input int y); run_op(OP_MULT,   x, y); endtask
        task div   (input int x, input int y); run_op(OP_DIV,    x, y); endtask
        task sqrt  (input int x);              run_op(OP_SQRT,   x, 0); endtask
        task square(input int x);              run_op(OP_SQUARE, x, 0); endtask

        function void summary();
            foreach (pass[i])
                $display("%-6s PASS %0d  FAIL %0d", name[i], pass[i], fail[i]);
        endfunction
    endclass
endpackage
