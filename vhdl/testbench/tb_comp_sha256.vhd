library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity tb_comp_sha256 is
end entity tb_comp_sha256;

architecture sim of tb_comp_sha256 is

signal msg : std_ulogic_vector(511 downto 0) := "01100001011000100110001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000";
signal res_sha256 : std_ulogic_vector(255 downto 0);
signal M  : word_vector(15 downto 0);
signal W  : word_vector(63 downto 0);
signal Wt : word;
signal h1 : word;
signal h2 : word;
signal h3 : word;
signal h4 : word;
signal h5 : word;
signal h6 : word;
signal h7 : word;
signal h8 : word;
signal clk : std_ulogic;
signal rst : std_ulogic;
signal start : std_ulogic;
signal finish : std_ulogic;
signal enable : std_ulogic;
signal continue : std_ulogic;
signal stall : std_ulogic;
signal round  : std_ulogic_vector(5 downto 0);
begin
  
  rst <= '1', '0' after 2 ns;
  start <= '0', '1' after 2 ns, '0' after 4 ns, '1' after 160 ns, '0' after 162 ns ;
  continue <= '0';--, '1' after 160 ns;  
  stall <= '0', '1' after 100 ns, '0' after 120 ns;

  res_sha256 <= sha256_fun(msg);
  M <= M_parsing(msg);
  W <= exp_W(M);
  Wt <= W(to_integer(unsigned(round)));
 
  process(clk)
  begin
  if (clk'event and clk = '1') then
    if (rst = '0') then
      if (enable = '1' and stall = '0') then
        if (to_integer(unsigned(round)) < 63) then
          round <= std_ulogic_vector(unsigned(round) + 1);
          finish <= '0';
        elsif (to_integer(unsigned(round)) = 63) then
          finish <= '1';
          enable <= '0';
          round <= (others => '0');
        end if;
      elsif (start = '1') then
        enable <= '1';
      elsif (finish = '1') then
        enable <= '0';
        finish <= '0';
      elsif (stall = '1') then
        enable <= enable;
        finish <= finish;
        round <= round;
      else 
        enable <= '0';
      end if;
    else
      round <= (others => '0');
      finish <= '0';
      enable <= '0';
    end if; 
  end if;
  end process;

  process
  begin
    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;
  end process;

  comp: entity work.comp_sha256(structure)
    port map(
       W   => Wt,
       clk => clk,
       rst => rst,
       start => start,
       finish => finish,
       enable => enable,
       continue => continue,
       stall => stall,
       round  => round,
       h1     => h1,
       h2     => h2,
       h3     => h3,
       h4     => h4,
       h5     => h5,
       h6     => h6,
       h7     => h7,
       h8     => h8
    );

end sim;

