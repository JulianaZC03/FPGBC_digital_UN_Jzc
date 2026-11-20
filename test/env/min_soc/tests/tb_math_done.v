`timescale 1ns/1ps
module tb_math_done;
    reg clk=0, reset=1, rd=0, wr=0;
    reg [2:0] cs=0;
    reg [4:0] addr=0;
    reg [19:0] data=0;
    wire [31:0] b2b, bcd, root;
    wire [31:0] dout=cs[0] ? b2b : cs[1] ? bcd : root;
    peripheral_bin2bcd a(clk,reset,data[15:0],cs[0],addr,rd,wr,b2b);
    peripheral_bcd2bin b(clk,reset,data,cs[1],addr,rd,wr,bcd);
    peripheral_sqrt c(clk,reset,data[15:0],cs[2],addr,rd,wr,root);
    always #12.5 clk=~clk;
    task write_reg;
        input [4:0] offset;
        input [19:0] value;
        begin
            @(negedge clk); #1; addr=offset; data=value; wr=1; rd=0;
            @(negedge clk); #1; wr=0;
        end
    endtask
    task calculate;
        input [2:0] select;
        input [19:0] value;
        input [31:0] expected;
        input integer held_cycles;
        begin
            cs=select;
            write_reg(5'h04,value);
            write_reg(5'h0c,1);
            // Mantener INIT alto muchos más ciclos que la operación.
            repeat(held_cycles) @(negedge clk);
            write_reg(5'h0c,0);
            if(held_cycles==0) begin
                // El nuevo inicio debe borrar DONE, no devolver el resultado anterior.
                #1; addr=5'h14; rd=1;
                repeat(3) @(negedge clk);
                #1;
                if(dout!==0) $fatal(1,"DONE no se borra al reiniciar");
                rd=0;
            end
            repeat(300) @(negedge clk);
            #1; addr=5'h14; rd=1;
            @(negedge clk); #1;
            if(dout!==1) $fatal(1,"DONE no persiste: cs=%b estado=%h",cs,dout);
            addr=5'h10;
            @(negedge clk); #1;
            if(dout!==expected) $fatal(1,"Resultado no persiste: cs=%b dato=%h esperado=%h",
                                       cs,dout,expected);
            rd=0; cs=0;
        end
    endtask
    initial begin
        repeat(4) @(negedge clk);
        #1; reset=0;
        calculate(3'b001,42,32'h42,300);
        calculate(3'b001,123,32'h123,300);
        calculate(3'b010,20'h42,42,300);
        calculate(3'b010,20'h123,123,300);
        calculate(3'b100,16,4,300);
        calculate(3'b100,121,11,300);
        calculate(3'b001,9,9,0);
        calculate(3'b001,0,0,0);
        calculate(3'b010,20'h9,9,0);
        calculate(3'b100,25,5,0);
        // Reset también debe retirar DONE.
        #1; reset=1;
        repeat(4) @(negedge clk);
        #1; cs=3'b111; addr=5'h14; rd=1; reset=0;
        repeat(3) @(negedge clk);
        #1;
        if(b2b!==0 || bcd!==0 || root!==0) $fatal(1,"DONE no se borra con reset");
        $display("PASS FSM originales: DONE/resultado persistentes, INIT largo/corto, recarga y reset.");
        $finish;
    end
    initial begin #200000; $fatal(1,"Timeout matemática"); end
endmodule
