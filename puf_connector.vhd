library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.cryptocore_pckg.all;

entity puf_connector is
 port (
    	clk   : in std_logic;
    	res_n   : in std_logic;

		read_in:		in std_logic;
		read_index:		in unsigned(31 downto 0);
		key_out:		out std_logic_vector(127 downto 0);

--	--PUF-Connection:
--        PUF_address_out: 	out std_logic_vector(31  downto 0);
--        PUF_sel_out:		out std_logic;
--        PUF_read_value_in: 	in std_logic_vector(31  downto 0);
--        PUF_write_mask_out: 	out std_logic_vector(3  downto 0);
--        PUF_write_value_out: 	out std_logic_vector(31  downto 0);
--        PUF_ready_in:		in std_logic;

		--Random Numbers:
		rn_PUF_out:		out std_logic_vector(511 downto 0);

		--seed-bits:
		active_flush_in:in std_logic;
		seedbits_in: in seed_bit_input_type;
		seed_bit_counter_in: in std_logic_vector(7 downto 0);
		flush_done:	out std_logic

    );

end puf_connector;


architecture behav of puf_connector is
	signal	seed_bits:	std_logic_vector(95 downto 0);
	signal	PUF_simulation:	std_logic_vector(SIZE_PUF_SIM-1 downto 0);

	signal seed_stored:	std_logic;
	signal counter: unsigned(31 downto 0);
	signal flush_done_intern: std_logic;

	signal state_now:	PUF_state_type;
	signal next_state:	PUF_state_type;


	--PUF-Connection: Zu testzwecken hier als signale
        signal PUF_address_out: 	std_logic_vector(31  downto 0);
        signal PUF_sel_out:		std_logic;
        signal PUF_read_value_in: 	std_logic_vector(31  downto 0);
        signal PUF_write_mask_out: 	std_logic_vector(3  downto 0);
        signal PUF_write_value_out: 	std_logic_vector(31  downto 0);
        signal PUF_ready_in:		std_logic;

begin
	rn_PUF_out <= (others => '1');

	set_next_state: process (clk, res_n) is
	begin
		if(res_n = '0') then
			state_now <= store_seed_idle;
		else
		  if(clk'event and clk = '1') then 
			state_now <= next_state;
		  end if; --clk
		end if; --res_n

	end process set_next_state;

	transition: process(state_now, read_in, flush_done_intern, PUF_ready_in, seed_stored, counter, PUF_read_value_in, seed_bits) is
		variable PUF_address_reg: unsigned(31 downto 0) := x"00000000";
		variable key_reg: std_logic_vector(127 downto 0) := (others => '0');
	begin

		key_out <= (others => '0');
		PUF_address_out <= (others => '0');	
		PUF_sel_out <= '0';
		PUF_write_mask_out <= (others => '0');
		PUF_write_value_out <= (others => '0');			
		key_reg := (others => '0');  --zur latch-vermeidung

		case state_now is
			when store_seed_idle =>
				if (flush_done_intern = '1') then
					PUF_address_out <= std_logic_vector(PUF_address_reg+0+counter);	
					PUF_sel_out <= '1';
					PUF_write_mask_out <= "1111";
					PUF_write_value_out <= seed_bits(31 downto 0);		
					
					next_state <= store1;
				else
					next_state <= store_seed_idle;
				end if;
			when store1 =>
				if (PUF_ready_in = '1') then
					PUF_address_out <= std_logic_vector(PUF_address_reg+1+counter);	
					PUF_sel_out <= '1';
					PUF_write_mask_out <= "1111";
					PUF_write_value_out <= seed_bits(63 downto 32);		
					
					next_state <= store2;					
				else
					next_state <= store1;
				end if;
			when store2 =>
				if (PUF_ready_in = '1') then
					PUF_address_out <= std_logic_vector(PUF_address_reg+2+counter);	
					PUF_sel_out <= '1';
					PUF_write_mask_out <= "1111";
					PUF_write_value_out <= seed_bits(95 downto 64);		
					
					next_state <= store3;					
				else
					next_state <= store2;
				end if;
			when store3 =>
				if (PUF_ready_in = '1') then
					if (seed_stored = '1') then
						next_state <= idle_write;
					else
						next_state <= store_seed_idle;					
					end if;
				else
					next_state <= store3;
				end if;
--ab hier jetzt write:
			when idle_write =>
				if (read_in = '1') then
					PUF_address_out <= std_logic_vector(PUF_address_reg+0);
					PUF_sel_out <= '1';
					PUF_write_mask_out <= (others => '0'); --> read
					PUF_write_value_out <= (others => '0');	

					next_state <= read1;					
				else
					next_state <= idle_write;
				end if;
			when read1 =>
				if (PUF_ready_in = '1') then
					key_reg(31 downto 0) := PUF_read_value_in;

					PUF_address_out <= std_logic_vector(PUF_address_reg+1);
					PUF_sel_out <= '1';
					PUF_write_mask_out <= (others => '0'); --> read
					PUF_write_value_out <= (others => '0');	

					next_state <= read2;					
				else
					next_state <= read1;
				end if;
			when read2 =>
				if (PUF_ready_in = '1') then
					key_reg(63 downto 32) := PUF_read_value_in;

					PUF_address_out <= std_logic_vector(PUF_address_reg+2);
					PUF_sel_out <= '1';
					PUF_write_mask_out <= (others => '0'); --> read
					PUF_write_value_out <= (others => '0');	

					next_state <= read3;					
				else
					next_state <= read2;
				end if;
			when read3 =>
				if (PUF_ready_in = '1') then
					key_reg(95 downto 64) := PUF_read_value_in;

					PUF_address_out <= std_logic_vector(PUF_address_reg+3);
					PUF_sel_out <= '1';
					PUF_write_mask_out <= (others => '0'); --> read
					PUF_write_value_out <= (others => '0');	

					next_state <= read4;					
				else
					next_state <= read3;
				end if;
			when read4 =>
				if (PUF_ready_in = '1') then
					key_reg(127 downto 96) := PUF_read_value_in;

					next_state <= output_ready;					
				else
					next_state <= read4;
				end if;
			when output_ready =>
				key_out <= key_reg;
				next_state <= idle_write;
			
			when others =>
				next_state <= state_now;
			end case;

	end process transition;



--not necessary and not working:
--	cntrl_PUF: process(clk, res_n) is
--		variable PUF_address_reg: unsigned(31 downto 0) := x"00000000";
--		variable key_reg: std_logic_vector(127 downto 0);
--	begin
--		if(res_n = '0') then
--			PUF_address_out <= (others => '0');
--			PUF_sel_out <= '0';
--			PUF_write_mask_out <= (others => '0');
--			PUF_write_value_out <= (others => '0');
--		else
--		if (clk'event and clk = '1') then 
--			if (flush_done_intern = '1') then  --write seed bits to PUF
--				for k in 1 to 3 loop--seedbits_in'length loop
--					PUF_address_out <= std_logic_vector(PUF_address_reg+to_unsigned(k, 32)+counter);	--DAS WIRD SO NICHT FUNKTIONIEREN!!!
--					PUF_sel_out <= '1';
--					PUF_write_mask_out <= "1111";
--					PUF_write_value_out <= seed_bits((32*k)-1 downto 32*k-32);
--				end loop;
--			elsif (seed_stored = '1' and read_in = '1') then	--read PUF numbers
--				key_out <= (others => '0');
--				for k in 1 to 4 loop--key'length loop								--DAS WIRD SO NICHT FUNKTIONIEREN!!!
--					PUF_address_out <= std_logic_vector(PUF_address_reg+to_unsigned(k, 32));
--					PUF_sel_out <= '1';
--					PUF_write_mask_out <= (others => '0'); --> read
--					PUF_write_value_out <= (others => '0');	
--					key_reg((32*k)-1 downto 32*k-32) <= PUF_read_value_in;
--				end loop;
--				key_out <= key_reg;
--			else
--				PUF_address_out <= (others => '0');
--				PUF_sel_out <= '0';
--				PUF_write_mask_out <= (others => '0');
--				PUF_write_value_out <= (others => '0');				
--			end if;
--			
--		end if;
--		end if;	
--	end process cntrl_PUF;


	store_seed_bits: process(clk, res_n) is
		
	begin
		if(res_n = '0') then
			seed_bits <= (others => '0');
			flush_done <= '0';
			flush_done_intern <= '0';
			counter <= x"00000000";
			seed_stored <= '0';
		else
		if (clk'event and clk = '1') then
			flush_done <= '0';
			flush_done_intern <= '0';
			if (active_flush_in = '1') then
				for k in 1 to seedbits_in'length loop
					seed_bits( ((6*k)-1) downto ((6*k)-6) ) <= seedbits_in(k-1);	--richtige Reihenfolge? (95 - (6*k) downto 90-(6*k))
				end loop;
				counter <= counter + 1;
				flush_done <= '1';
				flush_done_intern <= '1';
				if (seed_bit_counter_in(7) = '1') then --wenn höchstes Bit = 1 ist -> extraction fertig (this bit just has this function)
					seed_stored <= '1';
				end if;
			end if;
		end if;
		end if;	
	end process store_seed_bits;


--process for simulating some input from "PUF-PUF" 
	simulate_PUF_output: process(clk, res_n) is
		variable counter: unsigned(10 downto 0) := (others => '0');  -- addresses 0 to 4095
	begin
		if(res_n = '0') then 
			PUF_read_value_in <= (others =>'0');
			PUF_ready_in <= '0';
		else
		if (clk'event and clk = '1') then

			counter := (counter+32)mod SIZE_PUF_SIM;

			PUF_read_value_in <= PUF_simulation(to_integer(counter)+31 downto to_integer(counter));
			if (counter mod 4 = 0) then
				PUF_ready_in <='1';
			else
				PUF_ready_in <='0';
			end if; --counter

			if (counter >= 4063) then
				counter := (others => '0');
			end if;
		end if; --clk
		end if; --res_n
	end process simulate_PUF_output;

--process for simulating some input from "PUF" 
	simulate_PUF_input: process(clk, res_n) is
	begin
		if(res_n = '0') then 
			PUF_simulation <= (others =>'0');
		else
		if (clk'event and clk = '1') then
			if (PUF_sel_out = '1') then
				PUF_simulation((to_integer(unsigned(PUF_address_out))mod SIZE_PUF_SIM)+31 downto (to_integer(unsigned(PUF_address_out))mod SIZE_PUF_SIM)) <= PUF_write_value_out;
			else

			end if; --PUF_sel_out

		end if; --clk
		end if; --res_n
	end process simulate_PUF_input;


end behav;
