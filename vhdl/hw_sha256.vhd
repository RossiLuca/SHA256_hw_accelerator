library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity hw_sha256 is
  port (
          M : in std_ulogic_vector(31 downto 0);
          clk : in std_ulogic;
          rst : in std_ulogic;
          stop : in std_ulogic;
          new_msg : in std_ulogic;
          new_data : in std_ulogic;
          hash_valid : out std_ulogic;
          hash : out std_ulogic_vector(255 downto 0)
        );
end entity hw_sha256;

architecture structure of hw_sha256 is

signal start : std_ulogic;
signal stall : std_ulogic;
signal finish : std_ulogic;
signal continue : std_ulogic;
signal srst : std_ulogic;


begin


  dp: entity work.sha256_dp(structure)
      port map(
          M => M,
          clk => clk,
          rst => rst,
          start => start,
          continue => continue,
          stall => stall,
          finish => finish,
          hash => hash
        );

  cu: entity work.sha256_fsm(rtl)
      port map(
       clk => clk,
       rst => rst,
       new_data => new_data,
       finish  => finish,
       new_msg => new_msg,
       stop    => stop,
       stall   => stall,
       start   => start,
       continue => continue,
       hash_valid => hash_valid,
       srst => srst
      );


end structure;

