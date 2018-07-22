library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

entity sha256_fsm is
  port(
      clk:      in  std_ulogic;
      rst:      in  std_ulogic;
      new_data: in  std_ulogic;
      finish  : in  std_ulogic;
      new_msg : in  std_ulogic;
      stop    : in  std_ulogic;
      stall   : out  std_ulogic;
      start   : out  std_ulogic;
      continue: out  std_ulogic;
      hash_valid : out  std_ulogic;
      srst:    out  std_ulogic
  );
end entity sha256_fsm;

architecture rtl of sha256_fsm is

  TYPE State IS (idle, start_sha, wait_sha, finish_sha, continue_sha, stall_sha);
  SIGNAL p_state  : State:=idle;
  SIGNAL n_state   : State:=idle;

begin

  fsm_updating  : process (clk)
      begin
      if (clk='1' and clk'EVENT) then -- rising edge of the clock
        if rst ='0' then
           p_state <= n_state; -- change state of the machine to next one
        else
           p_state <= idle; -- reset state
        end if;
      end if;
      end process fsm_updating;

  fsm_transition: process(p_state, new_data, finish, stop)
      begin
      case p_state is
        when idle => -- current state is idle
          if (new_data  = '0') then -- no new data for sha
            n_state <= idle;
          elsif (new_data = '1') then
            n_state <= start_sha;
          else
            n_state <= idle;
          end if;

        when start_sha => --assert start signal
            if (stop = '1') then
             n_state <= stall_sha;
            else
             n_state <= wait_sha;
            end if;

        when continue_sha => --assert start and continue signals
            if (stop = '1') then
              n_state <= stall_sha;
            else
              n_state <= wait_sha;
            end if;

        when wait_sha =>  -- wait for end of SHA256
          if (finish  = '1') then
            n_state <= finish_sha;
          elsif (stop = '1') then
            n_state <= stall_sha;
          else
            n_state <= wait_sha;
          end if;

        when stall_sha =>  -- stall the SHA256 until the stop signal is asserted
            if (stop = '0') then
              n_state <= wait_sha;
            else
              n_state <= stall_sha;
            end if;

        when finish_sha => -- end of the SHA256
          if (new_data  = '1' and new_msg = '0') then -- new data of new message
            n_state <= continue_sha;
          elsif (new_data = '1' and new_msg = '1') then -- new block of data same message
            n_state <= start_sha;
          else
            n_state <= p_state;
          end if;

        when others =>
          n_state <= idle;
      end case;
    end process fsm_transition;

output: process (p_state) -- assign a value to output based on state
    begin
    srst <= '1';
    continue <= '0';
    start <= '0';
    stall <= '1';
    hash_valid <= '0';
    case p_state is
        when idle =>
            start <= '0';
            continue <= '0';
            srst <= '1';
            stall <= '0';
            hash_valid <= '0';
        when start_sha =>
            start <= '1';
            srst  <= '0';
            continue <= '0';
            stall <= '0';
            hash_valid <= '0';
        when wait_sha =>
            start <= '0';
            srst  <= '0';
            continue <= '0';
            stall <= '0';
            hash_valid <= '0';
        when stall_sha =>
            start <= '0';
            srst  <= '0';
            continue <= '0';
            stall <= '1';
            hash_valid <= '0';
        when finish_sha =>
            start <= '0';
            srst  <= '0';
            continue <= '0';
            stall <= '0';
            hash_valid <= '1';
        when continue_sha =>
            start <= '1';
            srst  <= '0';
            continue <= '1';
            stall <= '0';
            hash_valid <= '0';
        when others =>
            srst <= '1';
            continue <= '0';
            start <= '0';
            stall <= '1';
            hash_valid <= '0';
    end case;
  end process output;

end architecture rtl;
