library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity tb_sha256_fsm is
end entity tb_sha256_fsm;

architecture sim of tb_sha256_fsm is

signal clk : std_ulogic;
signal rst : std_ulogic;
signal start : std_ulogic;
signal finish : std_ulogic;
signal continue : std_ulogic;
signal stall : std_ulogic;
signal new_msg : std_ulogic;
signal new_data : std_ulogic;
signal stop : std_ulogic;
signal srst : std_ulogic;


begin
  
  
  process
  variable k : integer := 0;
  begin
      finish <= '0';
      new_msg <= '0';
      new_data <= '0';
      stop <= '0';
      rst <= '1';
      wait until rising_edge(clk);
      rst <= '0';
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      new_data <= '1';
      wait until rising_edge(clk);
      new_data <= '0';
      for j in 0 to 30 loop
        wait until rising_edge(clk);
      end loop;
      stop <= '1';
      for j in 0 to 10 loop
        wait until rising_edge(clk);
      end loop;
      stop <= '0';
      for j in 31 to 65 loop
        wait until rising_edge(clk);
      end loop;
      finish <= '1';
      wait until rising_edge(clk);
      finish <= '0';
      for j in 0 to 5 loop
        wait until rising_edge(clk);
      end loop;
      new_data  <= '1';
      new_msg   <= '1';
      wait until rising_edge(clk);
      new_data  <= '0';
      new_msg   <= '0';
      wait until rising_edge(clk);
      for j in 0 to 30 loop
        wait until rising_edge(clk);
      end loop;
      stop <= '1';
      for j in 0 to 10 loop
        wait until rising_edge(clk);
      end loop;
      stop <= '0';
      for j in 31 to 65 loop
        wait until rising_edge(clk);
      end loop;
      finish <= '1';
      wait until rising_edge(clk);
      finish <= '0';
      for j in 0 to 5 loop
        wait until rising_edge(clk);
      end loop;
      new_data  <= '1';
      new_msg   <= '0';
      wait until rising_edge(clk);
      new_data  <= '0';
      new_msg   <= '0';
      for j in 0 to 10 loop
        wait until rising_edge(clk);
      end loop;
   end process; 

  process
  begin
    clk <= '1';
    wait for 1 ns;
    clk <= '0';
    wait for 1 ns;
  end process;

sha256fsm: entity work.sha256_fsm(rtl)
    port map (
            clk => clk,
            rst => rst,
            new_data => new_data,
            finish => finish,
            new_msg => new_msg,
            stop => stop,
            stall => stall,
            start => start,
            continue => continue,
            srst => srst
           );

end sim;


