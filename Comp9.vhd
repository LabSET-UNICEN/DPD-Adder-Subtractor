
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Comp9 is
    Port ( b : in  STD_LOGIC_VECTOR (3 downto 0);
           sub : in std_logic;
			  bComp : out  STD_LOGIC_VECTOR (3 downto 0));
end Comp9;

architecture Behavioral of Comp9 is

begin

--	bComp(1) <= b(1);
--	bComp(0) <= ((not b(0)) and sub) or (b(0) and (not sub));
	
	comp01_LUT6 : LUT6_2
				generic map (
					INIT => X"000000cc0000005a")
				port map (
					O6 => bComp(1),  
					O5 => bComp(0),
					I0 => b(0),   
					I1 => b(1),     
					I2 => sub,
					I3 => '0',
					I4 => '0',					
					I5 => '1');  	
		
--	bComp(2) <= (b(2) xor b(1)).sub or b(2).sub';
--	bComp(3) <= (b(3)'.b(2)'.b(1)'.sub) or (b(3).sub');

	comp23_LUT6 : LUT6_2
				generic map (
					INIT => X"000001f0000066cc")
				port map (
					O6 => bComp(3),  
					O5 => bComp(2),
					I0 => b(1),   
					I1 => b(2),     
					I2 => b(3),
					I3 => sub,
					I4 => '0',					
					I5 => '1');  	

		

end Behavioral;


	
	
	
	
	