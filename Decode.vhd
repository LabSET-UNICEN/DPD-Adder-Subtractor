-- 
-- Este módulo es el encargado de decodificar el operando segín estandar IEEE
-- puede ser en  decimal32, decimal64 o decimal128 bits (N = 32, 64 o 128)
-- como entrada toma el dato <d> y como salida produce:
-- exponente <q> con NExp bits, en cero desplazado 
-- la mantisa <m> con P dígitos BCD de precisión
-- si es signal NaN <sNaN> o quiet <qNaN>
-- si es infinito <inf>

-- Este módulo trabaja con tres formatos
-- decimal32: N=32, Nexp=8 y P=7 
-- decimal64: N=64, Nexp=10 y P=16 
-- decimal128: N=128, Nexp=14 y P=34 



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Decode is
	 generic (N: integer:= 32;
				NExp: integer:= 8;
				P: integer:=7);
    Port ( d : in  std_logic_vector (N-1 downto 0);
           s: out std_logic;
			  q : out std_logic_vector (NExp-1 downto 0);
			  m : out  std_logic_vector (4*P-1 downto 0);
              qNaN, sNaN, inf : out  STD_LOGIC);
end Decode;

architecture Behavioral of Decode is

	component DPD_decode is
		generic ( P: integer:=6);
		Port ( di : in  STD_LOGIC_VECTOR ((P/3)*10-1 downto 0);
           do : out  STD_LOGIC_VECTOR (4*P-1 downto 0));
	end component;

	
	signal tmp, tmp2, tNaN: std_logic;
	signal q_cd: std_logic_vector(NExp-1 downto 0);


begin

	s <= d(N-1);

	tmp <= not(d(N-2) and d(N-3));
	tmp2 <= not(d(N-4) and d(N-5));

   q_cd(NExp-1 downto NExp-2) <= d(N-2 downto N-3) when tmp='1' else
										d(N-4 downto N-5) when tmp2='1' else
										"00"; -- don't care
		
	q_cd(NExp-3 downto 0) <= d(N-7 downto 10*((P-1)/3));
	-- Otra forma es d(N-7 downto N-4-NExp);

	
	-- genera el dígito más significativo de la mantisa
	m(4*P-1 downto 4*(P-1)) <= ('0'&d(N-4 downto N-6)) when tmp='1' else
										("100"&d(N-6)) when tmp2='1' else
										"0000"; -- don't care
										

	CDPD_dec: DPD_decode  -- genera ls P-1 dígitos BCD de mantisa
					generic map( P => P-1)
					Port map ( di => d(10*((P-1)/3)-1 downto 0),
								do => m(4*P-5 downto 0));


	tNaN <= d(N-2) and d(N-3) and d(N-4) and d(N-5) and d(N-6); 
	
	inf <= '1' when (tmp='0' and tmp2='0' and d(N-6)='0') else
			 '0';
	
	qNaN <= '1' when (tNaN='1' and d(10*((P-1)/3)-1)='0') else
				'0';
	
	sNaN <= '1' when (tNaN='1' and d(10*((P-1)/3)-1)='1') else
				'0';
	
		
	q <= q_cd;
 
	
end Behavioral;

