module control_sqrt( clk , rst , init, msb, z, done, ld_tmp, r0, sh, ld, lda2);
 

 input  clk;
 input  rst;
 input  init; 
 input  msb;
 input  z;
 output reg done; 
 output reg ld_tmp; 
 output reg r0; 
 output reg sh; 
 output reg ld; 
 output reg lda2; 



  parameter START     = 4'b0000;
  parameter CHECK     = 4'b0001;
  parameter SHIFT_DEC = 4'b0010;
  parameter LOAD_TMP  = 4'b0011;
  parameter LOAD_A2   = 4'b0100;
  parameter CHECK_Z   = 4'b0101;
  parameter END1      = 4'b0110;
  parameter WAIT_INIT = 4'b0111;
  parameter LOAD_NEW  = 4'b1000;

 
  reg [3:0] state;

always @(posedge clk) begin
  if (rst) begin
    state = START;
  end else begin
  case(state)

    START:begin
      if(init)
        state = SHIFT_DEC;
      else
        state = START;
    end

    SHIFT_DEC: begin
      state = LOAD_TMP;
    end


    LOAD_TMP: begin
      state = CHECK;
    end


    CHECK: begin
      if (msb)
        state = CHECK_Z;
      if (!msb)
        state = LOAD_A2;

    end

    LOAD_A2: begin
      state = CHECK_Z;
    end


    CHECK_Z: begin
      if (z)
        state = END1;
      else
        state = SHIFT_DEC;
    end

    END1: begin
      // No repetir si el inicio anterior sigue alto.
      state = (!init) ? WAIT_INIT : END1;
    end

    WAIT_INIT: begin
      // DONE y resultado se conservan hasta una nueva orden.
      state = (init) ? LOAD_NEW : WAIT_INIT;
    end

    LOAD_NEW: begin
      // Cargar durante un ciclo completo, aunque init ya vuelva a cero.
      state = SHIFT_DEC;
    end

    default: state = START;
   endcase
  end
end


always @(*) begin
  case(state)
    START, LOAD_NEW: begin
      done   = 0; 
      ld_tmp = 0; 
      r0     = 0; 
      sh     = 0; 
      ld     = 1; 
      lda2   = 0; 
    end

    CHECK: begin
      done   = 0; 
      ld_tmp = 0; 
      r0     = 0; 
      sh     = 0; 
      ld     = 0; 
      lda2   = 0; 
    end

    SHIFT_DEC: begin
      done   = 0; 
      ld_tmp = 0; 
      r0     = 0;   // OJO
      sh     = 1; 
      ld     = 0; 
      lda2   = 0; 
    end

    LOAD_TMP: begin
      done   = 0; 
      ld_tmp = 1; 
      r0     = 0; 
      sh     = 0; 
      ld     = 0; 
      lda2   = 0; 
    end

    LOAD_A2: begin
      done   = 0; 
      ld_tmp = 0; 
      r0     = 1; 
      sh     = 0; 
      ld     = 0; 
      lda2   = 1; 
    end

    CHECK_Z: begin
      done   = 0; 
      ld_tmp = 0; 
      r0     = 0; 
      sh     = 0; 
      ld     = 0; 
      lda2   = 0; 
    end

    END1, WAIT_INIT: begin
      done   = 1; 
      ld_tmp = 0; 
      r0     = 0; 
      sh     = 0; 
      ld     = 0; 
      lda2   = 0; 
    end

    default: begin
      done   = 0; 
      ld_tmp = 0; 
      r0     = 0; 
      sh     = 0; 
      ld     = 0; 
      lda2   = 0; 
    end

  endcase
end



`ifdef BENCH
reg [8*40:1] state_name;
always @(*) begin
  case(state)
    START     : state_name = "START";
    CHECK     : state_name = "CHECK";
    SHIFT_DEC : state_name = "SHIFT_DEC";
    LOAD_TMP  : state_name = "LOAD_TMP";
    LOAD_A2   : state_name = "LOAD_A2";
    END1      : state_name = "END1";
    WAIT_INIT : state_name = "WAIT_INIT";
    LOAD_NEW  : state_name = "LOAD_NEW";
  endcase
end
`endif

endmodule
