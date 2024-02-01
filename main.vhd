LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
ENTITY kasumi IS
	PORT (
		  clk, rst : IN STD_LOGIC;
		  inp      	: IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
		  key       : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
		  outp 		: OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
		  );
END kasumi;
ARCHITECTURE myarch OF kasumi IS 
	FUNCTION rotleft (input:STD_LOGIC_VECTOR(15 DOWNTO 0); shiftAmount:INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE result, a ,b : STD_LOGIC_VECTOR(15 DOWNTO 0);
	BEGIN
		result := input((16 - shiftAmount) - 1 DOWNTO 0) & input(15 DOWNTO (16 - shiftAmount));
		RETURN result;
	END function;

	function S9(x : std_logic_vector(8 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(8 downto 0);
	begin
        y(0) := (x(0) and x(2)) xor x(3) xor (x(2) and x(5)) xor (x(5) and x(6)) xor (x(0) and x(7)) xor (x(1) and x(7)) xor (x(2) and x(7)) xor (x(4) and x(8)) xor (x(5) and x(8)) xor (x(7) and x(8)) xor '1';
        y(1) := x(1) xor (x(0) and x(1)) xor (x(2) and x(3)) xor (x(0) and x(4)) xor (x(1) and x(4)) xor (x(0) and x(5)) xor (x(3) and x(5)) xor x(6) xor (x(1) and x(7)) xor (x(2) and x(7)) xor (x(5) and x(8)) xor '1';
        y(2) := x(1) xor (x(0) and x(3)) xor (x(3) and x(4)) xor (x(0) and x(5)) xor (x(2) and x(6)) xor (x(3) and x(6)) xor (x(5) and x(6)) xor (x(4) and x(7)) xor (x(5) and x(7)) xor (x(6) and x(7)) xor x(8) xor (x(0) and x(8)) xor '1';
        y(3) := x(0) xor (x(1) and x(2)) xor (x(0) and x(3)) xor (x(2) and x(4)) xor x(5) xor (x(0) and x(6)) xor (x(1) and x(6)) xor (x(4) and x(7)) xor (x(0) and x(8)) xor (x(1) and x(8)) xor (x(7) and x(8));
        y(4) := (x(0) and x(1)) xor (x(1) and x(3)) xor x(4) xor (x(0) and x(5)) xor (x(3) and x(6)) xor (x(0) and x(7)) xor (x(6) and x(7)) xor (x(1) and x(8)) xor (x(2) and x(8)) xor (x(3) and x(8));
        y(5) := x(2) xor (x(1) and x(4)) xor (x(4) and x(5)) xor (x(0) and x(6)) xor (x(1) and x(6)) xor (x(3) and x(7)) xor (x(4) and x(7)) xor (x(6) and x(7)) xor (x(5) and x(8)) xor (x(6) and x(8)) xor (x(7) and x(8)) xor '1';
        y(6) := x(0) xor (x(2) and x(3)) xor (x(1) and x(5)) xor (x(2) and x(5)) xor (x(4) and x(5)) xor (x(3) and x(6)) xor (x(4) and x(6)) xor (x(5) and x(6)) xor x(7) xor (x(1) and x(8)) xor (x(3) and x(8)) xor (x(5) and x(8)) xor (x(7) and x(8));
        y(7) := (x(0) and x(1)) xor (x(0) and x(2)) xor (x(1) and x(2)) xor x(3) xor (x(0) and x(3)) xor (x(2) and x(3)) xor (x(4) and x(5)) xor (x(2) and x(6)) xor (x(3) and x(6)) xor (x(2) and x(7)) xor (x(5) and x(7)) xor x(8) xor '1';
        y(8) := (x(0) and x(1)) xor x(2) xor (x(1) and x(2)) xor (x(3) and x(4)) xor (x(1) and x(5)) xor (x(2) and x(5)) xor (x(1) and x(6)) xor (x(4) and x(6)) xor x(7) xor (x(2) and x(8)) xor (x(3) and x(8));
		return y;
	end function;


	function S7(x : std_logic_vector(6 downto 0)) return std_logic_vector is
		variable y : std_logic_vector(6 downto 0);
	begin
		y(0) := (x(1) AND x(3)) xor x(4) xor (x(0) AND x(1) AND x(4)) xor x(5) xor (x(2) AND x(5)) xor (x(3) AND x(4) AND x(5)) xor x(6) xor (x(0) AND x(6)) xor (x(1) AND x(6)) xor (x(3) AND x(6)) xor (x(2) AND x(4) AND x(6)) xor (x(1) AND x(5) AND x(6)) xor (x(4) AND x(5) AND x(6));
		y(1) := (x(0) AND x(1)) xor (x(0) AND x(4)) xor (x(2) AND x(4)) xor x(5) xor (x(1) AND x(2) AND x(5)) xor (x(0) AND x(3) AND x(5)) xor x(6) xor (x(0) AND x(2) AND x(6)) xor (x(3) AND x(6)) xor (x(4) AND x(5) AND x(6)) xor '1';
		y(2) := x(0) xor (x(0) AND x(3)) xor (x(2) AND x(3)) xor (x(1) AND x(2) AND x(4)) xor (x(0) AND x(3) AND x(4)) xor (x(1) AND x(5)) xor (x(0) AND x(2) AND x(5)) xor (x(0) AND x(6)) xor (x(0) AND x(1) AND x(6)) xor (x(2) AND x(6)) xor (x(4) AND x(6)) xor '1';
		y(3) := x(1) xor (x(0) AND x(1) AND x(2)) xor (x(1) AND x(4)) xor (x(3) AND x(4)) xor (x(0) AND x(5)) xor (x(0) AND x(1) AND x(5)) xor (x(2) AND x(3) AND x(5)) xor (x(1) AND x(4) AND x(5)) xor (x(2) AND x(6)) xor (x(1) AND x(3) AND x(6));
		y(4) := (x(0) AND x(2)) xor x(3) xor (x(1) AND x(3)) xor (x(1) AND x(4)) xor (x(0) AND x(1) AND x(4)) xor (x(2) AND x(3) AND x(4)) xor (x(0) AND x(5)) xor (x(1) AND x(3) AND x(5)) xor (x(0) AND x(4) AND x(5)) xor (x(1) AND x(6)) xor (x(3) AND x(6)) xor (x(0) AND x(3) AND x(6)) xor (x(5) AND x(6)) xor '1';
		y(5) := x(2) xor (x(0) AND x(2)) xor (x(0) AND x(3)) xor (x(1) AND x(2) AND x(3)) xor (x(0) AND x(2) AND x(4)) xor (x(0) AND x(5)) xor (x(2) AND x(5)) xor (x(4) AND x(5)) xor (x(1) AND x(6)) xor (x(1) AND x(2) AND x(6)) xor (x(0) AND x(3) AND x(6)) xor (x(3) AND x(4) AND x(6)) xor (x(2) AND x(5) AND x(6)) xor '1';
		y(6) := (x(1) AND x(2)) xor (x(0) AND x(1) AND x(3)) xor (x(0) AND x(4)) xor (x(1) AND x(5)) xor (x(3) AND x(5)) xor x(6) xor (x(0) AND x(1) AND x(6)) xor (x(2) AND x(3) AND x(6)) xor (x(1) AND x(4) AND x(6)) xor (x(0) AND x(5) AND x(6));		
		return y;
	end function;

    FUNCTION FI (
        input: STD_LOGIC_VECTOR(15 downto 0);
		KI: STD_LOGIC_VECTOR(15 downto 0)
    ) RETURN STD_LOGIC_VECTOR IS
        variable l0, r1, l2, r3, r4 : std_logic_vector(8 downto 0);
		variable r0, l1, r2, l3, l4 : std_logic_vector(6 downto 0);
		variable ki1 : std_logic_vector(6 downto 0);
		variable ki2 : std_logic_vector(8 downto 0);
    begin
		ki1 := KI(15 downto 9);
		ki2 := KI(8 downto 0);

		l0 := input(15 downto 7);
		r0 := input(6 downto 0);

		l1 := r0;
		r1 := S9(l0) xor ("00" & r0);

		l2 := r1 xor ki2;
		r2 := S7(l1) xor r1(6 downto 0) xor ki1;

		l3 := r2;
		r3 := S9(l2) xor ("00" & r2);

		l4 := S7(l3) xor r3(6 downto 0);
		r4 := r3;
		
		return l4 & r4;
    end function;

	function FO(
		input : std_logic_vector(31 downto 0);
		KI, KO : std_logic_vector(47 downto 0)
	) return std_logic_vector is
		variable l0, l1, l2, l3, r0, r1, r2, r3, ko1, ko2, ko3, ki1, ki2, ki3 : std_logic_vector(15 downto 0);
	begin
		l0 := input(31 downto 16);
		r0 := input(15 downto 0);

		ko1 := KO(47 downto 32);
		ko2 := KO(31 downto 16);
		ko3 := KO(15 downto 0);

		ki1 := KI(47 downto 32);
		ki2 := KI(31 downto 16);
		ki3 := KI(15 downto 0);

		r1 := FI(l0 xor ko1, ki1) xor r0;
		l1 := r0;

		r2 := FI(l1 xor ko2, ki2) xor r1;
		l2 := r1;

		r3 := FI(l2 xor ko3, ki3) xor r2;
		l3 := r2;

		return l3 & r3;
	end function;
	
	function FL(
		input : std_logic_vector(31 downto 0);
		KL : std_logic_vector(31 downto 0)
	) return std_logic_vector is
		variable l, r, lp, rp, kl1, kl2 : std_logic_vector(15 downto 0);
	begin
		l := input(31 downto 16);
		r := input(15 downto 0);

		kl1 := KL(31 downto 16);
		kl2 := KL(15 downto 0);

		rp := r xor (rotleft(l and kl1, 1));
		lp := l xor (rotleft(rp or kl2, 1));

		return lp & rp;
	end function;
	
	function f(
		input : std_logic_vector(31 downto 0);
		KL    : std_logic_vector(31 downto 0);
		KO, KI : std_logic_vector(47 downto 0);
		i : integer
	) return std_logic_vector is
		variable O : std_logic_vector(31 downto 0);
	begin
		if (i = 1 or i = 3 or i = 5 or i = 7) then
			O := FO(FL(input, KL), KO, KI);
		elsif (i = 2 or i = 4 or i = 6 or i = 8) then
			O := FL(FO(input, KO, KI), KL);
		end if;

		return O;
	end function;
BEGIN
	process( clk )
		variable k1, k2, k3, k4, k5, k6, k7, k8 : std_logic_vector(15 downto 0);
		variable k1p, k2p, k3p, k4p, k5p, k6p, k7p, k8p : std_logic_vector(15 downto 0);
		-- variable KL1, KL2, KL3, KL4, KL5, KL6, KL7, KL8 : std_logic_vector(31 downto 0);
		type matrix_48 is array (0 to  7) of std_logic_vector(47 downto 0);
		variable KO, KI : matrix_48;
		type matrix_32 is array (0 to  7) of std_logic_vector(31 downto 0);
		variable KL : matrix_32;
		-- variable KO1, KO2, KO3, KO4, KO5, KO6, KO7, KO8 : std_logic_vector(47 downto 0);
		-- variable KI1, KI2, KI3, KI4, KI5, KI6, KI7, KI8 : std_logic_vector(47 downto 0);
		-- variable l0, l1, l2, l3, l4, l5, l6, l7, l8 : std_logic_vector(31 downto 0) ;
		-- variable r0, r1, r2, r3, r4, r5, r6, r7, r8 : std_logic_vector(31 downto 0) ;
		variable l, r, temp : std_logic_vector(31 downto 0);
		variable i : integer := 0;
	begin
		if (clk'event and clk = '1') then
			if (rst = '0') then
				outp <= x"0000000000000000";
				i := 0;
			else
				k1 := key(127 downto 112);
				k2 := key(111 downto 96);
				k3 := key(95 downto 80);
				k4 := key(79 downto 64);
				k5 := key(63 downto 48);
				k6 := key(47 downto 32);
				k7 := key(31 downto 16);
				k8 := key(15 downto 0);

				k1p := k1 xor x"0123";
				k2p := k2 xor x"4567";
				k3p := k3 xor x"89AB";
				k4p := k4 xor x"CDEF";
				k5p := k5 xor x"FEDC";
				k6p := k6 xor x"BA98";
				k7p := k7 xor x"7654";
				k8p := k8 xor x"3210";

				KL(0) := rotleft(k1, 1) & k3p;
				KL(1) := rotleft(k2, 1) & k4p;
				KL(2) := rotleft(k3, 1) & k5p;
				KL(3) := rotleft(k4, 1) & k6p;
				KL(4) := rotleft(k5, 1) & k7p;
				KL(5) := rotleft(k6, 1) & k8p;
				KL(6) := rotleft(k7, 1) & k1p;
				KL(7) := rotleft(k8, 1) & k2p;

				KO(0) := rotleft(k2, 5) & rotleft (k6, 8) & rotleft(k7, 13);
				KO(1) := rotleft(k3, 5) & rotleft (k7, 8) & rotleft(k8, 13);
				KO(2) := rotleft(k4, 5) & rotleft (k8, 8) & rotleft(k1, 13);
				KO(3) := rotleft(k5, 5) & rotleft (k1, 8) & rotleft(k2, 13);
				KO(4) := rotleft(k6, 5) & rotleft (k2, 8) & rotleft(k3, 13);
				KO(5) := rotleft(k7, 5) & rotleft (k3, 8) & rotleft(k4, 13);
				KO(6) := rotleft(k8, 5) & rotleft (k4, 8) & rotleft(k5, 13);
				KO(7) := rotleft(k1, 5) & rotleft (k5, 8) & rotleft(k6, 13);

				KI(0) := k5p & k4p & k8p;
				KI(1) := k6p & k5p & k1p;
				KI(2) := k7p & k6p & k2p;
				KI(3) := k8p & k7p & k3p;
				KI(4) := k1p & k8p & k4p;
				KI(5) := k2p & k1p & k5p;
				KI(6) := k3p & k2p & k6p;
				KI(7) := k4p & k3p & k7p;

				if (i = 0) then
					r := inp(31 downto 0);
					l := inp(63 downto 32);
					i := i + 1;
				elsif (i /= 9) then
					temp := l;
					l := r xor f(l, KL(i-1), KO(i-1), KI(i-1), i);
					r := temp;
					if (i = 8) then
						outp <= l & r;
					end if;
					i := i + 1;
				end if;
			end if;

		end if;

	end process ;
	
END myarch;
