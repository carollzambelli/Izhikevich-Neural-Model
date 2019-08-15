/* ----------------------------------------------------------------------------
Projeto: modulo conversor Float 16 - 32 
UFABC - universidade Federal do ABC
Versão: 1.0                Data: 02.10.2017
Prog: Carolina Zambelli

Descrição: converte um fp half precision (16bits) para um single (32bits)
como trabalhamos apenas em normalized, a fórmula fica:

f = ((h&0x8000)<<16) | (((h&0x7c00)+0x1C000)<<13) | ((h&0x03FF)<<13)
-----------------------------------------------------------------------------*/

module Conv_F16_F32
(
  input [15:0] Fin,
  output [31:0] Fout
);

  reg  [7:0] Exp_tmp;
  reg  [22:0] Man_tmp;

// este bloco resolve concatenação dos bits incluindo subnormal
always @(Fin)
  begin
  if (Fin[14:10] == 5'd31)             // se exp==31 +- inf
    begin
    Exp_tmp = 8'd255;
    Man_tmp = 23'd0;
	 end
  else if ((Fin[14:10]==5'd0) && (Fin[9:0]==10'd0) )  // zero
    begin
    Exp_tmp = 8'd0;
    Man_tmp = 23'd0;
    end
  // NORMAL: 1 <= exp <= 30
  else if (Fin[14:10] >= 5'b00001)     // se exp>zero, exp acima de 2^-14
    begin
    Exp_tmp = (Fin[14:10] + 8'd112);   // apenas soma 112 ao exp
    Man_tmp = {Fin[9:0], 13'b0};
    end
  // SUBNORMAL: exp = "00000"
  else if (Fin[9]==1'b1)               // se exp==0 e 1xxx exp 2^-15
    begin
    Exp_tmp = 8'd112;                  // esse valor representa exp -15
    Man_tmp = {Fin[9:0], 13'b0};       // usa 10 bits da mantissa 
    end
  else if (Fin[9:8]==2'b01)            // se ,01.. exp = 2^-16
    begin
    Exp_tmp = 8'd111;                  // esse valor representa exp -16
    Man_tmp = {Fin[8:0], 14'b0};       // desloca bits da mantissa  
    end
  else if (Fin[9:7]==3'b001)            // se ,001.. exp = 2^-17
    begin
    Exp_tmp = 8'd110;                  // esse valor representa exp -17
    Man_tmp = {Fin[7:0], 15'b0};       // desloca bits da mantissa  
    end
  else if (Fin[9:6]==4'b0001)          // se ,0001.. exp = 2^-18
    begin
    Exp_tmp = 8'd109;                  // esse valor representa exp -18
    Man_tmp = {Fin[6:0], 16'b0};       // desloca bits da mantissa  
    end
  else if (Fin[9:5]==5'b00001)         // se ,00001.. exp = 2^-19
    begin
    Exp_tmp = 8'd108;                  // esse valor representa exp -19
    Man_tmp = {Fin[5:0], 17'b0};       // desloca bits da mantissa  
    end
  else if (Fin[9:4]==6'b000001)        // se ,000001.. exp = 2^-20
    begin
    Exp_tmp = 8'd107;                  // esse valor representa exp -20
    Man_tmp = {Fin[4:0], 18'b0};       // desloca bits da mantissa  
    end
  else if (Fin[9:3]==7'b0000001)       // se ,0000001.. exp = 2^-21
    begin
    Exp_tmp = 8'd106;                  // esse valor representa exp -21
    Man_tmp = {Fin[3:0], 19'b0};       // desloca bits da mantissa  
    end
  else if (Fin[9:2]==8'b00000001)      // se ,00000001.. exp = 2^-22
    begin
    Exp_tmp = 8'd105;                  // esse valor representa exp -22
    Man_tmp = {Fin[2:0], 20'b0};       // desloca bits da mantissa  
    end
  else if (Fin[9:1]==9'b000000001)     // se ,000000001.. exp = 2^-23
    begin
    Exp_tmp = 8'd104;                  // esse valor representa exp -23
    Man_tmp = {Fin[1:0], 21'b0};       // desloca bits da mantissa  
    end
  else                                 // se menor ainda, trava em zero
    begin
    Exp_tmp = 8'd103;                  // esse valor representa exp -126
    Man_tmp = {23'b0};                 // non-zero na mantissa  
    end
  end
  
//remonta o valor depois do cálculo do novo expoente
  assign Fout = {Fin[15], Exp_tmp, Man_tmp}; 

endmodule
