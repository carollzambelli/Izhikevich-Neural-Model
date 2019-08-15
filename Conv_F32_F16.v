/* ----------------------------------------------------------------------------
Projeto: modulo conversor Float 32 - 16 
UFABC - universidade Federal do ABC
Versão: 1.0                Data: 02.10.2017
Prog: Carolina Zambelli

Descrição: converte um fp single precision (32bits) para um half precision 
           (16bits)
-----------------------------------------------------------------------------*/

module Conv_F32_F16
(
  input [31:0] Fin,
  output [15:0] Fout
);
  
  reg [4:0] Exp_tmp;
  reg [9:0] Man_tmp;
  
always @(Fin)
  begin
  if (Fin[30:23]>8'd142)               // se exp32 > 142, mostra infinity F16
    begin
    Exp_tmp = 5'b11111;                // exp = max  (rep +- INF)
    Man_tmp = 10'b0000000000;          // mant = 0
    end
  else if ((Fin[30:23]==8'd0) && (Fin[22:0]==23'd0))  // caso ZERO
    begin
    Exp_tmp = 5'b00000;                // exp16 sai 00000
    Man_tmp = 10'b0000000000;          // mant = 0,0000000000	 
	 end
  // normal: se 2^-14 <= exp32 <2^15 (ou seja, 103 <= exp32 <= 142)
  else if (Fin[30:23]>=8'd113)        // se 113 <= exp32 <= 142 normal F16
    begin
    Exp_tmp = Fin[30:23] - 8'd112;     // subtrair exp32 - 112!
    Man_tmp = Fin[22:13];              // mant = Fin[22:13]
    end
  // subnormal: se 2^-24 <= exp32 <2^-15 (ou seja, 103 <= exp32 <= 112)
  else if (Fin[30:23]>=8'd103) // se >103 e mant!=0
    begin
    Exp_tmp = 5'b00000;                // exp16 sai 00000
    // para cada exp < 2^-14, deslocar a mantissa
    if (Fin[30:23]==8'd112 && (9'b0|Fin[22:14]))
	   begin
      Man_tmp = {1'b1,Fin[22:14]};         // mant = Fin[22:14]
		end
	 else if (Fin[30:23]==8'd112 && ~(9'b0|Fin[22:14]))
	   begin
      Man_tmp = {1'b1,9'b0};               // mant = 0,1000000000		
		end

    else if (Fin[30:23]==8'd111 && (8'b0|Fin[22:15]))
	   begin
      Man_tmp = {2'b01,Fin[22:15]};        // mant = Fin[22:15]
		end
	 else if (Fin[30:23]==8'd111 && ~(8'b0|Fin[22:15]))
	   begin
      Man_tmp = {2'b01,8'b0};              // mant = 0,01000000	
		end

    else if (Fin[30:23]==8'd110 && (7'b0|Fin[22:16]))
	   begin
      Man_tmp = {3'b001,Fin[22:16]};       // mant = Fin[22:16]
		end
	 else if (Fin[30:23]==8'd110 && ~(7'b0|Fin[22:16]))
	   begin
      Man_tmp = {3'b001,7'b0};             // mant = 0,0010000000		
		end

    else if (Fin[30:23]==8'd109 && (6'b0|Fin[22:17]))
	   begin
      Man_tmp = {4'b0001,Fin[22:17]};      // mant = Fin[22:17]
		end
	 else if (Fin[30:23]==8'd109 && ~(6'b0|Fin[22:17]))
	   begin
      Man_tmp = {4'b0001,6'b0};            // mant = 0,0001000000		
		end

    else if (Fin[30:23]==8'd108 && (5'b0|Fin[22:18]))
	   begin
      Man_tmp = {5'b00001,Fin[22:18]};     // mant = Fin[22:18]
		end
	 else if (Fin[30:23]==8'd108 && ~(5'b0|Fin[22:18]))
	   begin
      Man_tmp = {5'b00001,5'b0};           // mant = 0,0000100000		
		end		

    else if (Fin[30:23]==8'd107 && (4'b0|Fin[22:19]))
	   begin
      Man_tmp = {6'b000001,Fin[22:19]};    // mant = Fin[22:19]
		end
	 else if (Fin[30:23]==8'd107 && ~(4'b0|Fin[22:19]))
	   begin
      Man_tmp = {6'b000001,4'b0};          // mant = 0,0000010000		
		end		

    else if (Fin[30:23]==8'd106 && (3'b0|Fin[22:20]))
	   begin
      Man_tmp = {7'b0000001,Fin[22:20]};   // mant = Fin[22:20]
		end
	 else if (Fin[30:23]==8'd106 && ~(3'b0|Fin[22:20]))
	   begin
      Man_tmp = {7'b0000001,3'b0};         // mant = 0,0000001000		
		end		

    else if (Fin[30:23]==8'd105 && (2'b0|Fin[22:21]))
	   begin
      Man_tmp = {8'b00000001,Fin[22:21]};  // mant = Fin[22:21]
		end
	 else if (Fin[30:23]==8'd105 && ~(2'b0|Fin[22:21]))
	   begin
      Man_tmp = {8'b00000001,2'b0};        // mant = 0,0000000100		
		end		

    else if (Fin[30:23]==8'd104 && Fin[22])
	   begin
      Man_tmp = {9'b000000001,Fin[22]};    // mant = Fin[22]
		end
	 else if (Fin[30:23]==8'd104 && ~Fin[22])
	   begin
      Man_tmp = {9'b000000001,1'b0};       // mant = 0,0000000010		
		end
    else
	   begin
      Man_tmp = 10'b0000000001;            // mant = 0,0000000001 
		end
    end
  // aqui não é subnormal - marcar como menor valor em vez de NaN!
  else
    begin
      Exp_tmp = 5'b00000;                  // exp16 sai 00000
      Man_tmp = 10'b0000000001;            // mant = 0,0000000001
	 end 
  end  
  
  assign Fout = {Fin[31], Exp_tmp, Man_tmp}; 
  
endmodule
