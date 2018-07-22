--sha256  wrapper, AXI lite version, top level
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;
use work.axi_pkg.all;

entity sha256_axi is
  port(
    aclk:           in    std_ulogic;
    aresetn:        in    std_ulogic;
    s0_axi_araddr:  in    std_ulogic_vector(11 downto 0);
    s0_axi_arprot:  in    std_ulogic_vector(2 downto 0);
    s0_axi_arvalid: in    std_ulogic;
    s0_axi_rready:  in    std_ulogic;
    s0_axi_awaddr:  in    std_ulogic_vector(11 downto 0);
    s0_axi_awprot:  in    std_ulogic_vector(2 downto 0);
    s0_axi_awvalid: in    std_ulogic;
    s0_axi_wdata:   in    std_ulogic_vector(31 downto 0);
    s0_axi_wstrb:   in    std_ulogic_vector(3 downto 0);
    s0_axi_wvalid:  in    std_ulogic;
    s0_axi_bready:  in    std_ulogic;
    s0_axi_arready: out   std_ulogic;
    s0_axi_rdata:   out   std_ulogic_vector(31 downto 0);
    s0_axi_rresp:   out   std_ulogic_vector(1 downto 0);
    s0_axi_rvalid:  out   std_ulogic;
    s0_axi_awready: out   std_ulogic;
    s0_axi_wready:  out   std_ulogic;
    s0_axi_bresp:   out   std_ulogic_vector(1 downto 0);
    s0_axi_bvalid:  out   std_ulogic
  );
end entity sha256_axi;

architecture rtl of sha256_axi is


  signal arst:      std_ulogic;
  signal stop:      std_ulogic;
  signal new_msg:   std_ulogic;
  signal new_data:  std_ulogic;
  signal hash_valid:  std_ulogic;
  signal hash:     std_ulogic_vector(255 downto 0);
  signal waiting : std_ulogic;
  signal new_word : std_ulogic;
  signal busy : std_ulogic;

  signal status_reg:  std_ulogic_vector(31 downto 0);
  signal data_reg:    std_ulogic_vector(31 downto 0);
  signal H: word_vector (7 downto 0);
  signal M: word;

  type bank_register is array (9 downto 0) of std_ulogic_vector(31 downto 0);
  type state is (r_idle,r_read,r_wait_rready,w_idle,w_write,w_wait_bready); -- define the possible states of the write and read FSM
  signal r_p_state        : state:=r_idle; -- read FSM current state
  signal r_n_state        : state:=r_idle; -- read FSM next state
  signal w_p_state        : state:=w_idle; -- write FSM current state
  signal w_n_state        : state:=w_idle; -- write FSM next state
  signal reg              : bank_register; -- instanciate the registers
  signal w_data           : std_ulogic_vector (31 downto 0); -- data to be written in the register
  signal r_data           : std_ulogic_vector (31 downto 0); -- read data from the register
  signal w_addr           : std_ulogic_vector (11 downto 0); -- write address
  signal r_status         : std_ulogic_vector (1 downto 0); -- response status to the read operation
  signal w_status         : std_ulogic_vector (1 downto 0); -- response status to the write operation

begin

  arst <= not aresetn;

  reg(0) <= data_reg; -- map data_reg to reg(0)
  reg(1) <= status_reg; -- map status_reg to reg(1)

  M <= data_reg;
  H <= hash_value(hash);

  sha256_hw: entity work.hw_sha256(structure) -- sha256 device
        port map(
          M => M,
          clk => aclk,
          rst => arst,
          stop => stop,
          new_msg => new_msg,
          new_data => new_data,
          hash_valid => hash_valid,
          hash => hash
        );


-- control logic for the write operations
  write_ctrl: process(aclk)
            variable cnt : integer;
            begin
            if (aclk = '1' and aclk'EVENT) then -- rising edge of the aclk signal
              if (aresetn = '1') then -- no reset condition
                status_reg(0) <= hash_valid;
                if (busy = '1') then -- we are in a round of SHA256 grater than 16
                  stop <= '0';
                else
                  stop <= '1';
                end if;
                if (cnt =  16) then -- set busy signal since no more data is required by the user to complete current SHA256
                  busy <= '1';
                  stop <= '0';
                end if;
                if ((w_addr >= "000000000000") and (w_addr < "000000000100") and (new_word = '1') and (busy = '0') and (cnt < 16))then -- new word for the hash
                    cnt := cnt + 1;
                    stop <= '0';
                    data_reg <= w_data;
                end if;
                if ((w_addr > "000000000011") and (w_addr < "000000001000") and (new_word = '1')) then -- status register
                  status_reg(1) <= w_data(1);
                  status_reg(2) <= w_data(2);
                  status_reg(0) <= status_reg(0);
                  stop <= '1';
                end if;
                if ((status_reg(1) = '1') and (waiting = '0')) then -- the SHA256 is not running we can modify control signals
                  new_data <= '1';
                  waiting <= '1';
                  status_reg(0) <= '0';
                  status_reg(1) <= '0';
                  if ((status_reg(2) = '1') and (waiting = '0')) then -- status_reg(1) = new_data status_reg(2) = new_msg
                    new_msg <= '1';
                  else
                    new_msg <= '0';
                  end if;
                  status_reg(2) <= '0';
                else
                  new_data <= '0';
                  new_msg <= '0';
                end if;
                if ((hash_valid = '1') and (waiting = '1') and (new_msg = '0') and (new_data = '0')) then -- the resulting hash is available 
                  reg(2) <= H(0);
                  reg(3) <= H(1);
                  reg(4) <= H(2);
                  reg(5) <= H(3);
                  reg(6) <= H(4);
                  reg(7) <= H(5);
                  reg(8) <= H(6);
                  reg(9) <= H(7);
                  cnt := 0;
                  busy <= '0';
                  waiting <= '0';
                else
                  reg(2) <= reg(2);
                  reg(3) <= reg(3);
                  reg(4) <= reg(4);
                  reg(5) <= reg(5);
                  reg(6) <= reg(6);
                  reg(7) <= reg(7);
                  reg(8) <= reg(8);
                  reg(9) <= reg(9);
                end if;
              else -- reset event zeroes all the status_reg
                new_msg <= '0';
                new_data <= '0';
                waiting <= '0';
                status_reg(0) <= hash_valid;
                status_reg(1) <= '0';
                status_reg(2) <= '0';
                status_reg(31 downto 3) <= (others => '0');
                stop <= '0';
                busy <= '0';
                data_reg <= (others => '0');
                cnt := 0;
              end if;
            end if;
            end process write_ctrl;



  -- update the state of the read FSM at every clock cycle
  read_fsm_updating:    process (aclk)
                        begin
                        if (aclk='1' and aclk'EVENT) then
                                if aresetn='1' then -- no reset event
                                         r_p_state<=r_n_state;
                                else -- reset event
                                         r_p_state<=r_idle;
                                end if;
                        end if;
                        end process read_fsm_updating;


  -- determine the next state of the read FSM based on the value of the input signals
  read_fsm_transition: process(r_p_state,s0_axi_arvalid,s0_axi_araddr,s0_axi_rready,reg)
                        begin
                        case r_p_state is
                                when r_idle => -- wait for the valid address signal
                                        if ((s0_axi_arvalid = '1') and ((s0_axi_araddr < "000000000000") or (s0_axi_araddr > "000001001111" ))) then -- valid is asserted but the range of the address is outside the addressable space (0 to 79)
                                                r_n_state <= r_read;
                                                r_status <= axi_resp_decerr;
                                                r_data  <= (others => '0');
                                        elsif ((s0_axi_arvalid = '1') and ((s0_axi_araddr >= "000000000000") and (s0_axi_araddr < "000010010000" ))) then -- valid is asserted and the address is correct 0 < addr < 80
                                                r_n_state <= r_read;
                                                r_status <= axi_resp_okay;
                                                case s0_axi_araddr is
                                                  when "000000000000" =>
                                                    r_data <= reg(0); -- data reg
                                                  when "000000000100" =>
                                                    r_data <= reg(1); -- status reg
                                                  when "000000001000" =>
                                                    r_data <= reg(2); -- H(1)
                                                  when "000000001100" =>
                                                    r_data <= reg(3); -- H(2)
                                                  when "000000010000" =>
                                                    r_data <= reg(4); -- H(3)
                                                  when "000000010100" =>
                                                    r_data <= reg(5); -- H(4)
                                                  when "000000011000" =>
                                                    r_data <= reg(6); -- H(5)
                                                  when "000000011100" =>
                                                    r_data <= reg(7); -- H(6)
                                                  when "000000100000" =>
                                                    r_data <= reg(8); -- H(7)
                                                  when "000000100100" =>
                                                    r_data <= reg(9); -- H(8)
                                                  when others =>
                                                    r_data <= reg(0); -- data reg
                                                end case;
                                        else -- no valid address signal asserted remains in the same state of before
                                                r_n_state <= r_idle;
                                                r_status <= axi_resp_okay;
                                                r_data <= (others => '0');
                                        end if;
                                when r_read =>
                                        if (s0_axi_rready = '1') then -- ready signal detected form the master return to idle state
                                                r_n_state <= r_idle;
                                        else -- ready signal from the master is not yet asserted wait for it
                                                r_n_state <= r_wait_rready;
                                        end if;
                                when r_wait_rready =>
                                        if (s0_axi_rready = '1') then -- ready signal detected form the master return to idle state
                                                r_n_state <= r_idle;
                                        else -- ready signal from the master is not yet asserted wait for it
                                                r_n_state <= r_wait_rready;
                                        end if;
                                when others =>
                                        r_n_state <= r_idle;
                        end case;
                end process read_fsm_transition;

-- determines the value of the output signals based on the current state of read FSM
 read_outlogic: process (r_p_state,r_data,r_status)
        begin
                -- default value for the output
                s0_axi_arready <= '0';
                s0_axi_rvalid <= '0';
                s0_axi_rresp <= axi_resp_okay;
                s0_axi_rdata <= (others => '0');
                case r_p_state is
                                when r_idle => -- waiting the arvalid signal
                                        s0_axi_arready <= '0';
                                        s0_axi_rvalid <= '0';
                                when r_read => -- arvalid received, set the rvalid and arready signals and put on the output the value read and the response status
                                        s0_axi_arready <= '1';
                                        s0_axi_rvalid <= '1';
                                        s0_axi_rdata  <= r_data;
                                        s0_axi_rresp <= r_status;
                                when r_wait_rready => -- deassert the arready signal rvalid still high waiting for the rready of the master
                                        s0_axi_arready <= '0';
                                        s0_axi_rvalid <= '1';
                                        s0_axi_rdata <= r_data;
                                        s0_axi_rresp <= r_status;
                                when others =>
                                        s0_axi_arready <= '0';
                                        s0_axi_rvalid <= '0';
                                        s0_axi_rdata <= (others => '0');
                                        s0_axi_rresp <= axi_resp_okay;
                        end case;
         end process read_outlogic;

  -- change the state of the write FSM
  write_fsm_updating:   process (aclk)
                        begin
                        if (aclk='1' and aclk'EVENT) then
                                if aresetn='1' then -- no reset received
                                         w_p_state<=w_n_state;
                                else -- reset event
                                         w_p_state<=w_idle;
                                end if;
                        end if;
                        end process write_fsm_updating;
 -- determine the next state of the write FSM
  write_fsm_transition: process(w_p_state,s0_axi_awvalid,s0_axi_wvalid,s0_axi_awaddr,s0_axi_wstrb,s0_axi_bready,s0_axi_wdata,reg)
                        begin
                        case w_p_state is
                                when w_idle =>
                                        if ((s0_axi_awvalid = '1') and (s0_axi_wvalid = '1') and (s0_axi_awaddr >= "000010010000" ) and (busy = '0'))  then -- valid signal of address and data but the address is out of the addressable space  addr > 7
                                                w_n_state <= w_write;
                                                w_status <= axi_resp_decerr; -- set the response status to the write
                                                w_addr <= s0_axi_awaddr; -- save the address of the write
                                                w_data <= (others => '1');
                                        elsif((s0_axi_awvalid = '1') and (s0_axi_wvalid = '1') and ((s0_axi_awaddr >= "000000000111") and (s0_axi_awaddr < "000001001111" )) and (busy = '0')) then -- valid signal of address and data but the pointed location is read-only (ro)   7 < addr < 79
                                                w_n_state <= w_write;
                                                w_status <= axi_resp_slverr; -- set the response status to the write
                                                w_addr <= s0_axi_awaddr; -- save the address of the write
                                                w_data <= (others => '1');
                                        elsif((s0_axi_awvalid = '1') and (s0_axi_wvalid = '1') and (s0_axi_awaddr >= "000000000000") and (s0_axi_awaddr < "000000001000" ) and (busy = '0')) then -- valid signal of address and data write operation in the range 0 < addr < 8 (data or status register)
                                                w_n_state <= w_write;
                                                w_status <= axi_resp_okay; -- set the response status to the write
                                                w_addr <= s0_axi_awaddr; -- save the address of the write
                                                if (s0_axi_wstrb(0) = '1') then -- write the byte (bits 7-0) with the new value received
                                                    w_data(7 downto 0) <= s0_axi_wdata(7 downto 0);
                                                else -- keep the previous value
                                                    w_data(7 downto 0) <= reg(to_integer(unsigned(s0_axi_awaddr(11 downto 2))))(7 downto 0);
                                                end if;
                                                if (s0_axi_wstrb(1) = '1') then -- write the byte (bits 15-8) with the new value received
                                                    w_data(15 downto 8) <= s0_axi_wdata(15 downto 8);
                                                else  -- keep the previous value
                                                    w_data(15 downto 8) <= reg(to_integer(unsigned(s0_axi_awaddr(11 downto 2))))(15 downto 8);
                                                end if;
                                                if (s0_axi_wstrb(2) = '1') then -- write the byte (bits 23-16) with the new value received
                                                    w_data(23 downto 16) <= s0_axi_wdata(23 downto 16);
                                                else -- keep the previous value
                                                    w_data(23 downto 16) <= reg(to_integer(unsigned(s0_axi_awaddr(11 downto 2))))(23 downto 16);
                                                end if;
                                                if (s0_axi_wstrb(3) = '1') then -- write the byte (bits 31-24) with the new value received
                                                    w_data(31 downto 24) <= s0_axi_wdata(31 downto 24);
                                                else -- keep the previous value
                                                    w_data(31 downto 24) <= reg(to_integer(unsigned(s0_axi_awaddr(11 downto 2))))(31 downto 24);
                                                end if;
                                        else -- remain in the same state until the two valid signals are asserted
                                                w_n_state <= w_idle;
                                                w_status <= axi_resp_okay;
                                                w_addr <= s0_axi_awaddr;
                                                w_data <= (others => '1');
                                        end if;
                                when w_write =>
                                        if (s0_axi_bready = '1') then -- bready signal received from the master move to the idle state
                                                w_n_state <= w_idle;
                                        else -- wait the bready signal of the master and deassert the wready and awready signals
                                                w_n_state <= w_wait_bready;
                                        end if;
                                when w_wait_bready =>
                                        if (s0_axi_bready = '1') then -- bready signal received from the master move to the idle state
                                                w_n_state <= w_idle;
                                        else -- wait the bready signal of the master while the  bvalid of the slave remains high
                                                w_n_state <= w_wait_bready;
                                        end if;
                                when others =>
                                        w_n_state <= w_idle;
                        end case;
                end process write_fsm_transition;

-- set the values of the outputs based on the current state of the write FSM
 write_outlogic: process (w_p_state,w_status)
        begin
                -- default values of the outputs
                s0_axi_awready <= '0';
                s0_axi_wready <= '0';
                s0_axi_bvalid <= '0';
                new_word <= '0';
                s0_axi_bresp <= axi_resp_okay;
                case w_p_state is
                                when w_idle => -- wait the wvalid and awvalid signal from the master
                                        s0_axi_wready <= '0';
                                        s0_axi_awready <= '0';
                                        s0_axi_bvalid <= '0';
                                when w_write => -- execute the write operation, put on the output the response status and assert awready, wready and bvalid
                                        new_word <= '1';
                                        s0_axi_wready <= '1';
                                        s0_axi_awready <= '1';
                                        s0_axi_bvalid <= '1';
                                        s0_axi_bresp <= w_status;
                                when w_wait_bready => -- set to zero the awready and wready signals, bvalid remains high and write to the output the response status
                                        new_word <= '0';
                                        s0_axi_wready <= '0';
                                        s0_axi_awready <= '0';
                                        s0_axi_bvalid <= '1';
                                        s0_axi_bresp <= w_status;
                                when others =>
                                        s0_axi_awready <= '0';
                                        s0_axi_wready <= '0';
                                        s0_axi_bvalid <= '0';
                                        s0_axi_bresp <= w_status;
                        end case;
         end process write_outlogic;


end architecture rtl;
