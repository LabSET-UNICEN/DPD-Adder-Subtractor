--
--Este módulo realiza el la codificación según Densely Packed Decimal
-- P es la precisión que se manejará el estandar
-- P puede ser  6, 15 o 33 (múltiplo de 3)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.VComponents.all;

entity DPD_encode is
	generic ( P: integer:=6);
   Port (  di : in  STD_LOGIC_VECTOR (4*P-1 downto 0);
			  do : out  STD_LOGIC_VECTOR ((P/3)*10-1 downto 0));
end DPD_encode;

architecture Behavioral of DPD_encode is

component DPD_encode3 
    Port ( di : in  STD_LOGIC_VECTOR (11 downto 0);
           do : out  STD_LOGIC_VECTOR (9 downto 0));
end component;

begin

	FOR_ENCODE: for I in 0 to P/3-1 generate

	
		CO_ENCODE: DPD_encode3 port map (
									di => di(12*(I+1)-1 downto 12*I),
									do => do(10*(I+1)-1 downto 10*I));
	
	end generate;


end Behavioral;

