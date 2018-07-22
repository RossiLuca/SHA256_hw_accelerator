library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;


entity data_expW is
  port  (
          Mt      : in word;
          LoadWi  : in std_ulogic;
          enable  : in std_ulogic;
          stall   : in std_ulogic;
          rst     : in std_ulogic;
          clk     : in std_ulogic;
          Wt      : out word
        );
end entity data_expW;

architecture structure of data_expW is

signal  sum1: word;
signal  sum2: word;
signal  sum3: word;
signal  W : word_vector (15 downto 0);
signal  Wt_in : word;
signal  Wt_16 : word;

begin

Wt <= Wt_in;
sum1 <= word(unsigned(sigma_lower0(W(1))) + unsigned(W(0)));
sum2 <= word(unsigned(sum1) + unsigned(W(9)));
sum3 <= word(unsigned(sum2) + unsigned(sigma_lower1(W(14))));

fifo: process(clk)
      begin
      if (clk'event and clk = '1') then
        if (rst = '1') then -- reset condition
          W(15 downto 0) <= (others => ( others => '0'));
        else
          if (enable = '1' and stall = '0') then -- compute the W for the current round
            for i in 1 to 15 loop
              W(i-1) <= W(i);
            end loop;
            W(15) <= Wt_16;
          end if;
        end if;
      end if;
    end process fifo;

mux: process(LoadWi, Mt, sum3)
     begin
        if (Loadwi = '1') then -- if round > 15 Wt is the output of the chain
          Wt_in <= sum3;
          Wt_16 <= sum3;
        else -- if round < 16 Wt = Mt
          Wt_in <= Mt;
          Wt_16 <= Mt;
        end if;
    end process mux;

end structure;
