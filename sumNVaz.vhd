-- este es el sumador de Vázquez para N dígitos que aparece en el reporte interno
-- esta el funcionamiento para que sume solo dos operandos
-- el resultado se corrige para que no aparezca la redundancia con el 8 y 9


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


library UNISIM;
use UNISIM.VComponents.all;


entity sumNVaz is
     generic (NDigit: integer:=7);
	  Port ( 
	        a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
end sumNVaz;


architecture Behavioral of sumNVaz is

	component Sum4Vaz 
		Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           cin : in  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (3 downto 0);
           cout : out  STD_LOGIC);
	end component;
	
	signal cyin: std_logic_vector(NDigit downto 0);

begin


--	s <= a + b + cin;


	cyin(0) <= cin; 	
	
	GenAdd: for i in 0 to NDigit-1 generate
		
		GAdd: Sum4Vaz port map	(a => a((i+1)*4-1 downto i*4),
							 b => b((i+1)*4-1 downto i*4),
							cin => cyin(i),
							s => s((i+1)*4-1 downto i*4),
							cout => cyin(i+1));
	
	end generate;	


	cout <= cyin(NDigit);

end Behavioral;

