LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
ENTITY kasumi IS
	PORT (
		  clk, nrst : IN STD_LOGIC;
		  inp      	: IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
		  key       : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
		  outp 		: OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
		  );
END kasumi;
ARCHITECTURE myarch OF kasumi IS 
	TYPE state IS (TEMP, initial_state, S1, S2, S3, S4, S5, S6, S7, S8);
	SIGNAL cur_state : state;
	SIGNAL nxt_state : state;
	SIGNAL regleft, regright : STD_LOGIC_VECTOR(31 DOWNTO 0);
	TYPE matrix IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
	TYPE matrix_2d_for_s7 IS ARRAY (0 TO 7, 15 DOWNTO 0) OF INTEGER;
	TYPE matrix_2d_for_s9 IS ARRAY (0 TO 31, 15 DOWNTO 0) OF INTEGER;

	SIGNAL FO,FL     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
	
	SIGNAL KL1 : matrix;
	SIGNAL KL2 : matrix;
	SIGNAL KO1 : matrix;
	SIGNAL KO2 : matrix;
	SIGNAL KO3 : matrix;
	SIGNAL KI1 : matrix;
	SIGNAL KI2 : matrix;
	SIGNAL KI3 : matrix;
	SIGNAL S_boxes7 : matrix_2d_for_s7 :=(
--   0    1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
	(54 , 50, 62, 56, 22, 34, 94, 96, 38, 6 , 63, 93, 2 , 18,123, 33),
	(55 ,113, 39,114, 21, 67, 65, 12, 47, 73, 46, 27, 25,111,124, 81),
	(53 , 9 ,121, 79, 52, 60, 58, 48,101,127, 40,120,104, 70, 71, 43),
	(20 ,122, 72, 61, 23,109, 13,100, 77, 1 , 16, 7 , 82, 10,105, 98),
	(117,116, 76, 11, 89,106, 0 ,125,118, 99, 86, 69, 30, 57,126, 87),
	(112, 51, 17, 5 , 95, 14, 90, 84, 91, 8 , 35,103, 32, 97, 28, 66),
	(102, 31, 26, 45, 75, 4 , 85, 92, 37, 74, 80, 49, 68, 29,115, 44),
	(64 ,107,108, 24,110, 83, 36, 78, 42, 19, 15, 41, 88,119, 59, 3)
	);
	SIGNAL S_boxes9 : matrix_2d_for_s9 :=(
--    0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15	
	(167,239,161,379,391,334, 9 ,338, 38,226, 48,358,452,385, 90,397),
	(183,253,147,331,415,340, 51,362,306,500,262, 82,216,159,356,177),
	(175,241,489, 37,206, 17, 0 ,333, 44,254,378, 58,143,220, 81,400),
	(95 , 3 ,315,245, 54,235,218,405,472,264,172,494,371,290,399, 76),
	(165,197,395,121,257,480,423,212,240, 28,462,176,406,507,288,223),
	(501,407,249,265, 89,186,221,428,164, 74,440,196,458,421,350,163),
	(232,158,134,354, 13,250,491,142,191, 69,193,425,152,227,366,135),
	(344,300,276,242,437,320,113,278, 11,243, 87,317, 36, 93,496, 27),
	(487,446,482, 41, 68,156,457,131,326,403,339, 20, 39,115,442,124),
	(475,384,508, 53,112,170,479,151,126,169, 73,268,279,321,168,364),
	(363,292, 46,499,393,327,324, 24,456,267,157,460,488,426,309,229),
	(439,506,208,271,349,401,434,236, 16,209,359, 52, 56,120,199,277),
	(465,416,252,287,246, 6 , 83,305,420,345,153,502, 65, 61,244,282),
	(173,222,418, 67,386,368,261,101,476,291,195,430, 49, 79,166,330),
	(280,383,373,128,382,408,155,495,367,388,274,107,459,417, 62,454),
	(132,225,203,316,234, 14,301, 91,503,286,424,211,347,307,140,374),
	(35 ,103,125,427, 19,214,453,146,498,314,444,230,256,329,198,285),
	(50 ,116, 78,410, 10,205,510,171,231, 45,139,467, 29, 86,505, 32),
	(72 , 26,342,150,313,490,431,238,411,325,149,473, 40,119,174,355),
	(185,233,389, 71,448,273,372, 55,110,178,322, 12,469,392,369,190),
	(1  ,109,375,137,181, 88, 75,308,260,484, 98,272,370,275,412,111),
	(336,318, 4 ,504,492,259,304, 77,337,435, 21,357,303,332,483, 18),
	(47 , 85, 25,497,474,289,100,269,296,478,270,106, 31,104,433, 84),
	(414,486,394, 96, 99,154,511,148,413,361,409,255,162,215,302,201),
	(266,351,343,144,441,365,108,298,251, 34,182,509,138,210,335,133),
	(311,352,328,141,396,346,123,319,450,281,429,228,443,481, 92,404),
	(485,422,248,297, 23,213,130,466, 22,217,283, 70,294,360,419,127),
	(312,377, 7 ,468,194, 2 ,117,295,463,258,224,447,247,187, 80,398),
	(284,353,105,390,299,471,470,184, 57,200,348, 63,204,188, 33,451),
	(97 , 30,310,219, 94,160,129,493, 64,179,263,102,189,207,114,402),
	(438,477,387,122,192, 42,381, 5 ,145,118,180,449,293,323,136,380),
	(43 , 66, 60,455,341,445,202,432, 8,237, 15 ,376,436,464, 59,461)
	);

	FUNCTION "rol" (SIGNAL input:STD_LOGIC_VECTOR(15 DOWNTO 0); shiftAmount:INTEGER) RETURN STD_LOGIC_VECTOR IS
		VARIABLE result, a ,b : STD_LOGIC_VECTOR(15 DOWNTO 0);
	BEGIN
		result := input((16 - shiftAmount) - 1 DOWNTO 0) & input(15 DOWNTO (16 - shiftAmount));
		RETURN result;
	
	END "rol";


	
	
	
BEGIN
	
	PROCESS (cur_state)
		VARIABLE rightinp   : STD_LOGIC_VECTOR(31 DOWNTO 0);
		VARIABLE leftinp    : STD_LOGIC_VECTOR(31 DOWNTO 0);
		-- VARIABLE FL, FO     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
		-- VARIABLE FL     : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
		VARIABLE k : matrix := (others => (others => '0'));
		VARIABLE c : matrix;
	
		VARIABLE FI         : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
		VARIABLE FLright, FLleft : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

		VARIABLE FOright, FOleft : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
		
		VARIABLE FIright, FIrightcopy : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
		VARIABLE FIleft , FIleftcopy  : STD_LOGIC_VECTOR(8 DOWNTO 0) := (OTHERS => '0');
		
		VARIABLE temp32 : STD_LOGIC_VECTOR(31 DOWNTO 0);
		VARIABLE temp64 : STD_LOGIC_VECTOR(63 DOWNTO 0);
		VARIABLE temp15left, temp15leftcopy, temp15right, temp15rightcopy : STD_LOGIC_VECTOR(15 DOWNTO 0);
		
		VARIABLE s7boxrox : INTEGER;
		VARIABLE s7boxcol : INTEGER;
		VARIABLE s9boxrox : INTEGER;
		VARIABLE s9boxcol : INTEGER;

		VARIABLE kaprim : matrix;

	BEGIN 
		CASE cur_state IS 
			WHEN initial_state =>
				--k matrix
				k(0) := key(127 DOWNTO 112);
				k(1) := key(111 DOWNTO 96);
				k(2) := key(95  DOWNTO 80);
				k(3) := key(79  DOWNTO 64);
				k(4) := key(63  DOWNTO 48);
				k(5) := key(47  DOWNTO 32);
				k(6) := key(31  DOWNTO 16);
				k(7) := key(15  DOWNTO 0);
				--c matix
				c(0) := x"0123";
				c(1) := x"4567";
				c(2) := x"89AB";
				c(3) := x"CDEF";
				c(4) := x"FEDC";
				c(5) := x"BA98";
				c(6) := x"7654";
				c(7) := x"3210";
			
				--kaprim matrix
				FOR i IN 0 TO 7 LOOP 
					kaprim(i) := k(i) XOR c(i); 
				END LOOP;
			
				--KL1 matrix
				FOR i IN 0 TO 7 LOOP
					KL1(i) <= k(i) rol 1;
				END LOOP;
				
				--KL2 matrix
				FOR i IN 0 TO 7 LOOP
					KL2(i) <= kaprim((i+2) MOD 8);
				END LOOP;
				
				--KO1 matrix	
				FOR i IN 0 TO 7 LOOP
					KO1(i) <= k((i+1) MOD 8) rol 5;
				END LOOP;
				
				-- KO2 matrix
				FOR i IN 0 TO 7 LOOP
					KO2(i) <= k((i+5) MOD 8) rol 8;
				END LOOP;
				
				-- KO3 matrix
				FOR i IN 0 TO 7 LOOP
					KO3(i) <= k((i+6) MOD 8) rol 13;
				END LOOP;
				
				-- KI1 matrix
				FOR i IN 0 TO 7 LOOP
					KI1(i) <= kaprim((i+4) MOD 8);
				END LOOP;
				
				-- KI2 matrix
				FOR i IN 0 TO 7 LOOP
					KI2(i) <= kaprim((i+3) MOD 8);
				END LOOP;
				
				-- KI3 matrix
				FOR i IN 0 TO 7 LOOP
					KI3(i) <= kaprim((i+7) MOD 8);
				END LOOP;
				regleft  <= inp(63 DOWNTO 32);
				regright <= inp(31 DOWNTO 0);
				
 				nxt_state <= S1;
			WHEN S1 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FL function
				FLleft := leftinp(31 DOWNTO 16); 
				FLright := leftinp(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(0);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(0);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				-- FO function
				FOleft := FL(31 DOWNTO 16); FOright := FL(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(0);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(0)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(0)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(0);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(0)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(0)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(0);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(0)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(0)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				temp32 := leftinp;
				leftinp  := FO XOR rightinp;
				rightinp := temp32;
				regleft  <= leftinp;
				regright <= rightinp;
				nxt_state <= S2;
			WHEN S2 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FO function
				FOleft := leftinp(31 DOWNTO 16); FOright := rightinp(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(1);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(1)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(1)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(1);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(1)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(1)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(1);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(1)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(1)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				-- FL function
				FLleft := FO(31 DOWNTO 16); FLright := FO(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(1);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(1);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				temp32 := leftinp;
				leftinp  := FL XOR rightinp;
				rightinp := temp32;
				regleft  <= leftinp;
				regright <= rightinp;
				nxt_state <= S3;
			WHEN S3 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FL function
				FLleft := leftinp(31 DOWNTO 16); FLright := leftinp(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(2);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(2);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				-- FO function
				FOleft := FL(31 DOWNTO 16); FOright := FL(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(2);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(2)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(2)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(2);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(2)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(2)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(2);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(2)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(2)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				temp32 := leftinp;
				leftinp  := FO XOR rightinp;
				rightinp := temp32;
				regleft  <= leftinp;
				regright <= rightinp;
				
				nxt_state <= S4;
			WHEN S4 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FO function
				FOleft := leftinp(31 DOWNTO 16); FOright := rightinp(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(3);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(3)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(3)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(3);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(3)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(3)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(3);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(3)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(3)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				-- FL function
				FLleft := FO(31 DOWNTO 16); FLright := FO(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(3);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(3);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				temp32 := leftinp;
				leftinp  := FL XOR rightinp;
				rightinp := temp32;
				regleft  <= leftinp;
				regright <= rightinp;
				
				nxt_state <= S5;
			WHEN S5 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FL function
				FLleft := leftinp(31 DOWNTO 16); FLright := leftinp(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(4);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(4);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				-- FO function
				FOleft := FL(31 DOWNTO 16); FOright := FL(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(4);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(4)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(4)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(4);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(4)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(4)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(4);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(4)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(4)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				temp32 := leftinp;
				leftinp  := FO XOR rightinp;
				rightinp := temp32;
				regleft  <= leftinp;
				regright <= rightinp;
				
				nxt_state <= S6;
			WHEN S6 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FO function
				FOleft := leftinp(31 DOWNTO 16); FOright := rightinp(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(5);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(5)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(5)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(5);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(5)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(5)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(5);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(5)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(5)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				-- FL function
				FLleft := FO(31 DOWNTO 16); FLright := FO(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(5);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(5);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				temp32 := leftinp;
				leftinp  := FL XOR rightinp;
				rightinp := temp32;
				regleft  <= leftinp;
				regright <= rightinp;
				nxt_state <= S7;
			WHEN S7 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FL function
				FLleft := leftinp(31 DOWNTO 16); FLright := leftinp(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(6);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(6);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				-- FO function
				FOleft := FL(31 DOWNTO 16); FOright := FL(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(6);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(6)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(6)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(6);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(6)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(6)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(6);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(6)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(6)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				temp32 := leftinp;
				leftinp  := FO XOR rightinp;
				rightinp := temp32;
				regleft  <= leftinp;
				regright <= rightinp;
				
				nxt_state <= S8;
			WHEN S8 =>
				leftinp  := regleft;
				rightinp := regright;
				-- FO function
				FOleft := leftinp(31 DOWNTO 16); FOright := rightinp(15 DOWNTO 0);
				temp15left := FOleft XOR KO1(7);
			--first part of FO -> FO1	
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI1(7)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI1(7)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--second part of FO -> FO2
				
				FOleft := FI XOR FOright;
				temp15left := FOright XOR KO2(7);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI2(7)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI2(7)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
			--third part of FO -> FO1
				
				FOright := FI XOR FOleft;
				temp15left := FOleft XOR KO3(7);
				--first part of FI functoin
				FIleft := temp15left(15 DOWNTO 7); FIright := temp15left(6 DOWNTO 0);
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);
				FIleftcopy := FIleft;
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIrightcopy := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				FIrightcopy := FIrightcopy XOR KI3(7)(15 DOWNTO 9);
				FIleftcopy:= FIleftcopy XOR KI3(7)(8 DOWNTO 0);
				
				--second part of FI function
				FIleft := FIleftcopy; FIright := FIrightcopy;
				s9boxrox := to_integer(unsigned(FIleft(8 DOWNTO 4))); s9boxcol := to_integer(unsigned(FIleft(3 DOWNTO 0)));
				FIleft := std_logic_vector(to_unsigned(S_boxes9(s9boxrox,s9boxcol), 9));
				FIleft := FIleft XOR ("00" & FIright);	
				s7boxrox := to_integer(unsigned(FIright(6 DOWNTO 4))); s7boxcol := to_integer(unsigned(FIright(3 DOWNTO 0)));
				FIright := std_logic_vector(to_unsigned(S_boxes7(s7boxrox,s7boxcol), 7)) XOR FIleft(6 DOWNTO 0);
				
				FI := FIright & FIleft;
				
				
				FO <= FOright & (FI XOR FOright);
				
				-- FL function
				FLleft := FO(31 DOWNTO 16); FLright := FO(15 DOWNTO 0);
				temp15left  := FLleft AND KL1(7);
				temp15leftcopy  := FLleft;
				temp15left  := temp15left rol 1;
				temp15right := FLright XOR temp15left;
				temp15rightcopy := temp15right;
				temp15right := temp15right OR KL2(7);
				temp15right := temp15right rol 1;
				temp15leftcopy  := temp15leftcopy XOR temp15right;
				FL <= temp15leftcopy & temp15rightcopy;
				
				temp32 := leftinp;
				leftinp  := FL XOR rightinp;
				rightinp := temp32;
				
				outp <= leftinp & rightinp;
			WHEN TEMP => NULL;
		END CASE;
	END PROCESS;
	
	PROCESS (clk, nrst)
	BEGIN
		IF (clk'EVENT AND clk = '1') THEN 
			IF (nrst = '0') THEN 
				cur_state <= initial_state;
			ELSE
				cur_state <= nxt_state;
			END IF;
		END IF;
	END PROCESS;
	
END myarch;
