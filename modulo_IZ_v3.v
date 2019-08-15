module modulo_IZ_v3
(
   input clk, go, reset,
	input [15:0] V_ini16, I_16, U_ini16,
	output [31:0] Vfinal, Ufinal,
	output ready
	
);

  reg [40:0] Timeline; 
 
  always @(posedge clk) 
   if (reset) begin
	    Timeline <= 40'h0000000000;
   end else begin
       Timeline = Timeline << 1; 
		 Timeline[0] = go;  
   end
	

/*-----------------------------------------------------------------------------
contantes de cálculo
-------------------------------------------------------------------------------*/

  wire [31:0] Kf5, Kf004, Kf140, kf30, kf60;
  
  assign Kf5 = 32'h40A00000;
  assign Kf004 = 32'h3d23d70a;
  assign Kf140 = 32'h430c0000;
  assign kf30 = 32'h41F00000;
  assign kf60 = 32'h42700000;

  wire [31:0] Kfa, Kfb, Kfc, kfd;
  assign Kfa = 32'h3CA3D70A; //0.02
  assign Kfb = 32'h3E4CCCCD; //0.2
  assign Kfc = 32'hC2820000; //-65 
  assign kfd = 32'h40000000; // 2 
  
  // parametro da linha de retardo
  parameter W = 32;
  
/*-----------------------------------------------------------------------------
Conversão para 32 bits
-------------------------------------------------------------------------------*/  
  
 wire [31:0] V_ini32, U_ini32, I_32;


Conv_F16_F32 IN_V16(
   .Fin (V_ini16),
   .Fout (V_ini32));

	
Conv_F16_F32 IN_I16(
   .Fin (I_16),
   .Fout (I_32));
 
 
Conv_F16_F32 IN_U16(
   .Fin (U_ini16),
   .Fout (U_ini32));
	    	 
/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine VV004
------------------------------------------------------------------------------*/	 
  always @(posedge clk)
    if (reset) begin
      Reg_VV <= 32'b0;   
    end else if (Timeline[6] == 1) begin
      Reg_VV <= W_VV;
    end 
	 
  always @(posedge clk)
    if (reset) begin
      Reg_VV004 <= 32'b0;   
    end else if (Timeline[13] == 1) begin
      Reg_VV004 <= W_VV004;
    end 
	 

/*-----------------------------------------------------------------------------
Lógica dos Cálculos do Pipeline VV004
------------------------------------------------------------------------------*/
// fios e registradores 
  wire habck_W_VV, habck_W_V004;
  wire [31:0] W_VV, W_VV004;
  reg [31:0] Reg_VV, Reg_VV004;
  
  assign habck_W_VV =| Timeline[5:0];  //or para todos os bit do timeline
  assign habck_W_V004 =| Timeline[12:7];

// calculo de VV
mult	mult_VV (
	.clk_en (habck_W_VV),
	.clock (clk),
	.dataa (V_ini32),
	.datab (V_ini32),
	.result (W_VV)
	);  
	
// calculo de VV004
mult	mult_VV004 (
	.clk_en (habck_W_V004),
	.clock (clk),
	.dataa (Reg_VV),
	.datab (Kf004),
	.result (W_VV004)
	);  
/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine 140-U
------------------------------------------------------------------------------*/	 
  always @(posedge clk)
    if (reset) begin
      Reg_140U <= 32'b0;   
    end else if (Timeline[8] == 1) begin
      Reg_140U <= W_140U;
    end 
	 
  always @(posedge clk)
    if (reset) begin
      Reg_140U_ret <= 32'b0;   
    end else if (Timeline[13] == 1) begin
      Reg_140U_ret <= W_140U_ret;
    end 
	 
	//assign reg_140u_ret = Reg_140U_ret;
	
/*-----------------------------------------------------------------------------
Lógica dos Cálculos do Pipeline 140-U
------------------------------------------------------------------------------*/
// fios e registradores 
  wire habck_W_140U, habck_ret140U;
  wire [31:0] W_140U, W_140U_ret;
  reg [31:0] Reg_140U, Reg_140U_ret;

//lógica para habilitar os cálculos  
  assign habck_W_140U =| Timeline[7:0];  //or para todos os bit do timeline
  assign habck_ret140U =| Timeline[12:9];
  
// calculo de 140-U	
sub  sub_140U (
	.clk_en (habck_W_140U),
	.clock ( clk ),
	.dataa (Kf140),
	.datab (U_ini32),
	.result ( W_140U ));	
	
	parameter LSTG_140U = 3;
	
	linha_retardo #(
    .W (W),                          
    .L (LSTG_140U))                      
  linRet_140U (                     
    .clk ( clk ),                     
    .ena ( habck_ret140U ),
    .A ( Reg_140U ),                        
    .O ( W_140U_ret)); 
	 
/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine VV004 + (140-U)
------------------------------------------------------------------------------*/	 
  
  always @(posedge clk)
    if (reset) begin
      Reg_VV004_140U <= 32'b0;   
    end else if (Timeline[22] == 1) begin
      Reg_VV004_140U <= W_VV004_140U;
    end

	 //assign reg_vv004_140u = Reg_VV004_140U;
	 
/*-----------------------------------------------------------------------------
Lógica dos Calculos do PipeLine VV004 + (140-U)
------------------------------------------------------------------------------*/	
// fios e registradores 
  wire habck_W_VV004_140U;
  wire [31:0] W_VV004_140U;
  reg [31:0] Reg_VV004_140U;

//lógica para habilitar os cálculos  
  assign habck_W_VV004_140U =| Timeline[21:14];  //or para todos os bit do timeline
  
// calculo de VV004 + (140-U) 	
soma  soma_VV004_140U (
	.clk_en (habck_W_VV004_140U),
	.clock ( clk ),
	.dataa ( Reg_VV004 ),
	.datab ( Reg_140U_ret ),
	.result ( W_VV004_140U ));	
	
/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine 5V+I
------------------------------------------------------------------------------*/	 
  always @(posedge clk)
    if (reset) begin
      Reg_V5 <= 32'b0;   
    end else if (Timeline[6] == 1) begin
      Reg_V5 <= W_5V;
    end 
  
  always @(posedge clk)
    if (reset) begin
      Reg_Iret <= 32'b0;   
    end else if (Timeline[6] == 1) begin
      Reg_Iret <= I_32_ret;
    end 
	 
  always @(posedge clk)
    if (reset) begin
      Reg_V5_I <= 32'b0;   
    end else if (Timeline[15] == 1) begin
      Reg_V5_I <= W_5V_I;
    end 
	 
  always @(posedge clk)
    if (reset) begin
      Reg_V5_Iret <= 32'b0;   
    end else if (Timeline[22] == 1) begin
      Reg_V5_Iret <= W_5V_Iret;
    end 
	 
	 
/*-----------------------------------------------------------------------------
Lógica dos Cálculos do Pipeline 5V+I
------------------------------------------------------------------------------*/
// fios e registradores 
  wire habck_W_5V, habck_retI, habck_W_5V_I, habck_W_5V_Iret;
  wire [31:0] W_5V, W_5V_I, W_5V_Iret;
  reg [31:0] Reg_V5, Reg_Iret, Reg_V5_I, Reg_V5_Iret;

//lógica para habilitar os cálculos  
  assign habck_W_5V =| Timeline[5:0];  //or para todos os bit do timeline
  assign habck_retI =| Timeline[5:0];
  assign habck_W_5V_I =| Timeline[14:7];
  assign habck_W_5V_Iret =| Timeline[21:16];

// calculo de 5V
mult	mult_V5 (
	.clk_en (habck_W_5V),
	.clock (clk),
	.dataa (V_ini32),
	.datab (Kf5),
	.result (W_5V)
	);  
	
	parameter LSTG_retI = 5;
	wire [31:0] I_32_ret;
	
	linha_retardo #(
    .W (W),                          
    .L (LSTG_retI))                      
  linRet_reI (                     
    .clk ( clk ),                     
    .ena ( habck_retI ),
    .A (I_32),                        
    .O ( I_32_ret)); 	
	 
// calculo de 5V + I	
soma	soma_5V_I (
	.clk_en (habck_W_5V_I),
	.clock ( clk ),
	.dataa ( Reg_Iret ),
	.datab ( Reg_V5 ),
	.result ( W_5V_I )); 
	
	parameter LSTG_ret5VI = 5;
	
	linha_retardo #(
    .W (W),                          
    .L (LSTG_ret5VI))                      
  linRet_re5VI (                     
    .clk ( clk ),                     
    .ena ( habck_W_5V_Iret ),
    .A ( Reg_V5_I ),                        
    .O ( W_5V_Iret));  

/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine VV004 + (140-U) + 5V + I
------------------------------------------------------------------------------*/	 

  
  always @(posedge clk)
    if (reset) begin
      Reg_VV004_140U_5VI <= 32'b0;   
    end else if (Timeline[31] == 1) begin
      Reg_VV004_140U_5VI <= W_VV004_140U_5VI;
    end
	 
		 
/*-----------------------------------------------------------------------------
Lógica dos Calculos do PipeLine VV004 + (140-U) + 5V + I
------------------------------------------------------------------------------*/	
// fios e registradores 
  wire habck_W_VV004_140U_5VI;
  wire [31:0] W_VV004_140U_5VI;
  reg [31:0] Reg_VV004_140U_5VI;

//lógica para habilitar os cálculos  
  assign habck_W_VV004_140U_5VI =| Timeline[30:23];  //or para todos os bit do timeline
  
// calculo de VV004 + (140-U) 	
soma  soma_VV004_140U_5VI (
	.clk_en (habck_W_VV004_140U_5VI),
	.clock ( clk ),
	.dataa ( Reg_V5_Iret ),
	.datab ( Reg_VV004_140U ),
	.result ( W_VV004_140U_5VI ));

/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine b*V - U
------------------------------------------------------------------------------*/	 
  always @(posedge clk)
    if (reset) begin
      Reg_bV <= 32'b0;   
    end else if (Timeline[6] == 1) begin
      Reg_bV <= W_bV;
    end 
  
  always @(posedge clk)
    if (reset) begin
      Reg_Uret <= 32'b0;   
    end else if (Timeline[6] == 1) begin
      Reg_Uret <= U_32_ret;
    end 
	 
  always @(posedge clk)
    if (reset) begin
      Reg_bV_U <= 32'b0;   
    end else if (Timeline[15] == 1) begin
      Reg_bV_U <= W_bV_U;
    end 
	 


/*-----------------------------------------------------------------------------
Lógica dos Calculos do PipeLine b*V - U
------------------------------------------------------------------------------*/	 
// fios e registradores 
  wire habck_W_bV, habck_ret1U, habck_W_bV_U;
  wire [31:0] W_bV, W_bV_U;
  reg [31:0] Reg_bV, Reg_Uret, Reg_bV_U;

//lógica para habilitar os cálculos  
  assign habck_W_bV =| Timeline[5:0];  //or para todos os bit do timeline
  assign habck_ret1U =| Timeline[5:0];
  assign habck_W_bV_U =| Timeline[14:7];

// calculo de bV
mult	mult_bV (
	.clk_en (habck_W_bV),
	.clock (clk),
	.dataa (V_ini32),
	.datab (Kfb),
	.result (W_bV)
	);  
	
	parameter LSTG_retU = 5;
	wire [31:0] U_32_ret;
	
	linha_retardo #(
    .W (W),                          
    .L (LSTG_retU))                      
  linRet_retU (                     
    .clk ( clk ),                     
    .ena ( habck_ret1U ),
    .A ( U_ini32 ),                        
    .O ( U_32_ret)); 	
	 
// calculo de bV - U	
sub sub_bV_U (
	.clk_en (habck_W_bV_U),
	.clock ( clk ),
	.dataa (Reg_bV),
	.datab (Reg_Uret),
	.result ( W_bV_U )); 


/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine a*(b*V - U)
------------------------------------------------------------------------------*/	 

  always @(posedge clk)
    if (reset) begin
      Reg_a_bV_U <= 32'b0;   
    end else if (Timeline[22] == 1) begin
      Reg_a_bV_U <= W_a_bV_U;
    end 
	
  always @(posedge clk)
    if (reset) begin
      Reg_a_bV_U_ret <= 32'b0;   
    end else if (Timeline[39] == 1) begin
      Reg_a_bV_U_ret <= a_bV_U_ret;
    end

/*-----------------------------------------------------------------------------
Lógica dos Calculos do PipeLine a*(b*V - U)
------------------------------------------------------------------------------*/		
// fios e registradores 
  wire habck_W_a_bV_U, habck_W_a_bV_U_ret;
  wire [31:0] W_a_bV_U;
  reg [31:0] Reg_a_bV_U, Reg_a_bV_U_ret;

//lógica para habilitar os cálculos  
  assign habck_W_a_bV_U =| Timeline[21:16];
  assign habck_W_a_bV_U_ret =| Timeline[38:23];

// calculo de bV
mult	mult_a_bV_U (
	.clk_en (habck_W_a_bV_U),
	.clock (clk),
	.dataa (Kfa),
	.datab (Reg_bV_U),
	.result (W_a_bV_U)
	);  
	
	parameter LSTG_ret_a_bV_U = 15;
	wire [31:0] a_bV_U_ret;
	
	linha_retardo #(
    .W (W),                          
    .L (LSTG_ret_a_bV_U))                      
  linRet_ret_a_bv_U (                     
    .clk ( clk ),                     
    .ena ( habck_W_a_bV_U_ret ),
    .A ( Reg_a_bV_U ),                        
    .O ( a_bV_U_ret)); 	
	 
/*-----------------------------------------------------------------------------
Instancia as saídas em clock 39
------------------------------------------------------------------------------*/
// precisa atrasar a saída do V

  wire habck_Reg_VV004_140U_5VI_ret;
  wire [31:0] W_Reg_VV004_140U_5VI_ret;
  reg [31:0] Reg_VV004_140U_5VI_ret;

//lógica para habilitar os cálculos  
  assign habck_Reg_VV004_140U_5VI_ret =| Timeline[38:32];
  
  	parameter LSTG_ret_VV004_140U_5VI_ret = 6;
	
	linha_retardo #(
    .W (W),                          
    .L (LSTG_ret_VV004_140U_5VI_ret))                      
  linRet_ret_VV004_140U_5VI_ret (                     
    .clk ( clk ),                     
    .ena ( habck_Reg_VV004_140U_5VI_ret ),
    .A ( Reg_VV004_140U_5VI ),                        
    .O ( W_Reg_VV004_140U_5VI_ret)); 	
	 
	   always @(posedge clk)
    if (reset) begin
      Reg_VV004_140U_5VI_ret <= 32'b0;   
    end else if (Timeline[39] == 1) begin
      Reg_VV004_140U_5VI_ret <= W_Reg_VV004_140U_5VI_ret;
    end

	 //assign U_final = Reg_a_bV_U_ret;
	 //assign V_final = Reg_VV004_140U_5VI_ret;
	 
/*-----------------------------------------------------------------------------
Lógica dos Registradores do PipeLine U + d
------------------------------------------------------------------------------*/	 

  always @(posedge clk)
    if (reset) begin
      Reg_dU <= 32'b0;   
    end else if (Timeline[8] == 1) begin
      Reg_dU <= W_dU;
    end 
	
  always @(posedge clk)
    if (reset) begin
      Reg_dU_ret <= 32'b0;   
    end else if (Timeline[39] == 1) begin
      Reg_dU_ret <= dU_ret;
    end 	
	 
  //assign uout2 = Reg_dU_ret;

/*-----------------------------------------------------------------------------
Lógica dos Calculos do PipeLine U + d
------------------------------------------------------------------------------*/		
// fios e registradores 
  wire habck_W_dU, habck_ret_dU;
  wire [31:0] W_dU;
  reg [31:0] Reg_dU, Reg_dU_ret;

//lógica para habilitar os cálculos  
  assign habck_W_dU =| Timeline[7:0];
  assign habck_ret_dU =| Timeline[38:9];

// calculo de U+d
soma	soma_dU (
	.clk_en (habck_W_dU),
	.clock (clk),
	.dataa (U_ini32),
	.datab (kfd),
	.result (W_dU)
	);  
	
	parameter LSTG_ret_dU = 29;
	wire [31:0] dU_ret;
	
	linha_retardo #(
    .W (W),                          
    .L (LSTG_ret_dU))                      
  linRet_ret_dU (                     
    .clk ( clk ),                     
    .ena ( habck_ret_dU ),
    .A ( Reg_dU ),                        
    .O ( dU_ret)); 

	
	
/*-----------------------------------------------------------------------------
Lógica dos Registradores do Comparador
------------------------------------------------------------------------------*/

reg fim;		
  
  always @(posedge clk)
    if (reset) begin
      Reg_Vfinal <= 32'b0;
      Reg_Ufinal <= 32'b0;	
		fim <= 1'b0;
    end else if (Timeline[40] == 1) begin
	     if (W_Vfinal < kf60) begin
          Reg_Vfinal <= Reg_VV004_140U_5VI;
			 Reg_Ufinal <= Reg_a_bV_U_ret;
			 fim <= 1'b1;
        end else if (W_Vfinal > kf60) begin
	       Reg_Vfinal <= Kfc;
			 Reg_Ufinal <= Reg_dU_ret;
			 fim <= 1'b1;
		  end else if (W_Vfinal == kf60) begin
	       Reg_Vfinal <= Kfc;
			 Reg_Ufinal <= Reg_dU_ret;
			 fim <= 1'b1;
	     end
	 end

	 
/*-----------------------------------------------------------------------------
Lógica dos Calculos do Comparador
------------------------------------------------------------------------------*/	
  wire habck_W_Vfinal;
  wire [31:0] W_Vfinal;
  reg [31:0] Reg_Vfinal, Reg_Ufinal;
  
  assign habck_W_Vfinal =| Timeline[39:32];
  
soma	comp_V (
	.clk_en ( habck_W_Vfinal),
	.clock ( clk ),
	.dataa ( Reg_VV004_140U_5VI ),
	.datab ( kf30 ),
	.result ( W_Vfinal )
	);
	
/*-----------------------------------------------------------------------------
Conversão para 16 bits
-------------------------------------------------------------------------------*/  
   
 assign Vfinal = Reg_Vfinal;
 assign Ufinal = Reg_Ufinal;
 assign ready = fim;	
	 	
endmodule
