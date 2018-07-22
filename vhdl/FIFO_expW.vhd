library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;


entity FIFO_expW is
  port  (
          Mt      : in word;
          LoadWi  : in std_ulogic;
          clk     : in std_ulogic;
          rst     : in std_ulogic;
          Wt      : out word
        );
end entity FIFO_expW;

architecture structure of FIFO_expW is

signal  sum : word;
signal  rotl: word;
signal  Wt_in : word;
signal  Wt_1 : word;
signal  Wt_2 : word;
signal  Wt_3 : word;
signal  Wt_4 : word;
signal  Wt_5 : word;
signal  Wt_6 : word;
signal  Wt_7 : word;
signal  Wt_8 : word;
signal  Wt_9 : word;
signal  Wt_10 : word;
signal  Wt_11 : word;
signal  Wt_12 : word;
signal  Wt_13 : word;
signal  Wt_14 : word;
signal  Wt_15 : word;
signal  Wt_16 : word;

begin 

Wt <= Wt_in;
sum <= word(unsigned(Wt_6) + unsigned(Wt_12) + unsigned(Wt_14) + unsigned(Wt_1));
rotl <= word(rotate_left(unsigned(sum),1));
    
fifo: process(clk)
      begin
      if (clk'event and clk = '1') then
        if (rst = '1') then 
          Wt_1 <= (others => '0');
          Wt_2 <= (others => '0');
          Wt_3 <= (others => '0');
          Wt_4 <= (others => '0');
          Wt_5 <= (others => '0');
          Wt_6 <= (others => '0');
          Wt_7 <= (others => '0');
          Wt_8 <= (others => '0');
          Wt_9 <= (others => '0');
          Wt_10 <= (others => '0');
          Wt_11 <= (others => '0');
          Wt_12 <= (others => '0');
          Wt_13 <= (others => '0');
          Wt_14 <= (others => '0');
          Wt_15 <= (others => '0');
          Wt_16 <= (others => '0');
        else
          Wt_1 <= Wt_in;
          Wt_2 <= Wt_1;
          Wt_3 <= Wt_2;
          Wt_4 <= Wt_3;
          Wt_5 <= Wt_4;
          Wt_6 <= Wt_5;
          Wt_7 <= Wt_6;
          Wt_8 <= Wt_7;
          Wt_9 <= Wt_8;
          Wt_10 <= Wt_9;
          Wt_11 <= Wt_10;
          Wt_12 <= Wt_11;
          Wt_13 <= Wt_12;
          Wt_14 <= Wt_13;
          Wt_15 <= rotl;
          Wt_16 <= Wt_15;
        end if;
      end if;
    end process fifo;

mux: process(LoadWi, Mt, Wt_16)
     begin
        if (Loadwi = '1') then
          Wt_in <= Wt_16;
        else
          Wt_in <= Mt;
        end if;
    end process mux;

end structure;
