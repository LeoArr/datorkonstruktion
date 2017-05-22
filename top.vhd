library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity top is
  port(
    -- in och utsignaler
    clk : in std_logic;
    vgaRed : out std_logic_vector(2 downto 0);
    vgaGreen : out std_logic_vector(2 downto 0);
    vgaBlue : out std_logic_vector(2 downto 1);
    Hsync : out std_logic;
    Vsync : out std_logic;
    sw : in std_logic_vector(7 downto 0);
    btnu, btnd, btnl, btnr, btns : in std_logic
    );
end top;

architecture behavioral of top is

  -- signaler
  signal vga_data : std_logic_vector(7 downto 0) := x"00";
  signal buttons : std_logic_vector(4 downto 0);
  
  -- komponenter
  component cpu
    port (
      clk : in std_logic;
      vga_data : out std_logic_vector(7 downto 0);  -- datan som ska skickas till VGA-motorn
      btnu, btnd, btnl, btnr, btns : in std_logic;
      color : in std_logic_vector(7 downto 0)
      );
  end component;

  component vga_motor
    port (
      clk : in std_logic;
      data : in std_logic_vector(7 downto 0);
      switches : in std_logic_vector(7 downto 0);
      vgaRed : out std_logic_vector(2 downto 0);
      vgaGreen : out std_logic_vector(2 downto 0);
      vgaBlue : out std_logic_vector(2 downto 1);
      Hsync : out std_logic;
      Vsync : out std_logic);
  end component;
  
begin
  
  --port map cpu
  cpuComp : cpu port map (
    clk => clk,
    vga_data => vga_data,
    buttons => buttons,
    color => sw,
    btnu => btnu,
    btnl => btnl,
    btnd => btnd,
    btnr => btnr,
    btns => btns
);
  
  --port map vga_motor
  vga_motorComp : vga_motor port map (
    clk => clk,
    data => vga_data,
    switches => sw,
    vgared => vgared,
    vgagreen => vgagreen,
    vgablue => vgablue,
    hsync => hsync,
    vsync => vsync
);

end behavioral;
