
-- Es para usar cualquiera de los tres sumadore/resadores en CB realizado

-- TAddSub esta para seleccionar tipo de sumador/restador 

--TAddSub = 0 -> G y P basado en suma inicial
--TAddSub = 1 -> G y P a partir de las entradas
--TAddSub = 2 -> Basado en el tio Vazquez

-- Proof

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity addsub_BCD_L6 is
   Generic (TAddSub: integer:= 1; NDigit : integer:=7);    
    Port ( 
	        a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin, sub : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
end addsub_BCD_L6;

architecture Behavioral of addsub_BCD_L6 is

	component AddSubBCDII 
	generic (NDigit: integer:=16);
	  Port ( 
           a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin, sub : in  STD_LOGIC;
		     cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;


	component AddSubBCDIII 
		  generic (NDigit: integer:=16);
		  Port ( 
				  a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
				  cin, sub : in  STD_LOGIC;
				  cout : out  STD_LOGIC;
				  s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;


	component AddSubBCDVaz 
	generic (NDigit: integer:=16);
	  Port ( 
           a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin, sub : in  STD_LOGIC;
		     cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;


begin


	addCond0:if (TAddSub = 0) generate
   begin  
	  add0: AddSubBCDIII generic map (NDigit => NDigit)
						Port map (  a => a, b => b, cin => cin, sub => sub, cout => cout, s => s); 
   end generate;
	
	addCond1:if (TAddSub = 1) generate
   begin  
	  add1: AddSubBCDII generic map (NDigit => NDigit)
						Port map (  a => a, b => b, cin => cin, sub => sub, cout => cout, s => s); 
   end generate;
		

	addCond2:if (TAddSub = 2) generate
   begin  
	  add2: AddSubBCDVaz generic map (NDigit => NDigit)
						Port map (  a => a, b => b, cin => cin, sub => sub, cout => cout, s => s); 
   end generate;

end Behavioral;

 
	
