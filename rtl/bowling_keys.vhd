LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity bowling_keys is
port (
	keys: in std_logic_vector(15 downto 0);
	key_pressed: out std_logic_vector(2 downto 0)
);
end bowling_keys;

ARCHITECTURE LogicFunction OF bowling_keys IS
BEGIN
	PROCESS(keys)
	BEGIN
		CASE (keys(15 downto 0)) IS	
			WHEN x"0069"	=>	key_pressed	<=	"001";	--	Num1
			WHEN x"0072"	=>	key_pressed	<=	"010";	--	Num2
			WHEN x"007A"	=>	key_pressed	<=	"011";	--	Num3
			WHEN x"006B"	=>	key_pressed	<=	"100";	--	Num4
			WHEN x"0073"	=>	key_pressed	<=	"101";	--	Num5
			WHEN x"0074"	=>	key_pressed	<=	"110";	--	Num6
			WHEN x"E05A"	=>	key_pressed	<=	"111";	--	NumEnter
			WHEN OTHERS	   =>	key_pressed	<=	"000";		
		END CASE;
	END PROCESS;
END LogicFunction ;