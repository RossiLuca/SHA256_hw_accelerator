library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity comp_sha256 is
  port (
          W   : in std_ulogic_vector(31 downto 0);
          clk : in std_ulogic;
          rst : in std_ulogic;
          start : in std_ulogic;
          finish : in std_ulogic;
          enable : in std_ulogic;
          continue : in std_ulogic;
          stall : in std_ulogic;
          round  : in std_ulogic_vector(5 downto 0);
          h1     : out std_ulogic_vector(31 downto 0);
          h2     : out std_ulogic_vector(31 downto 0);
          h3     : out std_ulogic_vector(31 downto 0);
          h4     : out std_ulogic_vector(31 downto 0);
          h5     : out std_ulogic_vector(31 downto 0);
          h6     : out std_ulogic_vector(31 downto 0);
          h7     : out std_ulogic_vector(31 downto 0);
          h8     : out std_ulogic_vector(31 downto 0)
        );
end entity comp_sha256;

architecture structure of comp_sha256 is

signal h1_in : word;
signal h2_in : word;
signal h3_in : word;
signal h4_in : word;
signal h5_in : word;
signal h6_in : word;
signal h7_in : word;
signal h8_in : word;
signal a : word;
signal b : word;
signal c : word;
signal d : word;
signal e : word;
signal f : word;
signal g : word;
signal h : word;
signal sum1 : word;
signal sum2 : word;
signal sum3 : word;
signal sum4 : word;
signal sum5 : word;

begin


  sum1 <= word(unsigned(d) + unsigned(sum3));
  sum2 <= word(unsigned(h) + unsigned(Ch(e, f, g)) + unsigned(W) + unsigned(K_constants(to_integer(unsigned(round)))));
  sum3 <= word(unsigned(sum2) + unsigned(sigma_upper1(e)));
  sum4 <= word(unsigned(sum3) + unsigned(Maj(a, b, c)));
  sum5 <= word(unsigned(sum4) + unsigned(sigma_upper0(a)));

  h1 <= h1_in;
  h2 <= h2_in;
  h3 <= h3_in;
  h4 <= h4_in;
  h5 <= h5_in;
  h6 <= h6_in;
  h7 <= h7_in;
  h8 <= h8_in;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst = '1') then -- reset condition
        h1_in <= H_init(0);
        h2_in <= H_init(1);
        h3_in <= H_init(2);
        h4_in <= H_init(3);
        h5_in <= H_init(4);
        h6_in <= H_init(5);
        h7_in <= H_init(6);
        h8_in <= H_init(7);
        a <= (others => '0');
        b <= (others => '0');
        c <= (others => '0');
        d <= (others => '0');
        e <= (others => '0');
        f <= (others => '0');
        g <= (others => '0');
        h <= (others => '0');
      else
          if (finish = '1') then -- end of the computation of the SHA256
            h1_in <= word(unsigned(a) + unsigned(h1_in));
            h2_in <= word(unsigned(b) + unsigned(h2_in));
            h3_in <= word(unsigned(c) + unsigned(h3_in));
            h4_in <= word(unsigned(d) + unsigned(h4_in));
            h5_in <= word(unsigned(e) + unsigned(h5_in));
            h6_in <= word(unsigned(f) + unsigned(h6_in));
            h7_in <= word(unsigned(g) + unsigned(h7_in));
            h8_in <= word(unsigned(h) + unsigned(h8_in));
          elsif (start = '1') then -- satrt the SHA256
            if (continue = '1') then -- the block belong to the previous msg
              a <= h1_in;
              b <= h2_in;
              c <= h3_in;
              d <= h4_in;
              e <= h5_in;
              f <= h6_in;
              g <= h7_in;
              h <= h8_in;
            else -- block of a new msg
              h1_in <= H_init(0);
              h2_in <= H_init(1);
              h3_in <= H_init(2);
              h4_in <= H_init(3);
              h5_in <= H_init(4);
              h6_in <= H_init(5);
              h7_in <= H_init(6);
              h8_in <= H_init(7);
              a <= H_init(0);
              b <= H_init(1);
              c <= H_init(2);
              d <= H_init(3);
              e <= H_init(4);
              f <= H_init(5);
              g <= H_init(6);
              h <= H_init(7);
            end if;
          elsif (enable = '1' and stall = '0') then -- execute a round of the algorithm
            a <= sum5;
            b <= a;
            c <= b;
            d <= c;
            e <= sum1;
            f <= e;
            g <= f;
            h <= g;
          else -- stall the execution 
            a <= a;
            b <= b;
            c <= c;
            d <= d;
            e <= e;
            f <= f;
            g <= g;
            h <= h;
          end if;
      end if;
    end if;
  end process;



end structure;
