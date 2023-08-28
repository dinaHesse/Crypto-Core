library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;


-- Package Declaration Section
package cryptocore_pckg is
 
	constant N_BITS : integer := 127;       -- Nicht aktuell, da masking der Dinge in aes_if stattfindet: if Protection order = 0 -> 127, =1 -> 255
	constant N	: integer := 1;		--Protection order

	constant SIZE_DRAM_SIM: integer := 128;	--size of registers for simulating the dram

	type data_reg_type is array (3 downto 0) of std_logic_vector(31 downto 0);
	type ciphertext_reg_type is array (3 downto 0) of std_logic_vector(31 downto 0);

	type key_reg_type is array (31 downto 0) of std_logic_vector(127 downto 0);

	type instr_type is (aes, check, hash, genkey, datamem, idle); --to be continued :)
	type key_cntrl_type is (idle, genkey, aes); -- gen_randomnumber, hash, ...

	type entropy_bit_input_type is array (15 downto 0) of std_logic_vector(5 downto 0);

	type dram_state_type is (store_entropy_idle, store1, store2, store3, idle_write, read1, read2, read3, read4, output_ready);
end package cryptocore_pckg;
 
-- Package Body Section, e.g for function implementation (function declaration in head)
package body cryptocore_pckg is
 

 
end package body cryptocore_pckg;
