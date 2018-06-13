LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tela IS
	PORT (
		GAME_STATE			: IN INTEGER RANGE 0 TO 2;
		PINOS					: IN STD_LOGIC_VECTOR(0 to 9);
		PLAYERS				: IN INTEGER RANGE 0 TO 6;
		PLAYER				: IN INTEGER RANGE 0 TO 5;
		JOGADA				: IN INTEGER RANGE 0 TO 2;
		RODADA				: IN INTEGER RANGE 1 TO 10;
		PONTUACAO_1			: IN INTEGER RANGE 0 TO 300;
		PONTUACAO_2			: IN INTEGER RANGE 0 TO 300;
		PONTUACAO_3			: IN INTEGER RANGE 0 TO 300;
		PONTUACAO_4			: IN INTEGER RANGE 0 TO 300;
		PONTUACAO_5			: IN INTEGER RANGE 0 TO 300;
		PONTUACAO_6			: IN INTEGER RANGE 0 TO 300;
		SPARE, STRIKE		: IN STD_LOGIC;
		CLOCK_50				: IN STD_LOGIC;
		KEY				: IN STD_LOGIC_VECTOR(0 downto 0);
		VGA_R, VGA_G, VGA_B	: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		VGA_HS, VGA_VS		: OUT STD_LOGIC;
		VGA_BLANK_N, VGA_SYNC_N : OUT STD_LOGIC;
		VGA_CLK : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE behavior OF tela IS
	COMPONENT vgacon IS
		GENERIC (
			NUM_HORZ_PIXELS : NATURAL := 128;	-- Number of horizontal pixels
			NUM_VERT_PIXELS : NATURAL := 96		-- Number of vertical pixels
		);
		PORT (
			clk50M, rstn              : IN STD_LOGIC;
			write_clk, write_enable   : IN STD_LOGIC;
			write_addr                : IN INTEGER RANGE 0 TO NUM_HORZ_PIXELS * NUM_VERT_PIXELS - 1;
			data_in                   : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
			vga_clk                   : buffer std_logic;
			red, green, blue          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			hsync, vsync              : OUT STD_LOGIC;
			sync, blank					  : OUT STD_LOGIC
		);
	END COMPONENT;
	
	CONSTANT CONS_CLOCK_DIV : INTEGER := 1000000;
	CONSTANT HORZ_SIZE : INTEGER := 160;
	CONSTANT VERT_SIZE : INTEGER := 120;
	
	SIGNAL slow_clock, pixel_out : STD_LOGIC;
	
	SIGNAL clear_video_address	,
		normal_video_address	,
		video_address			: INTEGER RANGE 0 TO HORZ_SIZE * VERT_SIZE - 1;
	
	SIGNAL x: INTEGER RANGE 0 TO HORZ_SIZE - 1;
	SIGNAL y: INTEGER RANGE 0 TO VERT_SIZE - 1;
	
	SIGNAL clear_video_word		,
		normal_video_word		,
		video_word				: STD_LOGIC_VECTOR (2 DOWNTO 0);
	
	TYPE VGA_STATES IS (NORMAL, CLEAR);
	SIGNAL state : VGA_STATES;
	
	signal switch, rstn, clk50M, sync, blank : std_logic;
	
BEGIN
	switch <= '1';
	rstn <= KEY(0);
	clk50M <= CLOCK_50;
	vga_component: vgacon
	GENERIC MAP (
		NUM_HORZ_PIXELS => HORZ_SIZE,
		NUM_VERT_PIXELS => VERT_SIZE
	) PORT MAP (
		clk50M			=> clk50M		,
		rstn			=> rstn		,
		write_clk		=> clk50M		,
		write_enable	=> '1'			,
		write_addr      => video_address,
		vga_clk		=> VGA_CLK,
		data_in         => video_word	,
		red				=> VGA_R		,
		green			=> VGA_G		,
		blue			=> VGA_B		,
		hsync			=> VGA_HS		,
		vsync			=> VGA_VS		,
		sync			=> sync		,
		blank			=> blank
	);
	VGA_SYNC_N <= NOT sync;
	VGA_BLANK_N <= NOT blank;
	
	video_word <= normal_video_word WHEN state = NORMAL ELSE clear_video_word;
	
	video_address <= normal_video_address WHEN state = NORMAL ELSE clear_video_address;

	clock_divider:
	PROCESS (clk50M, rstn)
		VARIABLE i : INTEGER := 0;
	BEGIN
		IF (rstn = '0') THEN
			i := 0;
			slow_clock <= '0';
		ELSIF (rising_edge(clk50M)) THEN
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
	
	vga_clear:
	PROCESS(clk50M, rstn, clear_video_address)
	BEGIN
		IF (rstn = '0') THEN
			state <= CLEAR;
			clear_video_address <= 0;
			clear_video_word <= "000";
		ELSIF (rising_edge(clk50M)) THEN
			CASE state IS
				WHEN CLEAR =>
					clear_video_address <= clear_video_address + 1;
					clear_video_word <= "000";
					IF (clear_video_address < HORZ_SIZE * VERT_SIZE-1) THEN
						state <= CLEAR;
					ELSE
						state <= NORMAL;
					END IF;
				WHEN NORMAL =>
					state <= NORMAL;
			END CASE;
		END IF;	
	END PROCESS;
				
	vga_writer:
	PROCESS (clk50M, rstn, normal_video_address)
	BEGIN
		IF (rstn = '0') THEN
			normal_video_address <= 0;
			normal_video_word <= "000";
		ELSIF (rising_edge(clk50M)) THEN
			normal_video_word <= "000";
			IF (GAME_STATE = 0) THEN
				-- LABEL "BOLICHE"
				if (	((y>=21 and y<=40) and (x=45 or x=46 or x=53 or x=69 or x=70 or x=97 or x=98 or x=105 or x=106)) or 
						((y>=23 and y<=38) and (x=54 or x=57 or x=58 or x=65 or x=66 or x=85 or x=86 or x=109 or x=110)) or
						((y>=25 and y<=40) and (x=81 or x=82)) or
						((y=21 or y=22) and ((x>=47 and x<=53) or (x>=59 and x<=64) or x=81 or x=82 or (x>=87 and x<=94) or (x>=111 and x<=118))) or
						((y=30 or y=31) and ((x>=47 and x<=53) or (x>=99 and x<=104) or (x>=111 and x<=118))) or
						((y=39 or y=40) and ((x>=47 and x<=53) or (x>=59 and x<=64) or (x>=71 and x<=78) or (x>=87 and x<=94) or (x>=111 and x<=118)))
					) then
					normal_video_word <= "111";
				end if;	
				
				-- LABEL "JOGADOR:"
				if (	((y=67) and ((x>=29 and x<=32) or x=35 or x=36 or (x>=40 and x<=42) or x=45 or x=46 or (x>=49 and x<=51) or x=55 or x=56 or (x>=59 and x<=61) or (x>=65 and x<=67) or (x>=70 and x<=72))) or 
						((y=68) and (x=32 or x=34 or x=37 or x=39 or x=44 or x=47 or x=49 or x=52 or x=54 or x=57 or x=59 or x=62 or x=64 or x=69)) or 
						((y=69) and (x=32 or x=34 or x=37 or x=39 or x=44 or x=47 or x=49 or x=52 or x=54 or x=57 or x=59 or x=62 or x=64 or x=69 or x=75)) or 
						((y=70) and (x=32 or x=34 or x=37 or x=39 or x=41 or x=42 or x=44 or x=47 or x=49 or x=52 or x=54 or x=57 or (x>=59 and x<=61) or (x>=64 and x<=67) or x=70 or x=71)) or 
						((y=71) and (x=29 or x=32 or x=34 or x=37 or x=39 or x=42 or (x>=44 and x<=47) or x=49 or x=52 or x=54 or x=57 or x=59 or x=60 or x=64 or x=72)) or 
						((y=72) and (x=29 or x=32 or x=34 or x=37 or x=39 or x=42 or x=44 or x=47 or x=49 or x=52 or x=54 or x=57 or x=59 or x=61 or x=64 or x=72 or x=75)) or 
						((y=73) and (x=30 or x=31 or x=35 or x=36 or x=40 or x=41 or x=44 or x=47 or (x>=49 and x<=51) or x=55 or x=56 or x=59 or x=62 or (x>=65 and x<=67) or (x>=69 and x<=71)) ) ) then 
					normal_video_word <= "111";
				end if;
				
				-- PLAYER NUMBER
				IF (PLAYERS = 1) THEN
					-- 1
					if (((x=80 or x=81) and (y=66 or y=67 or y=73 or y=74)) or ((x=82 or x=83) and (y>=65 and y<=74)) or ((x=84 or x=85) and (y=73 or y=74))) then
						normal_video_word <= "111";
					end if;
				ELSIF (PLAYERS = 2) THEN				
					-- 2
					if (((x>=80 and x<=85) and (y=65 or y=66 or y=69 or y=70 or y=73 or y=74)) or ((x=80 or x=81) and (y=71 or y=72)) or ((x=84 or x=85) and (y=67 or y=68))) then
						normal_video_word <= "111";
					end if;
				ELSIF (PLAYERS = 3) THEN
					-- 3
					if (((x>=80 and x<=85) and (y=65 or y=66 or y=69 or y=70 or y=73 or y=74)) or ((x=84 or x=85) and (y=71 or y=72)) or ((x=84 or x=85) and (y=67 or y=68))) then
						normal_video_word <= "111";
					end if;
				ELSIF (PLAYERS = 4) THEN
					-- 4
					if (((x=80 or x=81) and (y>=65 and y<=70)) or ((x=82 or x=83) and (y=69 or y=70)) or ((x=84 or x=85) and (y>=65 and y<=74))) then
						normal_video_word <= "111";
					end if;
				ELSIF (PLAYERS = 5) THEN
					-- 5
					if (((x>=80 and x<=85) and (y=65 or y=66 or y=69 or y=70 or y=73 or y=74)) or ((x=80 or x=81) and (y=67 or y=68)) or ((x=84 or x=85) and (y=71 or y=72))) then
						normal_video_word <= "111";
					end if;
				ELSIF (PLAYERS = 6) THEN
					-- 6
					if (((x>=80 and x<=85) and (y=65 or y=66 or y=69 or y=70 or y=73 or y=74)) or ((x=80 or x=81) and (y=67 or y=68)) or ((x=80 or x=81 or x=84 or x=85) and (y=71 or y=72))) then
						normal_video_word <= "111";
					end if;
				END IF;
				
			ELSIF(GAME_STATE = 1) THEN
			
				-- GAME SCREEN
				
				-- Label "Bola:"
				if( ((y=45) AND (x=2 or x=3 or x=6 or x=7 or x=8 or x=10 or x=14 or x=15 or x=16)) or
					 ((y=46 or y=48) AND (x=2 or x=4 or x=6 or x=8 or x=10 or x=14 or x=16 or x=18)) or
					 ((y=47) AND (x=2 or x=3 or x=4 or x=6 or x=8 or x=10 or x=14 or x=15 or x=16)) or
					 ((y=49) AND (x=2 or x=3 or x=6 or x=7 or x=8 or x=10 or x=11 or x=12 or x=14 or x=16)) ) then
					normal_video_word <= "111";
				end if;
				
				-- Num Bola
				IF(JOGADA = 0) THEN
					IF( ((x=20) and (y=46 or y=49))	or
						 ((x=21) and (y>=45 and y<=49)) or
						 ((x=22) and (y=49)) ) THEN
						normal_video_word <= "110";
					END IF;
				ELSIF(JOGADA = 1) THEN
					IF( ((x=20 or x=21 or x=22) and (y=45 or y=47 or y=49)) or
						 ((x=22) and (y=46)) or
						 ((x=20) and (y=48)) ) THEN
						normal_video_word <= "110";
					END IF;
				ELSE
					IF( ((x=20 or x=21 or x=22) and (y=45 or y=47 or y=49)) or
						 ((x=22) and (y=46 or y=48)) ) THEN
						normal_video_word <= "011";
					END IF;	
				END IF;
				
				-- Label "Player:"
				if( ((y=51) AND (x=2 or x=3 or x=4 or x=6 or x=10 or x=11 or x=12 or x=14 or x=16 or x=18 or x=19 or x=20 or x=22 or x=23)) or
					 ((y=52) AND (x=2 or x=4 or x=6 or x=10 or x=12 or x=14 or x=16 or x=18 or x=22 or x=24 or x=26)) or
					 ((y=53) AND (x=2 or x=3 or x=4 or x=6 or x=10 or x=11 or x=12 or x=15 or x=18 or x=19 or x=20 or x=22 or x=23)) or
					 ((y=54) AND (x=2 or x=6 or x=10 or x=12 or x=15 or x=18 or x=22 or x=24 or x=26)) or
					 ((y=55) AND (x=2 or x=6 or x=7 or x=8 or x=10 or x=12 or x=15 or x=18 or x=19 or x=20 or x=22 or x=24)) ) then
					normal_video_word <= "111";
				end if;
				
				-- Label "Pontos"
				
				-- Num Player
				IF(PLAYER = 0) THEN
					IF( ((x=28) and (y=52 or y=55))	or
						 ((x=29) and (y>=51 and y<=55)) or
						 ((x=30) and (y=55)) ) THEN
						normal_video_word <= "011";
					END IF;
					
				ELSIF(PLAYER = 1) THEN
					IF( ((x=28 or x=29 or x=30) and (y=51 or y=53 or y=55)) or
						 ((x=30) and (y=52)) or
						 ((x=28) and (y=54)) ) THEN
						normal_video_word <= "011";
					END IF;
				ELSIF(PLAYER = 2) THEN
					IF( ((x=28 or x=29 or x=30) and (y=51 or y=53 or y=55)) or
						 ((x=30) and (y=52 or y=54)) ) THEN
						normal_video_word <= "011";
					END IF;
				ELSIF(PLAYER = 3) THEN
					IF( ((x=28) and (y=51 or y=52 or y=53))	or
						 ((x=29) and (y=53)) or
						 ((x=30) and (y>=51 and y<=55)) ) THEN
						normal_video_word <= "011";
					END IF;
				ELSIF(PLAYER = 4) THEN
					IF( ((x=28 or x=29 or x=30) and (y=51 or y=53 or y=55)) or
						 ((x=28) and (y=52)) or
						 ((x=30) and (y=54)) ) THEN
						normal_video_word <= "011";
					END IF;
				ELSIF(PLAYER = 5) THEN
					IF( ((x=28 or x=29 or x=30) and (y=51 or y=53 or y=55)) or
						 ((x=28) and (y=52 or y=54)) or
						 ((x=30) and (y=54)) ) THEN
						normal_video_word <= "011";
					END IF;
				END IF;							
				
				-- Label "Rodada:"
				if( ((y=57) AND (x=2 or x=3 or x=6 or x=7 or x=8 or x=10 or x=11 or x=14 or x=15 or x=16 or x=18 or x=19 or x=22 or x=23 or x=2)) or
					 ((y=58) AND (x=2 or x=4 or x=6 or x=8 or x=10 or x=12 or x=14 or x=16 or x=18 or x=20 or x=22 or x=24 or x=26)) or
					 ((y=59) AND (x=2 or x=3 or x=6 or x=8 or x=10 or x=12 or x=14 or x=15 or x=16 or x=18 or x=20 or x=22 or x=23 or x=24)) or
					 ((y=60) AND (x=2 or x=4 or x=6 or x=8 or x=10 or x=12 or x=14 or x=16 or x=18 or x=20 or x=22 or x=24 or x=26)) or
					 ((y=61) AND (x=2 or x=4 or x=6 or x=7 or x=8 or x=10 or x=11 or x=14 or x=16 or x=18 or x=19 or x=22 or x=24)) ) then
					normal_video_word <= "111";
				end if;
				
				-- Num Rodada
				IF(RODADA = 1) THEN
					IF( ((x=28) and (y=58 or y=61))	or
						 ((x=29) and (y>=57 and y<=61)) or
						 ((x=30) and (y=61)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 2) THEN
					IF( ((x=28 or x=29 or x=30) and (y=57 or y=59 or y=61)) or
						 ((x=30) and (y=58)) or
						 ((x=28) and (y=60)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 3) THEN
					IF( ((x=28 or x=29 or x=30) and (y=57 or y=59 or y=61)) or
						 ((x=30) and (y=58 or y=60)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 4) THEN
					IF( ((x=28) and (y=57 or y=58 or y=59))	or
						 ((x=29) and (y=59)) or
						 ((x=30) and (y>=57 and y<=61)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 5) THEN
					IF( ((x=28 or x=29 or x=30) and (y=57 or y=59 or y=61)) or
						 ((x=28) and (y=58)) or
						 ((x=30) and (y=60)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 6) THEN
					IF( ((x=28 or x=29 or x=30) and (y=57 or y=59 or y=61)) or
						 ((x=28) and (y=58 or y=60)) or
						 ((x=30) and (y=60)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 7) THEN
					IF( ((x=28) and (y=57 or y=59))	or
						 ((x=29) and (y>=57 and y<=61)) or
						 ((x=30) and (y=59)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 8) THEN
					IF( ((x=28 or x=29 or x=30) and (y=57 or y=59 or y=61)) or
						 ((x=28 or x=30) and (y=58 or y=60)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 9) THEN
					IF( ((x=28 or x=29 or x=30) and (y=57 or y=59 or y=61)) or
						 ((x=30) and (y=58 or y=60)) or
						 ((x=28) and (y=58)) ) THEN
						normal_video_word <= "101";
					END IF;
				ELSIF(RODADA = 10) THEN
					IF( ((x=28) and (y=58 or y=61))	or
						 ((x=29 or x=32 or x=34) and (y>=57 and y<=61)) or
						 ((x=30) and (y=61)) or
						 ((x=33) AND (y=57 or y=61))	) THEN
						normal_video_word <= "101";
					END IF;
				END IF;
				
				
				
				-- Pino 6	
				if ((x>=5 and x<=9 and y>=5 and y<=9)) then
					if PINOS(6) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 7	
				if ((x>=13 and x<=17 and y>=5 and y<=9)) then
					if PINOS(7) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 8	
				if ((x>=21 and x<=25 and y>=5 and y<=9)) then
					if PINOS(8) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 9	
				if ((x>=29 and x<=33 and y>=5 and y<=9)) then
					if PINOS(9) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 3	
				if ((x>=9 and x<=13 and y>=13 and y<=17)) then
					if PINOS(3) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 4	
				if ((x>=17 and x<=21 and y>=13 and y<=17)) then
					if PINOS(4) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 5	
				if ((x>=25 and x<=29 and y>=13 and y<=17)) then
					if PINOS(5) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 1	
				if ((x>=13 and x<=17 and y>=21 and y<=25)) then
					if PINOS(1) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 2	
				if ((x>=21 and x<=25 and y>=21 and y<=25)) then
					if PINOS(2) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
				
				-- Pino 0	
				if ((x>=17 and x<=21 and y>=29 and y<=33)) then
					if PINOS(0) = '0' THEN normal_video_word <= "111"; ELSE normal_video_word <= "100"; END IF;
				end if;
		
				if(x = 39) then normal_video_word <= "111"; end if;
				
				if (STRIKE='1') then normal_video_word <= "100";
				elsif (SPARE='1') then normal_video_word <= "100";
				end if;
				
			ELSE
				normal_video_word <= "110";
			END IF;
			
			normal_video_address <= x + y * HORZ_SIZE;
			
			if(x = HORZ_SIZE-1) then 
				y <= y + 1;
				x <= 0;
			else
				x <= x + 1;
			end if;

		END IF;	
	END PROCESS;
END ARCHITECTURE;