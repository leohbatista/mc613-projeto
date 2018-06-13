library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use work.tela;
use work.kbd_bowling_ctrl;

entity boliche is

	port(
		SW 					: IN STD_LOGIC_VECTOR(9 downto 0);
		LEDR					: OUT STD_LOGIC_VECTOR(9 downto 0);
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
	
	SIGNAL slow_clock : STD_LOGIC;
	CONSTANT CONS_CLOCK_DIV : INTEGER := 1000000;
	
	-- Build an enumerated type for the state machine
	type state_type is (reset, inicio, jogando, resultado);

	-- Register to hold the current state
	signal state   : state_type;
	signal state_code: integer RANGE 0 TO 2;

	SIGNAL key_pressed, last_key_state : std_logic;
	
	signal players : std_logic_vector (2 downto 0);
	signal players_qtty : integer RANGE 0 TO 6;
	
	type pontos is array (0 to 5) of integer range 0 to 300; 
	signal pontuacao : pontos;
	
	--type strikes is array (0 to 5) of std_logic_vector(0 to 1);
	--signal strike_marks : strikes;
	
	--signal spare_marks : std_logic_vector(0 to 5);
	
	signal spares : std_logic_vector(0 to 5);
	signal strikes : std_logic_vector(0 to 5);
	
	signal jogador_vez : integer range 0 TO 5;
	signal jogada : integer range 0 to 2;
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
				PONTUACAO_1 => pontuacao(0),
				PONTUACAO_2 => pontuacao(1),
				PONTUACAO_3 => pontuacao(2),
				PONTUACAO_4 => pontuacao(3),
				PONTUACAO_5 => pontuacao(4),
				PONTUACAO_6 => pontuacao(5),
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
		
	clock_divider:
	PROCESS (CLOCK, KEY(0))
		VARIABLE i : INTEGER := 0;
	BEGIN
		IF (KEY(0) = '0') THEN
			i := 0;
			slow_clock <= '0';
		ELSIF (rising_edge(CLOCK)) THEN
			IF (i <= CONS_CLOCK_DIV/2) THEN
				i := i + 1;
				slow_clock <= '0';
			ELSIF (i < CONS_CLOCK_DIV-1) THEN
				i := i + 1;
				slow_clock <= '1';
			ELSE		
				i := 0;
			END IF;	
		END IF;
	END PROCESS;
	

	-- Logic to advance to the next state
	process (CLOCK)
		variable pontos_pinos : natural;
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
						jogada <= 0;
						pinos <= "0000000000";
						flag_strike <= '0';
						flag_spare <= '0';
						pontuacao(0) <= 0;
						pontuacao(1) <= 0;
						pontuacao(2) <= 0;
						pontuacao(3) <= 0;
						pontuacao(4) <= 0;
						pontuacao(5) <= 0;
						strikes <= "000000";
						spares <= "000000";
						
						key_pressed <= '0';
						last_key_state <= '0';
						state <= inicio;
						pontos_pinos := 0;
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
							
							if(jogada = 0) then
								pinos <= SW(9 downto 0);
								pontos_pinos := 0;
								for i in pinos'range loop
									if pinos(i) = '1' then
										pontos_pinos := pontos_pinos + 1;
									end if;
								end loop;								
								
								flag_spare <= '0';
								
								-- Se rodada anterior foi spare, soma pinos derrubados na primeira jogada
								if(spares(jogador_vez) = '1') then
									pontuacao(jogador_vez) <= pontuacao(jogador_vez) + pontos_pinos;
									spares(jogador_vez) <= '1';
								end if;

								if (pontos_pinos = 10) then						
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
									strikes(jogador_vez) <= '1';
									pinos <= "0000000000";
								else
									jogada <= 1;
									flag_strike <= '0';
									strikes(jogador_vez) <= '0';
								end if;								
							else
								pinos <= pinos or SW(9 downto 0);
								for i in pinos'range loop
									if pinos(i) = '1' then
										pontos_pinos := pontos_pinos + 1;
									end if;
								end loop;
								
								
								-- Incrementa pontuacao
								pontuacao(jogador_vez) <= pontuacao(jogador_vez) + pontos_pinos;
								
								-- Se rodada anterior foi strike, soma os pinos derrubados novamente
								if(strikes(jogador_vez) = '1') then
									pontuacao(jogador_vez) <= pontuacao(jogador_vez) + pontos_pinos;
									strikes(jogador_vez) <= '0';
								end if;
								
								if (pontos_pinos = 10) then
									-- Foi spare nessa rodada
									flag_spare <= '1';
									spares(jogador_vez) <= '1';
								else 
									flag_spare <= '0';
									spares(jogador_vez) <= '0';
								end if;
								
								pinos <= "0000000000";
								
								if (jogador_vez = (players_qtty-1)) then 
									jogador_vez <= 0;
									case (rodada) is
										when 10 => state <= resultado;
										when others => rodada <= rodada + 1;
									end case;
								else	
									jogador_vez <= jogador_vez + 1;
								end if;
								
								jogada <= 0;
							end if;
							key_pressed <= '0';
							
						end if;
						LEDR(0) <= flag_spare;
						LEDR(1) <= flag_strike;
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
