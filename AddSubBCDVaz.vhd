
-- sumador/restador basándose en sumador planteado por Vazquez en reporte interno

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity AddSubBCDVaz is
	generic (NDigit: integer:=16);
	  Port ( 
           a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin, sub : in  STD_LOGIC;
		     cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
end AddSubBCDVaz;

architecture Behavioral of AddSubBCDVaz is

	component Comp9 
    Port ( b : in  STD_LOGIC_VECTOR (3 downto 0);
           sub : in std_logic;
			  bComp : out  STD_LOGIC_VECTOR (3 downto 0));
	end component;

	component sumNVaz 
		generic (NDigit: integer:=7);
		Port ( a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
				cin : in  STD_LOGIC;
				cout : out  STD_LOGIC;
				s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;

	signal c: std_logic_vector(NDigit*4-1 downto 0);

begin

	GenC_nine: for i in 0 to NDigit-1 generate
		C_nine: Comp9 port map(b => b(4*(i+1)-1 downto 4*i), sub => sub, bComp => c(4*(i+1)-1 downto 4*i));
	end generate;
	
	
	EAdd: sumNVaz generic map (NDigit => NDigit)
						port map ( a => a,  b => c, cin => sub, cout => cout, s => s);
				


end Behavioral;

