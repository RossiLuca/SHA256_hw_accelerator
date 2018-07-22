library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity sha256_dp is
  port (
          --blk : in std_ulogic_vector(511 downto 0);
          M : in std_ulogic_vector(31 downto 0);
          clk : in std_ulogic;
          rst : in std_ulogic;
          start : in std_ulogic;
          continue : in std_ulogic;
          stall : in std_ulogic;
          finish : out std_ulogic;
          hash : out std_ulogic_vector(255 downto 0)
        );
end entity sha256_dp;

architecture structure of sha256_dp is

signal round : std_ulogic_vector(5 downto 0);
signal LoadWi : std_ulogic;
signal enable : std_ulogic;
signal finish_in : std_ulogic;
signal Wt : word;
signal Mt : word;
--signal M : word_vector (15 downto 0);


begin

  finish <= finish_in;
  --M <= M_parsing(blk);
  --Mt <= M(to_integer(unsigned(round(3 downto 0))));
  Mt <= M;

  comp: entity work.comp_sha256(structure)
      port map(
         W   => Wt,
         clk => clk,
         rst => rst,
         start => start,
         finish => finish_in,
         enable => enable,
         continue => continue,
         stall  => stall,
         round  => round,
         h1     => hash(255 downto 224),
         h2     => hash(223 downto 192),
         h3     => hash(191 downto 160),
         h4     => hash(159 downto 128),
         h5     => hash(127 downto 96),
         h6     => hash(95  downto 64),
         h7     => hash(63  downto 32),
         h8     => hash(31  downto 0)
      );

  data: entity work.data_expW(structure)
    port map(
       Mt      => Mt,
       LoadWi  => LoadWi,
       enable  => enable,
       stall   => stall,
       clk     => clk,
       rst     => rst,
       Wt      => Wt
    );


process(clk)
   begin
   if (clk'event and clk = '1') then
     if (rst = '0') then 
       if (enable = '1' and stall = '0') then
         if (to_integer(unsigned(round)) < 63) then
           round <= std_ulogic_vector(unsigned(round) + 1);
           finish_in <= '0';
           if ((to_integer(unsigned(round)) < 15)) then
              LoadWi <= '0';
              --Mt <= M;
           else
              LoadWi <= '1';
           end if;
         elsif (to_integer(unsigned(round)) = 63) then
           finish_in <= '1';
           enable <= '0';
           LoadWi <= '0';
           round <= (others => '0');
         end if;
       elsif (start = '1') then
         enable <= '1';
         --Mt <= M;
       elsif (finish_in = '1') then
         enable <= '0';
         finish_in <= '0';
       elsif (stall = '1') then
         enable <= enable;
         finish_in <= finish_in;
         --Mt <= Mt;
         round <= round;
         LoadWi <= LoadWi;
       else
         enable <= '0';
       end if;
     else
       round <= (others => '0');
       finish_in <= '0';
       enable <= '0';
       LoadWi <= '0';
     end if;
   end if;
end process;

end structure;
