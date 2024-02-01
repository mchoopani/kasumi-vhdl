LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;
ENTITY kasumi_tb IS
END kasumi_tb;

ARCHITECTURE test OF kasumi_tb IS
	COMPONENT kasumi IS 
		PORT (
		  clk, rst : IN  STD_LOGIC;
		  inp      	: IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
		  key       : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
		  outp		: OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
			);
	END COMPONENT;
	SIGNAL clk_tb  : STD_LOGIC := '1';
	SIGNAL rst_tb : STD_LOGIC;
	SIGNAL inp_tb  : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL key_tb  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL outp_tb : STD_LOGIC_VECTOR(63 DOWNTO 0);
BEGIN
	cut: kasumi PORT MAP (clk_tb, rst_tb, inp_tb, key_tb, outp_tb);
	clk_tb  <= NOT clk_tb AFTER 5 ns;
	rst_tb <= '0', '1' AFTER 11 ns;
	inp_tb  <= x"9f8115571e526dad";
	key_tb  <= x"4f1271c53d8e98504f1271c53d8e9850";
END test;