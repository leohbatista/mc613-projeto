library ieee;
use ieee.std_logic_1164.all;
use work.tela;
use work.kbd_bowling_ctrl;

entity boliche is

	port(
		SW 					: IN STD_LOGIC_VECTOR(9 downto 0);
		CLOCK				: IN STD_LOGIC;
		KEY				: IN STD_LOGIC_VECTOR(1 downto 0);
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
	type state_type is (reset, inicio, jogando, resultado);

	-- Register to hold the current state
	signal state   : state_type;
	signal state_code: integer RANGE 0 TO 2;

	SIGNAL key_pressed, last_key_state : std_logic;
	--signal placar 
	
	signal players : std_logic_vector (2 downto 0);
	signal players_qtty : integer RANGE 0 TO 6;
	
	type pontos is array (0 to 5) of integer range 0 to 300; 
	signal pontuacao : pontos;
	
	signal jogador_vez : integer range 0 TO 5;
	signal jogada : std_logic;
	signal rodada : integer range 1 to 10;
	signal pinos  : std_logic_vector(9 downto 0);
	signal flag_strike, flag_spare : std_logic;
begin

	t: tela port map (
				GAME_STATE => state_code,
				PINOS => pinos,
				PLAYERS => players_qtty,
				PLAYER => jogador_vez,
				JOGADA => jogada,
				RODADA => rodada,
				SPARE => flag_spare,
				STRIKE => flag_strike,
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
				state <= reset;				
			ELSE
				-- Maquina de estados
				case state is
					when reset =>
						players_qtty <= 0;
						rodada <= 1;
						jogador_vez <= 0;
						jogada <= '0';
						pinos <= "0000000000";
						flag_strike <= '0';
						flag_spare <= '0';
						key_pressed <= '0';
						last_key_state <= '0';
						state <= inicio;
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
						if(KEY(1) = '0') then
							IF(key_pressed = '0' and last_key_state = '0') THEN
								key_pressed <= '1';
								last_key_state <= '1';
							ELSE
								key_pressed <= '0';
								last_key_state <= '1';
							END IF;							
						else
							key_pressed <= '0';
							last_key_state <= '0';
						end if;
						
						if (key_pressed = '1') then
							if(jogada = '0') then
								pinos <= SW(9 downto 0);
								
								if (pinos = "1111111111") then									
									if (jogador_vez = (players_qtty-1)) then 
										jogador_vez <= 0;
										case (rodada) is
											when 10 => state <= resultado;
											when others => rodada <= rodada + 1;
										end case;
									else	
										jogador_vez <= jogador_vez + 1;
									end if;
									
									flag_strike <= '1';
--									for I in 0 to 50000000 loop
--										if(I = 50000000) then
--											flag_strike <= '0';
--											pinos <= "0000000000";
--										end if;
--									end loop;
									
								else
									jogada <= '1';
								end if;								
							else
								pinos <= pinos or SW(9 downto 0);
								
								if (pinos = "1111111111") then
									flag_spare <= '1';
--									for I in 0 to 50000000 loop
--										if(I = 50000000) then
--											flag_spare <= '0';
--											pinos <= "0000000000";
--										end if;
--									end loop;
								end if;
								
								if (jogador_vez = (players_qtty-1)) then 
									jogador_vez <= 0;
									case (rodada) is
										when 10 => state <= resultado;
										when others => rodada <= rodada + 1;
									end case;
								else	
									jogador_vez <= jogador_vez + 1;
								end if;
								--pinos <= "0000000000";
								jogada <= '0';
							end if;
							key_pressed <= '0';
						end if;
					when resultado=>
						
				end case;
			END IF;			
		end if;
	end process;

	-- Output depends solely on the current state
	process (state)
	begin
		case state is
			when reset =>
				state_code <= 0;
			when inicio =>
				state_code <= 0;
			when jogando =>
				state_code <= 1;
			when resultado =>
				state_code <= 2;
		end case;
	end process;

end rtl;
