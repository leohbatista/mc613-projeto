library ieee;
use ieee.std_logic_1164.all;
use work.bowling_keys;

entity kbd_bowling is
  port (
    clk : in std_logic;
    key_on : in std_logic_vector(2 downto 0);
    key_code : in std_logic_vector(47 downto 0);
    key_pressed : out std_logic_vector(2 downto 0)
  );
end kbd_bowling;

architecture rtl of kbd_bowling is
	signal ascii_bin : std_logic_vector(7 downto 0);
	signal key_bin : std_logic_vector(15 downto 0); -- value to be shown in display
begin
	kb: bowling_keys port map (keys => key_code (15 downto 0), key_pressed => key_pressed);	
end rtl;
