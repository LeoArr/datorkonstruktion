library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity cpu is
  port(
    -- in och utsignaler
    clk : in std_logic;
    vga_data : out std_logic_vector(7 downto 0);  -- data till VGA-motorn
    btnu, btnd, btnl, btnr, btns : in std_logic;  -- alla knappar 
    color : in std_logic_vector(7 downto 0)
  );
end cpu;

--TODO addreseringsmoder, uMinneprogrammering, hoppas att det funkar

architecture behavioral of cpu is
  -- intarna signaler
  type prog_mem is array (0 to 255) of std_logic_vector(15 downto 0);           --programminne
  signal asr : std_logic_vector(7 downto 0) := x"00";  -- ASR
  signal ir : std_logic_vector(15 downto 0) := x"0000";  -- Instruktionsregister
  signal pc : std_logic_vector(7 downto 0) := x"00";                             --program counter
  signal buss : std_logic_vector(15 downto 0) := x"0000";  -- buss
  
  --statusflaggor
  -- z n c o l
  signal sr : std_logic_vector(3 downto 0) := "0000";  --statusregister
  
  -- register o mux
  signal sel : std_logic_vector(1 downto 0) := "00";  -- Mux SEL
  type grx is array (0 to 3) of std_logic_vector(15 downto 0);  -- grX
  signal gmux : grx;
  
  -- ALU
  signal ar : std_logic_vector(15 downto 0) := x"0000";  -- Accumulatorregister
  signal helpr : std_logic_vector(15 downto 0) := x"0000";  -- help register

  signal umsig_cpu : std_logic_vector(31 downto 0);
  signal tobuss : std_logic_vector(2 downto 0);

  -- instruktioner 
  --load        0000
  --store       0001
  --add         0010
  --sub         0011
  --and         0100
  --bra         0101
  --bne         0110
  --beq         0111
  --btn         1000 ; laddar in knappar i grx
  --vga         1001 ; skickar ut grx-data till vga-motorn

-- programmet 
  signal pm : prog_mem := ("0000000100000000",  --00 load, gr0, d40   INIT
                           "0000000000101000",  --01 d40
                           "0000010100000000",  --02 load gr1, d30
                           "0000000000011110",  --03 d30
                           "0000100100000000",  --04 load gr2 0
                           "0000000000000000",  --05
                           "0001100011111111",  --06 store gr2, pmFF
                           "1111000000000000",  --07 NOP
                           --MAIN LOOP
                           "0000110011111111",  --08 load gr3 pmFF
                           "0010110100000000",  --09 add gr3, 0
                           "0000000000000000",  --0A d0
                           "0110000000101011",  --0B bne btn_check <<<<<<<<<<<
                           --UPPKNAPP
                           "1000110000000000",  --0C btn gr3
                           "0100110100000001",  --0D and gr3, x0001
                           "0000000000000001",  --0E x0001
                           "0011110100000000",  --0F sub gr3 1
                           "0000000000000001",  --10 1
                           "0111000000110011",  --11 beq btn_up    <<<<<<<<<<<<
                           --NEDKNAPP
                           "1000110000000000",  --12 btn gr3
                           "0100110100000000",  --13 and gr3 x0004
                           "0000000000000100",  --14 x0004
                           "0011110100000000",  --15 sub gr3 04
                           "0000000000000100",  --16 04
                           "0111000001000000",  --17 beq btn_down <<<<<<<<<<<<<
                           --HOGERKNAPP
                           "1000110000000000",  --18 btn gr3
                           "0100110100000000",  --19 and gr3 x0008
                           "0000000000001000",  --1A x0008
                           "0011110100000000",  --1b sub gr3 08
                           "0000000000001000",  --1c 08
                           "0111000001001111",  --1d beq btn_right <<<<<<<<<<<<<
                           --LEFT
                           "1000110000000000",  --1e btn gr3
                           "0100110100000000",  --1f and gr3 x0002
                           "0000000000000010",  --20 x0002
                           "0011110100000000",  --21 sub gr3 02
                           "0000000000000010",  --22 02
                           "0111000001011110",  --23 beq btn_left <<<<<<<<<<<<<
                           --SELECT
                           "1000110000000000",  --24 btn gr3
                           "0100110100000000",  --25 and gr3 x0010
                           "0000000000010000",  --26 x0010
                           "0011110100000000",  --27 sub gr3 x10
                           "0000000000010000",  --28 x10
                           "0111000001101010",  --29 beq btn_sel <<<<<<<<<<<<<
                           --LOOP
                           "0101000000001000",  --2A bra main_loop <<<<<<<<<<
                           --BTN_CHECK
                           "1000110000000000",  --2B btn gr3
                           "0010110100000000",  --2C add gr3, 0
                           "0000000000000000",  --2D
                           "0110000000000111",  --2e bne main_loop <<<<<<<<<<<
                           "0000110100000000",  --2f load gr3, 0
                           "0000000000000000",  --30 0
                           "0001110011111111",  --31 store gr3 i pmFF
                           "0101000000001000",  --32 bra main_loop <<<<<<<<<
                           --BTN_UPP
                           "0010010100000000",  --33 add gr1, 0
                           "0000000000000000",  --34 0
                           "0111000000001000",  --35 beq main_loop <<<<<<<<<<<
                           "0011010100000000",  --36 sub gr1 1
                           "0000000000000001",  --37 1
                           "0000110100000000",  --38 load gr3 x82
                           "0000000010000010",  --39 x82
                           "1001110000000000",  --3a vga gr3
                           "1001010000000000",  --3b vga gr1
                           "0000110100000000",  --3c load gr3 1
                           "1111111111111111",  --3d 1
                           "0001110011111111",  --3e store pmFF
                           "0101000000001000",  --3f bra main_loop <<<<<<<<<<<
                           --BTN_DOWN
                           "0001010011111110",  --40 store gr1, FE
                           "0011010100111011",  --41 sub gr1 d59
                           "0000000000111011",  --42 d59
                           "0000010011111110",  --43 load gr1 FE
                           "0111000000001000",  --44 beq main_loop <<<<<<<<<<<
                           "0010010100000000",  --45 add gr1 1
                           "0000000000000001",  --46 1
                           "0000110100000000",  --47 load gr3 x82
                           "0000000010000010",  --48 x82
                           "1001110000000000",  --49 vga gr3
                           "1001010000000000",  --4a vga gr1
                           "0000110100000000",  --4a load gr3 1
                           "1111111111111111",  --4c 1
                           "0001110011111111",  --4d store pmFF
                           "0101000000001000",  --4e bra main_loop <<<<<<<<<<<
                           --BTN_RIGHT
                           "0001000011111110",  --4f store gr0, FE
                           "0011000101001111",  --50 sub gr0 d79
                           "0000000001001111",  --51
                           "0000000011111110",  --52 load gr0 FE
                           "0111000000001000",  --53 beq main_loop <<<<<<<<<<<
                           "0010000100000000",  --54 add gr0 1
                           "0000000000000001",  --55 d1
                           "0000110100000000",  --56 load gr3 x81
                           "0000000010000001",  --57 x81
                           "1001110000000000",  --58 vga gr3
                           "1001000000000000",  --59 vga gr0
                           "0000110100000000",  --5a load gr3 1
                           "1111111111111111",  --5b ffff
                           "0001110011111111",  --5c store pmFF gr3
                           "0101000000001000",  --5d bra main_loop <<<<<<<<<<<
                           --BTN_LEFT
                           "0010000011111100",  --5e add gr0 x00
                           "0111000000001000",  --5f beq main_loop <<<<<<<<<<<
                           "0011000100000000",  --60 sub gr0 1
                           "0000000000000001",  --61 d1
                           "0000110100000000",  --62 load gr3 x81
                           "0000000010000001",  --63 x81
                           "1001110000000000",  --64 vga gr3
                           "1001000000000000",  --65 vga gr0
                           "0000110100000000",  --66 load gr3 1
                           "1111111111111111",  --67 ffff
                           "0001110011111111",  --68 store pmFF gr3
                           "0101000000001000",  --69 bra main_loop <<<<<<<<<<<
                           --BTN_SEL
                           "0000110100000000",  --6a load gr3 x83
                           "0000000010000011",  --6b x81
                           "1001110000000000",  --6c vga gr3
                           "1001000000000000",  --6d vga gr0 DUMMYWRITE
                           "0000110100000000",  --6e load gr3 1
                           "1111111111111111",  --6f ffff
                           "0001110011111111",  --70 store pmFF gr3
                           "0101000000001000",  --71 bra main_loop <<<<<<<<<<<
                           
                           others => "0000000000000000");
  
  signal curr_pm : std_logic_vector(15 downto 0) := x"0000";  -- nuvarande instruktion som exekveras 

  signal Xsignal : unsigned(7 downto 0) := "00101000";

  signal check_c : std_logic_vector(16 downto 0);

  signal z : std_logic := '0';            -- z flagga
  signal n : std_logic := '0';            -- n flagga
  signal c : std_logic := '0';            -- c flagga
  signal o : std_logic := '0';            -- o flagga

  --VGA
  --signal vga_data : std_logic_vector(7 downto 0);

-- komponenten umem ligger i cpun
  component umem
    port (
      clk : in std_logic;               -- clock
      umsig : out std_logic_vector(31 downto 0);  -- umsig
      ir : in std_logic_vector(15 downto 0);
      sr : in std_logic_vector(3 downto 0)
      );
  end component;

begin

  --port map umem
  umemComp : umem port map (
    clk => clk,
    umsig => umsig_cpu,
    ir => ir,
    sr => sr
  );
  
  tobuss <= umsig_cpu(27 downto 25); -- till buss-fältet
  curr_pm <= pm(to_integer(unsigned(asr))); -- signal för den nuvarande instruktionen som behandlas 

  process(clk)
  begin
    if rising_edge(clk) then
      sel <= ir(11 downto 10);  -- sel styr gmx -muxen
    end if;
  end process;
  
  
  --till buss
  with tobuss select buss <=
    ir when "001",
    curr_pm when "010",
    x"00" & pc when "011",
    ar when "100",
    helpr when "101",
    gmux(to_integer(unsigned(sel))) when "110",
    x"0000" when others;
  
  -- IR
  process(clk)
  begin
    if rising_edge(clk) then
      if umsig_cpu(24 downto 22) = "001" then -- umsig(24 downto 22) = från buss
        ir <= buss;
      end if;
    end if;             
  end process;

  --PM
  process(clk)
  begin
    if rising_edge(clk) then
      if umsig_cpu(24 downto 22) = "010" then -- umsig(24 downto 22) = från buss
        pm(to_integer(unsigned(asr))) <= buss;
      end if;
    end if;             
  end process;

  -- PC
  process(clk)
  begin
    if rising_edge(clk) then
      if umsig_cpu(24 downto 22) = "011" then -- umsig(24 downto 22) = från buss
        pc <= buss(7 downto 0);   -- får endast plats med den sista byten
      elsif umsig_cpu(21) = '1' then  --P bit
        pc <= std_logic_vector(unsigned(pc) + 1);
      end if;
    end if;
  end process;

  -- HR
  process(clk)
  begin
    if rising_edge(clk) then
      if umsig_cpu(24 downto 22) = "101" then
        vga_data <= buss(7 downto 0);
      end if;
    end if;                     
  end process;
 
  -- GRX
  process(clk)
  begin
    if rising_edge(clk) then
      --gmux(to_integer(unsigned(sel))) <=  "00000000000" & btns & btnr & btnd & btnl & btnu;
      if umsig_cpu(24 downto 22) = "110" then
        gmux(to_integer(unsigned(sel))) <= buss;
      elsif umsig_cpu(31 downto 28) = "1111" then
        --gmux(to_integer(unsigned(sel))) <=  "00000000000" & btns & btnr & btnd & btnl & btnu;
      if sel = "00" then
        gmux(0) <= "00000000000" & btns & btnr & btnd & btnl & btnu;
       elsif sel = "01" then
         gmux(1) <= "00000000000" & btns & btnr & btnd & btnl & btnu;
       elsif sel = "10" then
        gmux(2) <= "00000000000" & btns & btnr & btnd & btnl & btnu;
       else
        gmux(3) <= "00000000000" & btns & btnr & btnd & btnl & btnu;
       end if;
      end if;
    end if;             
  end process;
  

  -- ASR
  process(clk)
  begin
    if rising_edge(clk) then
      if umsig_cpu(24 downto 22) = "111" then   -- umsig(24 downto 22) = från buss
        asr <= buss(7 downto 0);
      end if;
    end if;             
  end process;

  --acc
  process(clk)
  begin
    if rising_edge(clk) then
      case umsig_cpu(31 downto 28) is
        when "0001" => ar <= buss;
        when "0010" => ar <= not buss;
        when "0011" => ar <= X"0000";
        when "0100" => ar <= std_logic_vector(signed(ar) + signed(buss));
        when "0101" => ar <= std_logic_vector(unsigned(ar) - unsigned(buss));
        --when "0110" => ar <= ar and buss;
        when "0110" => ar <= ar and buss;
        when "0111" => ar <= ar or buss;
        when others => null;
      end case;
    end if;
  end process;

  with umsig_cpu(31 downto 28) select c <=
    check_c(16) when "0101",
    '0' when others;

    --flaggor
  z <= sr(0);
  n <= sr(1);
  c <= sr(2);
  o <= sr(3);

    -- z n c o l
  process(clk)
    begin
    if rising_edge(clk) then
      if ar = x"0000" then
        sr <= sr or "0001";          -- z UNEQUAL LENGTH?
      else
        sr <= sr and "1110";
      end if;
      if umsig_cpu(31 downto 28) = "0100" then
        if signed(ar) + signed(buss) > 65535 then
          sr <= sr or "1000";        -- o
        else
          sr <= sr and "0111";
        end if;
      end if;
    end if;
  end process;
        
end behavioral;
