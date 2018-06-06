LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity keycode2ascii is
port (
	keys: in std_logic_vector(15 downto 0);
	ascii: out std_logic_vector(7 downto 0)
);
end keycode2ascii;

ARCHITECTURE LogicFunction OF keycode2ascii IS
BEGIN
	CASE aux_keys IS	
		WHEN x"0070"	=>	ascii	<=	"00110000";	--	Num0
		WHEN x"0069"	=>	ascii	<=	"00110001";	--	Num1
		WHEN x"0072"	=>	ascii	<=	"00110010";	--	Num2
		WHEN x"007A"	=>	ascii	<=	"00110011";	--	Num3
		WHEN x"006B"	=>	ascii	<=	"00110100";	--	Num4
		WHEN x"0073"	=>	ascii	<=	"00110101";	--	Num5
		WHEN x"0074"	=>	ascii	<=	"00110110";	--	Num6
		WHEN x"006C"	=>	ascii	<=	"00110111";	--	Num7
		WHEN x"0075"	=>	ascii	<=	"00111000";	--	Num8
		WHEN x"007D"	=>	ascii	<=	"00111001";	--	Num9
		WHEN x"E04A"	=>	ascii	<=	"00111011";	--	Num/
		WHEN x"0079"	=>	ascii	<=	"00101011";	--	Num+
		WHEN x"007B"	=>	ascii	<=	"00101101";	--	Num-
		WHEN x"007C"	=>	ascii	<=	"00101010";	--	Num*
		WHEN x"0071"	=>	ascii	<=	"00101110";	--	Num.
		WHEN x"E05A"	=>	ascii	<=	"00001010";	--	NumEnter
		WHEN OTHERS	   =>	ascii	<=	"00000000";		
	END CASE;	
END LogicFunction ;