library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;


-- Package Declaration Section
package cryptocore_pckg is
	constant N	: integer := 1;		--if Protection order = 0 -> 127, =1 -> 255

--only necessary if simulating the PUF:
--	constant SIZE_PUF_SIM: integer := 128;	--size of registers for simulating the PUF

	type data_reg_type is array (3 downto 0) of std_logic_vector(31 downto 0);
	type ciphertext_reg_type is array (3 downto 0) of std_logic_vector(31 downto 0);

	type key_reg_type is array (31 downto 0) of std_logic_vector(127 downto 0);

	type instr_type is (aes, check, hash, genkey, datamem, idle); --to be continued :)
	type key_cntrl_type is (idle, genkey, aes); -- gen_randomnumber, hash, ...

	type seed_bit_input_type is array (15 downto 0) of std_logic_vector(5 downto 0);

	type PUF_state_type is (store_seed_idle, store1, store2, store3, idle_write, read1, read2, read3, read4, output_ready);
end package cryptocore_pckg;
 
-- Package Body Section, e.g for function implementation (function declaration in head)
package body cryptocore_pckg is
 

 
end package body cryptocore_pckg;
