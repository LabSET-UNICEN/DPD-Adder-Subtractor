-- 
-- Este módulo es el encargado de codificar el operando según estandar IEEE
-- puede ser en  decimal32, decimal64 o decimal128 bits (N = 32, 64 o 128)
-- como etrada toma 
-- exponente <q> con NExp bits 
-- la mantisa <m> con P dígitos BCD de precisión
-- si es signal NaN <sNaN> o quiet <qNaN>
-- si es infinito <inf>
-- y produce el resultado <r> :

-- Este módulo trabaja con tres formatos
-- decimal32: N=32, Nexp=8 y P=7 
-- decimal64: N=64, Nexp=10 y P=16 
-- decimal128: N=128, Nexp=14 y P=34 

-- El exponente se que entra al módulo se encuentra en complento a la base
-- es por eso que hay que pasarlo a cero desplazado

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Encode is
	 generic (N: integer:= 32;
				NExp: integer:= 8;
				P: integer:=7);
    Port ( s: in std_logic;
			  q : in std_logic_vector (NExp-1 downto 0);
			  m : in  std_logic_vector (4*P-1 downto 0);
           qNaN, sNaN, inf : in  STD_LOGIC;
			  r : out  std_logic_vector (N-1 downto 0));
end Encode;

architecture Behavioral of Encode is

	component DPD_encode is
		generic ( P: integer:=6);
		Port (  di : in  STD_LOGIC_VECTOR (4*P-1 downto 0);
				  do : out  STD_LOGIC_VECTOR ((P/3)*10-1 downto 0));
	end component;
	
	signal rr: std_logic_vector(10*((P-1)/3)-1 downto 0);
	
begin

	CDPD_encode: DPD_encode  -- codifica los P-1 dígitos BCD de mantisa
					generic map( P => P-1)
					Port map ( di => m(4*P-5 downto 0),
								do => rr(10*((P-1)/3)-1 downto 0)
								);


	

	r(10*((P-1)/3)-2 downto 0) <= rr(10*((P-1)/3)-2 downto 0);
	
	-- esto es para bit que discrimina entre NaN
	-- para el caso que sNaN o qNaN es 1, entonces si sNaN es 1 pone 1
	-- sino es porque qNaN es 1 y pone 0
	r(10*((P-1)/3)-1) <= rr(10*((P-1)/3)-1) when (sNaN='0' and qNaN='0') else
								sNaN; 
	
	
	r(N-1) <= s;
	r(N-7 downto 10*((P-1)/3)) <= q(NExp-3 downto 0);


	r(N-2 downto N-6) <= "11111" when (sNaN='1' or qNaN='1') else
								"11110" when inf='1' else
								("11"&q(NExp-1 downto NExp-2)&m(4*P-4)) when m(4*P-1)='1' else -- primer dígito 8 o 9
								(q(NExp-1 downto NExp-2)&m(4*P-2 downto 4*P-4));	
								



end Behavioral;

