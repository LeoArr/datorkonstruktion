library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity topp_tb is
end topp_tb;

architecture Behavioral of topp_tb is

  component top
    port (
    clk, btns : in std_logic;
    vgaRed : out std_logic_vector(2 downto 0);
    vgaGreen : out std_logic_vector(2 downto 0);
    vgaBlue : out std_logic_vector(2 downto 1);
    Hsync : out std_logic;
    Vsync : out std_logic;
    sw : in std_logic_vector(7 downto 0);
    btnu, btnd, btnl, btnr : in std_logic
    );
  end component;

  signal clk : std_logic := '0';
  signal sw : std_logic_vector(7 downto 0);
  signal btnu : std_logic;
  signal btnd : std_logic;
  signal btnl : std_logic;
  signal btnr : std_logic;
  signal btns : std_logic;
begin  -- Behavioral

  uut: top port map (
    clk => clk,
    sw => sw,
    btnu => btnu,
    btnd => btnd,
    btnr => btnr,
    btnl => btnl,
    btns => btns
    );

clk <= not clk after 5 ns;

end Behavioral;
