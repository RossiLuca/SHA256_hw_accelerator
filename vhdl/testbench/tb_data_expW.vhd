library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity tb_data_expW is
end entity tb_data_expW;

architecture sim of tb_data_expW is

signal msg : std_ulogic_vector(511 downto 0) := "01100001011000100110001110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000";
signal res_sha256 : std_ulogic_vector(255 downto 0);
signal M  : word_vector(15 downto 0);
signal W  : word_vector(63 downto 0);
signal Mt : word;
signal Wt_data : word;
signal Wt_vector_data : word_vector(63 downto 0);
signal LoadWi : std_ulogic;
signal clk : std_ulogic;
signal rst : std_ulogic;
signal enable : std_ulogic;
signal stall : std_ulogic;

begin

  rst <= '1', '0' after 2 ns;
  enable <= '1', '0' after 30 ns, '1' after 60 ns;
  stall <= '0', '1' after 72 ns, '0' after 80 ns;

  res_sha256 <= sha256_fun(msg);
  M <= M_parsing(msg);
  W <= exp_W(M);

  process(clk)
  variable i : integer:= 0;
  begin
  if (clk'event and clk = '1') then
    if (rst = '0') then
      if (enable = '1' and stall = '0') then
        if ( i < 64) then
          if (i < 16) then
            Mt <= M(i);
            LoadWi <= '0';
          else
            LoadWi <= '1';
          end if;
   --     Wt_vector_fifo(i) <= Wt_fifo;
          Wt_vector_data(i) <= Wt_data;
          i := i + 1;
        end if;
      elsif (stall = '1') then
        i := i;
        LoadWi <= LoadWi;
        Mt <= Mt;
      end if;
    else
      LoadWi <= '0';
      Mt <= M(0);
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


  data: entity work.data_expW(structure)
    port map(
       Mt      => Mt,
       LoadWi  => LoadWi,
       enable  => enable,
       stall   => stall,
       clk     => clk,
       rst     => rst,
       Wt      => Wt_data
    );

end sim;
