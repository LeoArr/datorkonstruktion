--------------------------------------------------------------------------------
-- VGA MOTOR
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity VGA_MOTOR is
  port ( clk			: in std_logic;
         switches               : in std_logic_vector(7 downto 0);	-- switcharnas värde
	 data			: in std_logic_vector(7 downto 0);	-- Data från cpun
	 vgaRed		        : out std_logic_vector(2 downto 0);	-- röd
	 vgaGreen	        : out std_logic_vector(2 downto 0);	-- grön
	 vgaBlue		: out std_logic_vector(2 downto 1);	-- blå
	 Hsync		        : out std_logic;			-- horisontell sync signal
	 Vsync		        : out std_logic);			-- vertikal sync signal
end VGA_MOTOR;


-- architecture
architecture Behavioral of VGA_MOTOR is

  signal	Xpixel	        : unsigned(9 downto 0);         -- Horizontal pixel counter
  signal	Ypixel	        : unsigned(9 downto 0);		-- Vertical pixel counter
  signal	ClkDiv	        : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
  signal	Clk25		: std_logic;			-- One pulse width 25 MHz signal
		
  signal 	tilePixel       : std_logic_vector(7 downto 0);	-- Tile pixel data
  signal	pMemAddr	: unsigned(19 downto 0);	-- Tile address

  signal        blank           : std_logic;                    -- blanking signal
  signal        we              : std_logic := '0';             -- write enable
  signal        cursor          : std_logic;

  signal data_buf : std_logic_vector(7 downto 0) := x"00";  -- for storing previous data value
  signal command : std_logic_vector(1 downto 0) := "00";
  -- command 0: NOP
  -- command 1: sätt x
  -- command 2: sätt y
  -- command 3: sätt we


  --upplösning 80/60 ger 19200 bytes av bilddata vilket är lagom?
  -- då blir varje pixel 4ggr så stor
  --|00...................79,0|
  --|0,1..................79,1|
  --           ...
  --|....................79,59|
  
  -- Tile memory type
  type minne is array (0 to (2048*3 - 1)) of std_logic_vector(7 downto 0);

-- pic memory
  signal picMem : minne := (others => x"FF");	-- vit som default färg
  signal xcoord : unsigned(9 downto 0) := "0000101000"; -- curson börjar mitt på skärmen x = 40 y = 30
  signal ycoord : unsigned(9 downto 0) := "0000011110";
  
begin

  --Hanterar kommadon från cpu eller whatever
  --kollar om data-signal har ändrats, isf
  --om commando = 00 (standardläget) uppdaterar vi commando enl data
  -- nästa gång data ändras gör vi det tidigare valda commandot mha nya datasignalen
  process(clk)
  begin
    if rising_edge(clk) then
      if data /= data_buf then	-- kollar att vi har fått ny data 
        if command = "00" or data(7) = '1' then -- kollar om vi har fått signal eller är på NOP
          case data is
            when x"80" => command <= "00";  --NOP
            when x"81" => command <= "01";  --x
            when x"82" => command <= "10";  --y
            when x"83" => command <= "11";  --we, write enable 
            when others => null;
          end case;
          data_buf <= data;
        else
          case command is
            when "01" => Xcoord <= unsigned("0000000000" or "00" & data);
            when "10" => Ycoord <= unsigned("0000000000" or "00" & data);
            when "11" => we <= not we;
            when others => null;
          end case;
          command <= "00";
          data_buf <= data;
        end if;
      end if;
    end if;
  end process;

  -- picture memory address composite
  pMemAddr <= Ypixel/8*80 + Xpixel/8;

  --skriv till bildminnet
  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        picMem(to_integer(Ycoord*80 + Xcoord)) <= switches;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if pMemAddr = Ycoord*80 + Xcoord then
        cursor <= '1';
      else
        cursor <= '0';
      end if;
    end if;
  end process;

  --skicka ut ratt pixel eller blank
  process(clk)
  begin
    if rising_edge(clk) then
      if blank = '0' then
        tilePixel <= picMem(to_integer(pMemAddr));
      else
        tilePixel <= (others => '0');
      end if;
    end if;
  end process;
    
  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
      ClkDiv <= ClkDiv + 1;
    end if;
  end process;
	
  -- 25 MHz clock (one system clock pulse width)
  Clk25 <= '1' when (ClkDiv = 3) else '0';
	
	
  -- Horizontal pixel counter

  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' then
        if  Xpixel = 800 then
          Xpixel <= "0000000000";
        else
          Xpixel <= Xpixel + "1";
        end if;
      end if;
    end if;
  end process;


  
  -- Horizontal sync

  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' then
        if  Xpixel > 656 and Xpixel < 752 then
          Hsync <= '0';
        else
          Hsync <= '1';
        end if;
      end if;
    end if;
  end process;
  

  
  -- Vertical pixel counter

  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' then
        if  Ypixel = 521 then
          Ypixel <= "0000000000";
        else
          if Xpixel = 800 then
            Ypixel <= Ypixel + "1";
          end if;
        end if;
      end if;
    end if;
  end process;

	

  -- Vertical sync

  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' then
        if  Ypixel > 490 and Ypixel < 492 then
          Vsync <= '0';
        else
          Vsync <= '1';
        end if;
      end if;
    end if;
    
  end process;



  
  -- Video blanking signal

  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' then
        if Xpixel > 640 or Ypixel > 480 then
          blank <= '1';
        else
          blank <= '0';
        end if;
      end if;
    end if;
  end process;

  
  -- Picture memory address composite
  --addr <= to_unsigned(20, 7) * Ypixel(8 downto 5) + Xpixel(9 downto 5);


  -- VGA generation
  --vgaRed(2) 	<= tilePixel(7);
  vgaRed(2)     <= (tilePixel(7) xor (cursor and not we)) and not blank;
  vgaRed(1) 	<= (tilePixel(6) xor (cursor and not we)) and not blank;
  vgaRed(0) 	<= (tilePixel(5) xor (cursor and not we)) and not blank;
  vgaGreen(2)   <= (tilePixel(4) xor (cursor and not we)) and not blank;
  vgaGreen(1)   <= tilePixel(3);
  vgaGreen(0)   <= tilePixel(2);
  vgaBlue(2) 	<= tilePixel(1);
  vgaBlue(1) 	<= tilePixel(0);

end Behavioral;

