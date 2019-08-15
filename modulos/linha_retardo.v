/* ---------------------------------------------------------------------------------
modulo linha de retardo - feito à mão - synthesizable (garantido)
Autor:  João Ranhel
Versão: 1.0       Data 01/01/2017
Funcionamento:
recebe um vetor A de W bits, e causa um delay de L clk (se enable=1)
para alterar o W
ajustar manualmente a quantidade de regs SRbnn 
----------------------------------------------------------------------------------*/
module linha_retardo(
  input clk, ena,
  input [W-1:0] A,
  output [W-1:0] O);
  
// parametros
  parameter W = 32;                    // largura do barramento de entrada
  parameter L = 6;                     // comprimento do deslocamento dos bits
  
// regs e mem usada neste módulo
  reg [L-1:0] SR [W-1:0];              // estrutura de memória p/ retardo
  reg [W-1:0] tmpO;                    // arq temp p/ saida do retardo
  
  assign O = tmpO;                     // fios de saída 
  
// var para contador
  integer i;                           // i apenas p/ loop
  
  always @(posedge clk)                // faz desloc de W bits a cada clk
    begin
      if (ena)
        begin
          for (i=0; i<W; i=i+1)
            begin
            SR[i][L-1:1] <= SR[i][L-2:0]; 
            SR[i][0] <= A[i];
            end
        end
    end
  always @(posedge clk)                // reconstroi saída da linha em um reg tmp
    begin
    for (i=0; i<W; i=i+1)
      begin
        tmpO[i] <= SR[i][L-1];
      end
    end
endmodule
