module peripheral_bin2bcd(clk , reset , d_in , cs , addr , rd , wr, d_out );

  input clk;
  input reset;
  input [15:0] d_in;
  input cs;
  input [4:0] addr;
  input rd;
  input wr;
  output reg [31:0] d_out;

//------------------------------------ regs and wires-------------------------------
reg [4:0] s;
reg [15:0] A;
reg init;
wire [19:0] result;
wire done;

always @(*) begin//-------------------address_decoder------------------------------
  if (cs) begin
    case (addr)
      5'h04: s = 5'b00001; // A
      5'h0C: s = 5'b00100; // init
      5'h10: s = 5'b01000; // result
      5'h14: s = 5'b10000; // done
      default: s = 5'b00000;
    endcase
  end
  else
    s = 5'b00000;
end

always @(posedge clk) begin//----------escritura de registros-----------------------
  if(reset) begin
    init = 0;
    A = 0;
  end
  else if (cs && wr) begin
    A = s[0] ? d_in : A;
    init = s[2] ? d_in[0] : init;
  end
end

always @(posedge clk) begin//----------multiplexa salidas del periferico------------
  if(reset)
    d_out = 0;
  else if (cs) begin
    case (s)
      5'b01000: d_out = {12'b0, result};
      5'b10000: d_out = {31'b0, done};
    endcase
  end
end

bin2bcd bin2bcd0 (
  .rst(reset), .clk(clk), .init(init),
  .done(done), .result(result), .A(A)
);
endmodule
