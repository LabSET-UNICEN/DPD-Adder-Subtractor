
-- Código adaptado, considerando genérico, del que se encuentra en carpeta
-- .../Maestria/ProysAdd/CodigoUltimo/codigos_V5_adder_Gus/ImplI/adderBCDV5.vhd

-- TAdd esta para seleccionar tipo de sumador en el caso que haya mas de uno 
-- como lo que se hizo con Lut de 4. Se podrá elegir p y g dependiendo de las entradas.
-- Hoy por hoy solo esta implementado para p y g dependiendo de la suma inicial.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;



library UNISIM;
use UNISIM.VComponents.all;

entity adder_BCD_L6 is
   Generic (TAdd: integer:= 1; NDigit : integer:=7);    
    Port ( 
	        a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
end adder_BCD_L6;

architecture Behavioral of adder_BCD_L6 is


	component AddBCD 
     generic (NDigit: integer:=7);
	  Port ( 
	        a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;
	
	component AddBCDII 
    generic (NDigit: integer:=7);
	 Port ( 
           a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
		     cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;

	component sumNVaz 
     generic (NDigit: integer:=7);
	  Port ( 
	        a, b : in  STD_LOGIC_VECTOR (NDigit*4-1 downto 0);
           cin : in  STD_LOGIC;
           cout : out  STD_LOGIC;
           s : out  STD_LOGIC_VECTOR (NDigit*4-1 downto 0));
	end component;

begin


	addCond0:if (TAdd = 0) generate
   begin  
	  add0: AddBCD generic map (NDigit => NDigit)
						Port map (  a => a, b => b, cin => cin, cout => cout, s => s); 
   end generate;

	addCond1:if (TAdd = 1) generate
   begin  
	  add1: AddBCDII generic map (NDigit => NDigit)
						Port map (  a => a, b => b, cin => cin, cout => cout, s => s); 
   end generate;

	addCond2:if (TAdd = 2) generate
   begin  
	  add2: sumNVaz generic map (NDigit => NDigit)
						Port map (  a => a, b => b, cin => cin, cout => cout, s => s); 
   end generate;

end Behavioral;

 
	
