library ieee;
use ieee.std_logic_1164.all;
use work.tela;
use work.kbd_bowling_ctrl;

entity boliche is

	port(
		SW 					: IN STD_LOGIC_VECTOR(9 downto 0);
		CLOCK				: IN STD_LOGIC;
		KEY				: IN STD_LOGIC_VECTOR(0 downto 0);
		VGA_R, VGA_G, VGA_B	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		VGA_HS, VGA_VS		: OUT STD_LOGIC;
		VGA_BLANK_N, VGA_SYNC_N : OUT STD_LOGIC;
		VGA_CLK : OUT STD_LOGIC;
		PS2_DAT : inout STD_LOGIC;
		PS2_CLK : inout STD_LOGIC
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
	
	signal players : std_logic_vector (2 downto 0);
	signal players_qtty : integer RANGE 0 TO 6;
begin

	t: tela port map (
				GAME_STATE => state_code,
				PINOS => SW,
				PLAYERS => players_qtty,
				CLOCK_50 => CLOCK,
				KEY => KEY(0 DOWNTO 0),
				VGA_R => VGA_R, VGA_G => VGA_G, VGA_B => VGA_B,
				VGA_HS => VGA_HS, VGA_VS => VGA_VS,
				VGA_BLANK_N => VGA_BLANK_N, VGA_SYNC_N => VGA_SYNC_N, VGA_CLK => VGA_CLK
		);
				
	k: kbd_bowling_ctrl port map (
				CLOCK_50 => CLOCK,
				PS2_DAT => PS2_DAT,
				PS2_CLK => PS2_CLK,
				KEY => players
		);			

	-- Logic to advance to the next state
	process (CLOCK)
	begin	
		if (rising_edge(CLOCK)) then
			-- Tratamento de se o botao continua apertado
			IF(KEY(0) = '0') THEN
				state <= inicio;
				players_qtty <= 0;
			ELSE
				-- Maquina de estados
				case state is
					when inicio=>					
						case (players(2 downto 0)) is
							when "001" => players_qtty <= 1;
							when "010" => players_qtty <= 2;
							when "011" => players_qtty <= 3;
							when "100" => players_qtty <= 4;
							when "101" => players_qtty <= 5;
							when "110" => players_qtty <= 6;
							when others => players_qtty <= players_qtty;
						end case;
						
						if(players(2 downto 0)="111" AND players_qtty > 0) then
							state <= jogando;
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
			END IF;			
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
