library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.cryptocore_pckg.all;

entity tb is
end tb;

architecture tb_struct of tb is 
	
	signal clk_tb : std_logic := '0';
	signal res_n_tb: std_logic := '0';

    --further signals for top module's input and output
	--memory bus signals:
	signal address_tb: 	std_logic_vector(31 downto 0) := (others => '0');
	signal sel_tb:		std_logic := '0';
	signal read_tb: 	std_logic := '0';
	signal write_tb: 	std_logic := '0';
	signal write_mask_tb: 	std_logic_vector(3 downto 0) := (others => '0');
	signal write_value_tb: 	std_logic_vector(31 downto 0) := (others => '0');
	signal read_value_tb: 	std_logic_vector(31 downto 0) := (others => '0');
	signal ready_tb: 	std_logic := '0';

	-- seed input signals:
	signal seed_flush_tb: 	std_logic := '0';
	signal seed_input_tb:	seed_bit_input_type := (others => (others => '0'));
	signal seed_counter_tb:	std_logic_vector(7 downto 0)  := (others => '0');
	signal seed_done_tb : std_logic;

	--PUF signals:


	--TRNG signals:



begin

	write_tb <= NOT read_tb;

	--Instantiation of cryptocore_top module:
	cc_top: entity work.cryptocore_top
	port map(
		clk => clk_tb,
		res_n => res_n_tb,
		address_extern_in => address_tb,
		sel_extern_in => sel_tb,
		read_extern_in => read_tb,
		write_extern_in => write_tb,
		write_mask_extern_in => write_mask_tb,
		write_value_extern_in => write_value_tb,

		seed_active_flush_in => seed_flush_tb,
		seed_seedbits_in => seed_input_tb,
		seed_bit_counter_in => seed_counter_tb,
		seed_flush_done => seed_done_tb,

		read_value_extern_out => read_value_tb,
		ready_extern_out => ready_tb
	);

	--Clock generation process:
	clk_process: process 
	begin
		wait for 20 ns;
		res_n_tb <= '1';
		while now < 100000 ns loop --simulate for 1000ns
			clk_tb <= not clk_tb;
			wait for 5 ns; 
		end loop;
		wait;
	end process;

	-- Input generation process:
	input_process: process

		variable data_input: std_logic_vector(127 downto 0) := x"3243f6a8885a308d313198a2e0370734";

	begin
		wait for 20 ns; --initial delay

-- FLUSH SEED BITS:
		seed_flush_tb <= '1';
		seed_input_tb <= (others => (others => '1'));
		seed_counter_tb <= b"10000000";

		wait for 20 ns;

		--end flushing of seed bits:
		seed_flush_tb <='0';

		wait for 10 ns;

		--values for input signals:
--		address_tb(7 downto 2) <= (others => '0');
--		sel_tb <= '0';
--		read_tb <= '0';
--		write_mask_tb <= (others => '0');
--		write_value_tb <= (others => '0');

		--start key generation for key at index 0 
		address_tb(7 downto 2) <= "001000";
		sel_tb <= '1';
		read_tb <= '0';
		write_mask_tb <= (others => '1');
		write_value_tb <= (others => '0');  

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '0';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 20 ns;

		--store data in data registers 
		--1st 32 bits:
		address_tb(7 downto 2) <= "100000";
		sel_tb <= '1';
		read_tb <= '0';
		write_mask_tb <= (others => '1');
		write_value_tb <= data_input(31 downto 0);

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '0';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--2nd 32 bits:
		address_tb(7 downto 2) <= "100001";
		sel_tb <= '1';
		read_tb <= '0';
		write_mask_tb <= (others => '1');
		write_value_tb <= data_input(63 downto 32); 

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '0';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--3rd 32 bits:
		address_tb(7 downto 2) <= "100010";
		sel_tb <= '1';
		read_tb <= '0';
		write_mask_tb <= (others => '1');
		write_value_tb <= data_input(95 downto 64);

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '0';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--4th 32 bits:
		address_tb(7 downto 2) <= "100011";
		sel_tb <= '1';
		read_tb <= '0';
		write_mask_tb <= (others => '1');
		write_value_tb <= data_input(127 downto 96);

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '0';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--start AES encryption
		address_tb(7 downto 2) <= "000001";
		sel_tb <= '1';
		read_tb <= '0';
		write_mask_tb <= (others => '1');
		write_value_tb <= (others => '0');  --ToDo: Check Data (make it clearer that bit 31-16: data register index, bit 15-0: key register index)

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '0';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--check busy (until ready)
		address_tb(7 downto 2) <= "000100";
		sel_tb <= '1';
		read_tb <= '1';

--			wait for 20 ns; 
--			address_tb(7 downto 2) <= (others => '0');
--			sel_tb <= '0';
--			read_tb <= '0';
--			write_mask_tb <= (others => '0');
--			write_value_tb <= (others => '0');

		wait for 20 ns;

		while read_value_tb /= 0 loop

			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '1';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');
	
			wait for 20 ns; 	

			--check busy (until ready)
			address_tb(7 downto 2) <= "000100";
			sel_tb <= '1';
			read_tb <= '1';
	
			wait for 20 ns;
		end loop;


		--load ciphertext
		--load 1st byte:
		address_tb(7 downto 2) <= "000000";
		sel_tb <= '1';
		read_tb <= '1';

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '1';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--load 2nd byte:
		address_tb(7 downto 2) <= "000001";
		sel_tb <= '1';
		read_tb <= '1';

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '1';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--load 3rd byte:
		address_tb(7 downto 2) <= "000010";
		sel_tb <= '1';
		read_tb <= '1';

			wait for 20 ns; 
			address_tb(7 downto 2) <= (others => '0');
			sel_tb <= '0';
			read_tb <= '1';
			write_mask_tb <= (others => '0');
			write_value_tb <= (others => '0');

		wait for 40 ns;

		--load 4th byte:
		address_tb(7 downto 2) <= "000011";
		sel_tb <= '1';
		read_tb <= '1';

		wait for 40 ns;
		--add further test cases and input changes as needed

		wait;
	end process;


end tb_struct;
