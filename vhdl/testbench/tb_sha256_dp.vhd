library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity tb_sha256_dp is
end entity tb_sha256_dp;

architecture sim of tb_sha256_dp is

signal msg : std_ulogic_vector(511 downto 0) := "01100001011000100110001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000";
signal msg2 : sha256data(1 downto 0);
signal res_sha256 : std_ulogic_vector(255 downto 0);
signal res2_sha256 : std_ulogic_vector(255 downto 0);
signal HW_sha256 : std_ulogic_vector(255 downto 0);
signal clk : std_ulogic;
signal rst : std_ulogic;
signal start : std_ulogic;
signal finish : std_ulogic;
signal continue : std_ulogic;
signal stall : std_ulogic;
signal Mt  : word;
signal M  : word_vector(15 downto 0);


begin
  
  msg2(0) <= msg;
  msg2(1) <= msg;
  res_sha256 <= sha256_fun(msg);
  res2_sha256 <= sha256_comp(msg2, 2);
  M <= M_parsing(msg);
  
  process
  variable k : integer := 0;
  begin
      continue <= '0';
      stall <= '0';
      rst <= '1';
      wait until rising_edge(clk);
      rst <= '0';
      wait until rising_edge(clk);
      start <= '1';
      Mt <= M(k);
      k := k + 1;
      wait until rising_edge(clk);
      start <= '0';
      for j in 0 to 7 loop
        Mt <= M(k);
        k := k + 1;
        wait until rising_edge(clk);
      end loop;
      for j in 0 to 4 loop
        stall <= '1';
        wait until rising_edge(clk);
      end loop;
      stall <= '0';
      for j in 8 to 14 loop
        Mt <= M(k);
        k := k + 1;
        wait until rising_edge(clk);
      end loop;
      k := 0;
      wait until (rising_edge(clk) and finish = '1');
      continue <= '1';
      start <= '1';
      Mt <= M(k);
      k := k + 1;
      wait until rising_edge(clk);
      start <= '0';
      continue <= '0';
      for j in 0 to 14 loop
        Mt <= M(k);
        k := k +1;
        wait until rising_edge(clk);
      end loop;
      k := 0;
      wait until (rising_edge(clk) and finish = '1');
   end process; 

  process
  begin
    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;
  end process;

sha256dp: entity work.sha256_dp(structure)
    port map (
            M => Mt,
            clk => clk,
            rst => rst,
            start => start,
            continue => continue,
            stall => stall,
            finish => finish,
            hash => HW_sha256
           );

end sim;


