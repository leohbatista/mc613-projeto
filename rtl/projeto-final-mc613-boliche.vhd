library ieee;
use ieee.std_logic_1164.all;
use work.tela;

entity boliche is

	port(
		SW 					: IN STD_LOGIC_VECTOR(9 downto 0);
		CLOCK				: IN STD_LOGIC;
		KEY				: IN STD_LOGIC_VECTOR(1 downto 0);
		VGA_R, VGA_G, VGA_B	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		VGA_HS, VGA_VS		: OUT STD_LOGIC;
		VGA_BLANK_N, VGA_SYNC_N : OUT STD_LOGIC;
		VGA_CLK : OUT STD_LOGIC
	);

end entity;

architecture rtl of boliche is

	-- Build an enumerated type for the state machine
	type state_type is (inicio, jogando, resultado);

	-- Register to hold the current state
	signal state   : state_type;
	signal state_code: integer RANGE 0 TO 2;

	SIGNAL key_pressed, last_key_state : std_logic;
	--signal placar 
begin

	t: tela port map (
				GAME_STATE => state_code,
				PINOS => SW,
				CLOCK_50 => CLOCK,
				KEY => KEY(0 DOWNTO 0),
				VGA_R => VGA_R, VGA_G => VGA_G, VGA_B => VGA_B,
				VGA_HS => VGA_HS, VGA_VS => VGA_VS,
				VGA_BLANK_N => VGA_BLANK_N, VGA_SYNC_N => VGA_SYNC_N, VGA_CLK => VGA_CLK);

	-- Logic to advance to the next state
	process (CLOCK,KEY(1))
	begin	
		if (rising_edge(CLOCK)) then
			-- Tratamento de se o botao continua apertado
			IF(KEY(1) = '0') THEN
				IF(key_pressed = '0' and last_key_state = '0') THEN
					key_pressed <= '1';
					last_key_state <= '1';
				ELSE
					key_pressed <= '0';
					last_key_state <= '1';
				END IF;
			ELSE
				key_pressed <= '0';
				last_key_state <= '0';
			END IF;
			
			-- Maquina de estados
			case state is
				when inicio=>
					if key_pressed = '1' then
						state <= jogando;
						key_pressed <= '0';	
					else
						state <= inicio;
					end if;
				when jogando=>
					if key_pressed = '1' then
						state <= resultado;
						key_pressed <= '0';	
					else
						state <= jogando; 
					end if;
				when resultado=>
					if key_pressed = '1' then
						state <= inicio;
						key_pressed <= '0';	
					else
						state <= resultado;
					end if;
			end case;
		end if;
	end process;

	-- Output depends solely on the current state
	process (state)
	begin
		case state is
			when inicio =>
				state_code <= 0;
			when jogando =>
				state_code <= 1;
			when resultado =>
				state_code <= 2;
		end case;
	end process;

end rtl;
