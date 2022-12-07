--
--Este módulo realiza el la decodificación según Densely Packed Decimal
-- P es la precisión que se manejará el estandar
-- P puede ser  6, 15 o 33 (múltiplo de 3)



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity DPD_decode is
	generic ( P: integer:=6);
   Port ( di : in  STD_LOGIC_VECTOR ((P/3)*10-1 downto 0);
           do : out  STD_LOGIC_VECTOR (4*P-1 downto 0));
end DPD_decode;

architecture Behavioral of DPD_decode is

component DPD_decode3 is
    Port ( di : in  STD_LOGIC_VECTOR (9 downto 0);
           do : out  STD_LOGIC_VECTOR (11 downto 0));
end component;

begin

	FOR_DECODE: for I in 0 to P/3-1 generate

	
		CO_DECODE: DPD_decode3 port map (
									di => di(10*(I+1)-1 downto 10*I),
									do => do(12*(I+1)-1 downto 12*I));
	
	end generate;

end Behavioral;

