library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity tb_sha256 is
end entity tb_sha256;

architecture sim of tb_sha256 is

signal msg : std_ulogic_vector(511 downto 0) := "01100001011000100110001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000";
signal msg2 : sha256data(1 downto 0);
signal res_sha256 : std_ulogic_vector(255 downto 0);
signal res2_sha256 : std_ulogic_vector(255 downto 0);
signal M_parsed : word_vector(15 downto 0);
signal M : word;
signal clk : std_ulogic;
signal rst : std_ulogic;
signal stop : std_ulogic;
signal new_msg : std_ulogic;
signal new_data : std_ulogic;
signal hash_valid : std_ulogic;
signal hash : std_ulogic_vector(255 downto 0);


begin
  
  M_parsed <= M_parsing(msg);
  msg2(0) <= msg;
  msg2(1) <= msg;
  res_sha256 <= sha256_fun(msg);
  res2_sha256 <= sha256_comp(msg2, 2);
  
  process
  variable k : integer := 0;
  begin
      k := 0;
      new_msg <= '0';
      new_data <= '0';
      stop <= '0';
      rst <= '1';
      wait until rising_edge(clk);
      rst <= '0';
      wait until rising_edge(clk);
      new_data <= '1';
      wait until rising_edge(clk);
      new_data <= '0';
      wait until rising_edge(clk);
      M <= M_parsed(k);
      k := k + 1;
      wait until rising_edge(clk);
      for j in 0 to 5 loop
        M <= M_parsed(k);
        k := k +1;
        wait until rising_edge(clk);
      end loop;
      stop <= '1';
      for j in 0 to 10 loop
        wait until rising_edge(clk);
      end loop;
      stop <= '0';
      for j in 6 to 14 loop
        M <= M_parsed(k);
        k := k + 1;
        wait until rising_edge(clk);
      end loop;
      for j in 15 to 65 loop
        wait until rising_edge(clk);
      end loop;
      for j in 0 to 5 loop
       wait until rising_edge(clk);
      end loop;
      new_data  <= '1';
      new_msg   <= '1';
      wait until rising_edge(clk);
      new_data  <= '0';
      new_msg   <= '0';
      wait until rising_edge(clk);
      k := 0;
      M <= M_parsed(k);
      k := k + 1;
      wait until rising_edge(clk);
      for j in 0 to 5 loop
        M <= M_parsed(k);
        k := k +1;
        wait until rising_edge(clk);
      end loop;
      for j in 6 to 14 loop
        M <= M_parsed(k);
        k := k + 1;
        wait until rising_edge(clk);
      end loop;
      for j in 15 to 65 loop
        wait until rising_edge(clk);
      end loop;
      for j in 0 to 5 loop
        wait until rising_edge(clk);
      end loop;
      new_data  <= '1';
      new_msg   <= '0';
      wait until rising_edge(clk);
      new_data  <= '0';
      new_msg   <= '0';
      wait until rising_edge(clk);
      k := 0;
      M <= M_parsed(k);
      k := k + 1;
      wait until rising_edge(clk);
      for j in 0 to 5 loop
        M <= M_parsed(k);
        k := k +1;
        wait until rising_edge(clk);
      end loop;
      stop <= '1';
      for j in 0 to 10 loop
        wait until rising_edge(clk);
      end loop;
      stop <= '0';
      for j in 6 to 14 loop
        M <= M_parsed(k);
        k := k + 1;
        wait until rising_edge(clk);
      end loop;
      for j in 15 to 65 loop
        wait until rising_edge(clk);
      end loop;
      for j in 0 to 5 loop
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

hw_sha256: entity work.hw_sha256(structure)
    port map (                
          M => M,
          clk => clk,
          rst => rst,
          stop => stop,
          new_msg => new_msg,
          new_data => new_data,
          hash_valid => hash_valid,
          hash => hash
        );


end sim;



