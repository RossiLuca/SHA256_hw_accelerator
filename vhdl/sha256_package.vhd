library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
library std;
use std.textio.all;

package sha256_pkg is

  ---------------------
  -- type definition --
  ---------------------

  subtype word is std_ulogic_vector(31 downto 0);
  type word_vector is array (integer range <>) of word;
  subtype sha256_blk is std_ulogic_vector(511 downto 0);
  subtype sha256 is std_ulogic_vector(255 downto 0);
  type sha256data is array (integer range <>) of sha256_blk;

  -------------------------
  -- constant definition --
  -------------------------

  constant K_constants :  word_vector(0 to 63) := (
        x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5", x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
        x"d807aa98", x"12835b01", x"243185be", x"550c7dc3", x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
        x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc", x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
        x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7", x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
        x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13", x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
        x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3", x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
        x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5", x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
        x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208", x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2"
  );

  constant H_init : word_vector(0 to 7) := (
    x"6a09e667",
    x"bb67ae85",
    x"3c6ef372",
    x"a54ff53a",
    x"510e527f",
    x"9b05688c",
    x"1f83d9ab",
    x"5be0cd19"
  );

  ------------------------
  -- function prototype --
  ------------------------

  function rot_r (x : word; n : natural) return std_ulogic_vector; -- rotate right x of n positions
  function shift_r (x : word; n : natural) return std_ulogic_vector; -- shift right x of n positions
  function Ch (x, y, z : word) return std_ulogic_vector;       -- (x /\ y ) xor ( not x /\ z )
  function Maj (x, y, z : word) return std_ulogic_vector;      -- (x /\ y ) xor ( x /\ z ) xor (y /\ z)
  function sigma_upper0 (x : word) return std_ulogic_vector;   -- (S2(x)) xor (S13(x)) xor (S22(x))
  function sigma_upper1 (x : word) return std_ulogic_vector;   -- (S6(x)) xor (S11(x)) xor (S25(x))
  function sigma_lower0 (x : word) return std_ulogic_vector;   -- (S7(x)) xor (S18(x)) xor (R3(x))
  function sigma_lower1 (x : word) return std_ulogic_vector;   -- (S17(x)) xor (S19(x)) xor (R10(x))
  function M_parsing (msg : sha256_blk) return word_vector;  -- split the message in 16 M blocks of 32 bits each
  function exp_W (M : word_vector(15 downto 0)) return word_vector;
  function hash_value (hash : sha256) return word_vector; -- extract the h(0) h(1...) from sha256
  function sha256_fun (msg : sha256_blk) return std_ulogic_vector; -- apply the sha256 algorithm on a block
  function sha256_comp (msg : sha256data; N : natural) return std_ulogic_vector; -- apply the sha256 algorithm on a msg made of multiple blocks


end sha256_pkg;



package body sha256_pkg is

  -------------------
  --  rot_r (x, n) --
  -------------------

  function rot_r (x : word; n : natural ) return std_ulogic_vector is -- rotate right x of n positions
    begin
        return std_ulogic_vector(rotate_right(unsigned(x),n));
  end function;

  ---------------------
  --  shift_r (x, n) --
  ---------------------

  function shift_r (x : word; n : natural ) return std_ulogic_vector is -- shift right x of n positions
  variable zero : std_ulogic_vector ((n-1) downto 0);
    begin
        return std_ulogic_vector(shift_right(unsigned(x),n));
  end function;

  ------------------
  --  Ch(x, y, z) --
  ------------------

  function Ch (x, y, z : word) return std_ulogic_vector is  -- (x /\ y ) xor ( not x /\ z )
    begin
        return ((x and y) xor ((not x) and z));
  end function;

  -------------------
  --  Maj(x, y, z) --
  -------------------

  function Maj (x, y, z : word) return std_ulogic_vector is  -- (x /\ y ) xor ( x /\ z ) xor (y /\ z)
    begin
        return ((x and y) xor ( x and z) xor (y and z));
  end function;

  -----------------------
  --  sigma_upper0(x)  --
  -----------------------

  function sigma_upper0 (x : word) return std_ulogic_vector is   -- (S2(x)) xor (S13(x)) xor (S22(x))
    begin
        return (rot_r(x, 2) xor rot_r(x, 13) xor rot_r(x, 22));
  end function;

  -----------------------
  --  sigma_upper1(x)  --
  -----------------------

  function sigma_upper1 (x : word) return std_ulogic_vector is   -- (S6(x)) xor (S11(x)) xor (S25(x))
    begin
        return (rot_r(x, 6) xor rot_r(x, 11) xor rot_r(x, 25));
  end function;

  -----------------------
  --  sigma_lower0(x)  --
  -----------------------

  function sigma_lower0 (x : word) return std_ulogic_vector is    -- (S7(x)) xor (S18(x)) xor (R3(x))
    begin
        return (rot_r(x, 7) xor rot_r(x, 18) xor shift_r(x, 3));
  end function;

  -----------------------
  --  sigma_lower1(x)  --
  -----------------------

  function sigma_lower1 (x : word) return std_ulogic_vector is   -- (S17(x)) xor (S19(x)) xor (R10(x))
    begin
        return (rot_r(x, 17) xor rot_r(x, 19) xor shift_r(x, 10));
  end function;

  -------------------
  --  M_parsing(x) --
  -------------------

  function M_parsing (msg : sha256_blk) return word_vector is -- split the message in 16 M blocks of 32 bits each
  variable M: word_vector(15 downto 0);
    begin
       for i in 0 to 15 loop
          M(i) := msg((((16-i)*32)-1) downto ((16-i-1)*32));
      end loop;
      return M;
  end function;



  ----------------
  --  exp_w(M)  --
  ----------------

  function exp_W (M : word_vector(15 downto 0)) return word_vector is
  variable W: word_vector(63 downto 0);
    begin
        for i in 0 to 15 loop
          W(i) := M(i);
        end loop;
        for i in 16 to 63 loop
          W(i) := word(unsigned(sigma_lower1(W(i-2))) + unsigned(W(i-7)) + unsigned(sigma_lower0(W(i-15))) + unsigned(W(i-16)));
        end loop;
        return W;
  end function;

  ----------------------
  -- hash_value(hash) --
  ----------------------

  function hash_value (hash : sha256) return word_vector is -- extract the h(0) h(1...) from sha256
  variable H: word_vector(7 downto 0);
    begin
       for i in 0 to 7 loop
          H(i) := hash((((8-i)*32)-1) downto ((8-i-1)*32));
      end loop;
      return H;
  end function;

  ----------------------
  -- sha256_fun(hash) --
  ----------------------

  function sha256_fun (msg : sha256_blk) return std_ulogic_vector is -- apply the sha256 algorithm on a block
  variable a,b,c,d,e,f,g,h : word;
  variable h1, h2, h3, h4, h5, h6, h7, h8 : word;
  variable t1, t2 : word;
  variable W : word_vector(63 downto 0);
  variable M : word_vector(15 downto 0);
  variable myline : line;
  file myfile: text open WRITE_MODE is "/dev/stdout";
    begin

        h1  := H_init(0);
        h2  := H_init(1);
        h3  := H_init(2);
        h4  := H_init(3);
        h5  := H_init(4);
        h6  := H_init(5);
        h7  := H_init(6);
        h8  := H_init(7);


        a := h1;
        b := h2;
        c := h3;
        d := h4;
        e := h5;
        f := h6;
        g := h7;
        h := h8;


        M := M_parsing(msg);

        W := exp_W(M);

        --for i in 0 to 63 loop
        --    write(myline,i);
        --   write(myline,string'(" 0x"));
        --    hwrite(myline,W(i));
        --    writeline(myfile,myline);
        --end loop;
        for j in 0 to 63 loop
        --    hwrite(myline,K_constants(j));
        --    write(myline,string'(" 0x"));
            t1 := word(unsigned(h) + unsigned(sigma_upper1(e)) + unsigned(Ch(e, f, g)) + unsigned(K_constants(j)) + unsigned(W(j)));
            t2 := word(unsigned(sigma_upper0(a)) + unsigned(Maj(a, b, c)));
            h := g;
            g := f;
            f := e;
            e := word(unsigned(d) + unsigned(t1));
            d := c;
            c := b;
            b := a;
            a := word(unsigned(t1) + unsigned(t2));
            write(myline,string'(" Round "));
            write(myline,j);
            write(myline,string'(" a 0x"));
            hwrite(myline,a);
            write(myline,string'(" b 0x"));
            hwrite(myline,b);
            write(myline,string'(" c 0x"));
            hwrite(myline,c);
            write(myline,string'(" d 0x"));
            hwrite(myline,d);
            write(myline,string'(" e 0x"));
            hwrite(myline,e);
            write(myline,string'(" f 0x"));
            hwrite(myline,f);
            write(myline,string'(" g 0x"));
            hwrite(myline,g);
            write(myline,string'(" h 0x"));
            hwrite(myline,h);
            writeline(myfile,myline);
        end loop;

        h1 := std_ulogic_vector(unsigned(a) + unsigned(h1));
        h2 := std_ulogic_vector(unsigned(b) + unsigned(h2));
        h3 := std_ulogic_vector(unsigned(c) + unsigned(h3));
        h4 := std_ulogic_vector(unsigned(d) + unsigned(h4));
        h5 := std_ulogic_vector(unsigned(e) + unsigned(h5));
        h6 := std_ulogic_vector(unsigned(f) + unsigned(h6));
        h7 := std_ulogic_vector(unsigned(g) + unsigned(h7));
        h8 := std_ulogic_vector(unsigned(h) + unsigned(h8));

            write(myline,string'(" h8 0x"));
            hwrite(myline,h8);
            write(myline,string'(" h7 0x"));
            hwrite(myline,h7);
            write(myline,string'(" h6 0x"));
            hwrite(myline,h6);
            write(myline,string'(" h5 0x"));
            hwrite(myline,h5);
            write(myline,string'(" h4 0x"));
            hwrite(myline,h4);
            write(myline,string'(" h3 0x"));
            hwrite(myline,h3);
            write(myline,string'(" h2 0x"));
            hwrite(myline,h2);
            write(myline,string'(" h1 0x"));
            hwrite(myline,h1);
            writeline(myfile,myline);

        return h1 & h2 & h3 & h4 & h5 & h6 & h7 & h8;

  end function;


  ----------------------
  -- sha256_comp(hash) --
  ----------------------

  function sha256_comp (msg : sha256data; N : natural) return std_ulogic_vector is -- apply the sha256 algorithm on multiple
  variable a,b,c,d,e,f,g,h : word;
  variable h1, h2, h3, h4, h5, h6, h7, h8 : word;
  variable t1, t2 : word;
  variable W : word_vector(63 downto 0);
  variable M : word_vector(15 downto 0);
  variable hash : sha256;
  variable H_int: word_vector(7 downto 0);
  variable myline : line;
  file myfile: text open WRITE_MODE is "/dev/stdout";
    begin

        h1  := H_init(0);
        h2  := H_init(1);
        h3  := H_init(2);
        h4  := H_init(3);
        h5  := H_init(4);
        h6  := H_init(5);
        h7  := H_init(6);
        h8  := H_init(7);


        a := h1;
        b := h2;
        c := h3;
        d := h4;
        e := h5;
        f := h6;
        g := h7;
        h := h8;


  for i in 0 to (N-1) loop

       write(myline,string'(" Block "));
       write(myline,i);
       writeline(myfile,myline);

        M := M_parsing(msg(i));

        W := exp_W(M);

        --for i in 0 to 63 loop
        --    write(myline,i);
        --   write(myline,string'(" 0x"));
        --    hwrite(myline,W(i));
        --    writeline(myfile,myline);
        --end loop;
        for j in 0 to 63 loop
        --    hwrite(myline,K_constants(j));
        --    write(myline,string'(" 0x"));
            t1 := word(unsigned(h) + unsigned(sigma_upper1(e)) + unsigned(Ch(e, f, g)) + unsigned(K_constants(j)) + unsigned(W(j)));
            t2 := word(unsigned(sigma_upper0(a)) + unsigned(Maj(a, b, c)));
            h := g;
            g := f;
            f := e;
            e := word(unsigned(d) + unsigned(t1));
            d := c;
            c := b;
            b := a;
            a := word(unsigned(t1) + unsigned(t2));
            write(myline,string'(" Round "));
            write(myline,j);
            write(myline,string'(" a 0x"));
            hwrite(myline,a);
            write(myline,string'(" b 0x"));
            hwrite(myline,b);
            write(myline,string'(" c 0x"));
            hwrite(myline,c);
            write(myline,string'(" d 0x"));
            hwrite(myline,d);
            write(myline,string'(" e 0x"));
            hwrite(myline,e);
            write(myline,string'(" f 0x"));
            hwrite(myline,f);
            write(myline,string'(" g 0x"));
            hwrite(myline,g);
            write(myline,string'(" h 0x"));
            hwrite(myline,h);
            writeline(myfile,myline);
        end loop;

        h1 := std_ulogic_vector(unsigned(a) + unsigned(h1));
        h2 := std_ulogic_vector(unsigned(b) + unsigned(h2));
        h3 := std_ulogic_vector(unsigned(c) + unsigned(h3));
        h4 := std_ulogic_vector(unsigned(d) + unsigned(h4));
        h5 := std_ulogic_vector(unsigned(e) + unsigned(h5));
        h6 := std_ulogic_vector(unsigned(f) + unsigned(h6));
        h7 := std_ulogic_vector(unsigned(g) + unsigned(h7));
        h8 := std_ulogic_vector(unsigned(h) + unsigned(h8));


            write(myline,string'(" h8 0x"));
            hwrite(myline,h8);
            write(myline,string'(" h7 0x"));
            hwrite(myline,h7);
            write(myline,string'(" h6 0x"));
            hwrite(myline,h6);
            write(myline,string'(" h5 0x"));
            hwrite(myline,h5);
            write(myline,string'(" h4 0x"));
            hwrite(myline,h4);
            write(myline,string'(" h3 0x"));
            hwrite(myline,h3);
            write(myline,string'(" h2 0x"));
            hwrite(myline,h2);
            write(myline,string'(" h1 0x"));
            hwrite(myline,h1);
            writeline(myfile,myline);


        a := h1;
        b := h2;
        c := h3;
        d := h4;
        e := h5;
        f := h6;
        g := h7;
        h := h8;

  end loop;

        return h1 & h2 & h3 & h4 & h5 & h6 & h7 & h8;

  end function;

end package body sha256_pkg;
