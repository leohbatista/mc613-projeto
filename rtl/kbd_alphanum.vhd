library ieee;
use ieee.std_logic_1164.all;
use work.keycode2ascii;
use work.bin2hex;

entity kbd_alphanum is
  port (
    clk : in std_logic;
    key_on : in std_logic_vector(2 downto 0);
    key_code : in std_logic_vector(47 downto 0);
    HEX1 : out std_logic_vector(6 downto 0); -- GFEDCBA
    HEX0 : out std_logic_vector(6 downto 0) -- GFEDCBA
  );
end kbd_alphanum;

architecture rtl of kbd_alphanum is
	signal ascii_bin : std_logic_vector(7 downto 0);
	signal key_bin : std_logic_vector(15 downto 0); -- value to be shown in display
	signal aux_hex0,aux_hex1: std_logic_vector(6 downto 0);
begin
	k2a_0: keycode2ascii port map (keys => key_code, ascii => ascii_bin);
	b2h_0: bin2hex port map (SW => ascii_bin(3 downto 0), HEX0 => aux_hex0);
	b2h_1: bin2hex port map (SW => ascii_bin(7 downto 4), HEX0 => aux_hex1);
	
	process(ascii_bin)
	begin
		if (ascii_bin = "00000000") then
			HEX0 <= "1111111";
			HEX1 <= "1111111";
		else
			HEX0 <= aux_hex0;
			HEX1 <= aux_hex1;
		end if;
	end process;
	
end rtl;
