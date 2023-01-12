library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.crypteng_pckg.all;

entity puf_connector is
 port (
    	clk   : in std_logic;
    	res_n   : in std_logic;

	read_in:		in std_logic;
	read_index:		in unsigned(31 downto 0);
	key_out:		out std_logic_vector(127 downto 0);

--	--DRAM-Connection:
--        dram_address_out: 	out std_logic_vector(31  downto 0);
--        dram_sel_out:		out std_logic;
--        dram_read_value_in: 	in std_logic_vector(31  downto 0);
--        dram_write_mask_out: 	out std_logic_vector(3  downto 0);
--        dram_write_value_out: 	out std_logic_vector(31  downto 0);
--        dram_ready_in:		in std_logic;

	--Random Numbers:
	rn_PUF_out:		out std_logic_vector(511 downto 0);

	--entropy-bits:
	active_flush_in:in std_logic;
	entropybits_in: in entropy_bit_input_type;
	entropy_bit_counter_in: in std_logic_vector(7 downto 0);
	flush_done:	out std_logic

    );

end puf_connector;


architecture behav of puf_connector is
	signal	entropy_bits:	std_logic_vector(95 downto 0);
	signal	dram_simulation:	std_logic_vector(SIZE_DRAM_SIM-1 downto 0);

	signal entropy_stored:	std_logic;
	signal counter: unsigned(31 downto 0);
	signal flush_done_intern: std_logic;

	signal state_now:	dram_state_type;
	signal next_state:	dram_state_type;


	--DRAM-Connection: Zu testzwecken hier als signale
        signal dram_address_out: 	std_logic_vector(31  downto 0);
        signal dram_sel_out:		std_logic;
        signal dram_read_value_in: 	std_logic_vector(31  downto 0);
        signal dram_write_mask_out: 	std_logic_vector(3  downto 0);
        signal dram_write_value_out: 	std_logic_vector(31  downto 0);
        signal dram_ready_in:		std_logic;

begin
	rn_PUF_out <= (others => '1');

	set_next_state: process (clk, res_n) is
	begin
		if(res_n = '0') then
			state_now <= store_entropy_idle;
		else
		  if(clk'event and clk = '1') then 
			state_now <= next_state;
		  end if; --clk
		end if; --res_n

	end process set_next_state;

	transition: process(state_now, read_in, flush_done_intern, dram_ready_in, entropy_stored, counter, dram_read_value_in, entropy_bits) is
		variable dram_address_reg: unsigned(31 downto 0) := x"00000000";
		variable key_reg: std_logic_vector(127 downto 0) := (others => '0');
	begin

		key_out <= (others => '0');
		dram_address_out <= (others => '0');	
		dram_sel_out <= '0';
		dram_write_mask_out <= (others => '0');
		dram_write_value_out <= (others => '0');			
		key_reg := (others => '0');  --zur latch-vermeidung

		case state_now is
			when store_entropy_idle =>
				if (flush_done_intern = '1') then
					dram_address_out <= std_logic_vector(dram_address_reg+0+counter);	
					dram_sel_out <= '1';
					dram_write_mask_out <= "1111";
					dram_write_value_out <= entropy_bits(31 downto 0);		
					
					next_state <= store1;
				else
					next_state <= store_entropy_idle;
				end if;
			when store1 =>
				if (dram_ready_in = '1') then
					dram_address_out <= std_logic_vector(dram_address_reg+1+counter);	
					dram_sel_out <= '1';
					dram_write_mask_out <= "1111";
					dram_write_value_out <= entropy_bits(63 downto 32);		
					
					next_state <= store2;					
				else
					next_state <= store1;
				end if;
			when store2 =>
				if (dram_ready_in = '1') then
					dram_address_out <= std_logic_vector(dram_address_reg+2+counter);	
					dram_sel_out <= '1';
					dram_write_mask_out <= "1111";
					dram_write_value_out <= entropy_bits(95 downto 64);		
					
					next_state <= store3;					
				else
					next_state <= store2;
				end if;
			when store3 =>
				if (dram_ready_in = '1') then
					if (entropy_stored = '1') then
						next_state <= idle_write;
					else
						next_state <= store_entropy_idle;					
					end if;
				else
					next_state <= store3;
				end if;
--ab hier jetzt write:
			when idle_write =>
				if (read_in = '1') then
					dram_address_out <= std_logic_vector(dram_address_reg+0);
					dram_sel_out <= '1';
					dram_write_mask_out <= (others => '0'); --> read
					dram_write_value_out <= (others => '0');	

					next_state <= read1;					
				else
					next_state <= idle_write;
				end if;
			when read1 =>
				if (dram_ready_in = '1') then
					key_reg(31 downto 0) := dram_read_value_in;

					dram_address_out <= std_logic_vector(dram_address_reg+1);
					dram_sel_out <= '1';
					dram_write_mask_out <= (others => '0'); --> read
					dram_write_value_out <= (others => '0');	

					next_state <= read2;					
				else
					next_state <= read1;
				end if;
			when read2 =>
				if (dram_ready_in = '1') then
					key_reg(63 downto 32) := dram_read_value_in;

					dram_address_out <= std_logic_vector(dram_address_reg+2);
					dram_sel_out <= '1';
					dram_write_mask_out <= (others => '0'); --> read
					dram_write_value_out <= (others => '0');	

					next_state <= read3;					
				else
					next_state <= read2;
				end if;
			when read3 =>
				if (dram_ready_in = '1') then
					key_reg(95 downto 64) := dram_read_value_in;

					dram_address_out <= std_logic_vector(dram_address_reg+3);
					dram_sel_out <= '1';
					dram_write_mask_out <= (others => '0'); --> read
					dram_write_value_out <= (others => '0');	

					next_state <= read4;					
				else
					next_state <= read3;
				end if;
			when read4 =>
				if (dram_ready_in = '1') then
					key_reg(127 downto 96) := dram_read_value_in;

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
--	cntrl_dram: process(clk, res_n) is
--		variable dram_address_reg: unsigned(31 downto 0) := x"00000000";
--		variable key_reg: std_logic_vector(127 downto 0);
--	begin
--		if(res_n = '0') then
--			dram_address_out <= (others => '0');
--			dram_sel_out <= '0';
--			dram_write_mask_out <= (others => '0');
--			dram_write_value_out <= (others => '0');
--		else
--		if (clk'event and clk = '1') then 
--			if (flush_done_intern = '1') then  --write entropy bits to dram
--				for k in 1 to 3 loop--entropybits_in'length loop
--					dram_address_out <= std_logic_vector(dram_address_reg+to_unsigned(k, 32)+counter);	--DAS WIRD SO NICHT FUNKTIONIEREN!!!
--					dram_sel_out <= '1';
--					dram_write_mask_out <= "1111";
--					dram_write_value_out <= entropy_bits((32*k)-1 downto 32*k-32);
--				end loop;
--			elsif (entropy_stored = '1' and read_in = '1') then	--read PUF numbers
--				key_out <= (others => '0');
--				for k in 1 to 4 loop--key'length loop								--DAS WIRD SO NICHT FUNKTIONIEREN!!!
--					dram_address_out <= std_logic_vector(dram_address_reg+to_unsigned(k, 32));
--					dram_sel_out <= '1';
--					dram_write_mask_out <= (others => '0'); --> read
--					dram_write_value_out <= (others => '0');	
--					key_reg((32*k)-1 downto 32*k-32) <= dram_read_value_in;
--				end loop;
--				key_out <= key_reg;
--			else
--				dram_address_out <= (others => '0');
--				dram_sel_out <= '0';
--				dram_write_mask_out <= (others => '0');
--				dram_write_value_out <= (others => '0');				
--			end if;
--			
--		end if;
--		end if;	
--	end process cntrl_dram;


	store_entropy_bits: process(clk, res_n) is
		
	begin
		if(res_n = '0') then
			entropy_bits <= (others => '0');
			flush_done <= '0';
			flush_done_intern <= '0';
			counter <= x"00000000";
			entropy_stored <= '0';
		else
		if (clk'event and clk = '1') then
			flush_done <= '0';
			flush_done_intern <= '0';
			if (active_flush_in = '1') then
				for k in 1 to entropybits_in'length loop
					entropy_bits( ((6*k)-1) downto ((6*k)-6) ) <= entropybits_in(k-1);	--richtige Reihenfolge? (95 - (6*k) downto 90-(6*k))
				end loop;
				counter <= counter + 1;
				flush_done <= '1';
				flush_done_intern <= '1';
				if (entropy_bit_counter_in(7) = '1') then --wenn höchstes Bit = 1 ist -> extraction fertig (this bit just has this function)
					entropy_stored <= '1';
				end if;
			end if;
		end if;
		end if;	
	end process store_entropy_bits;


--process for simulating some input from "DRAM-PUF" 
	simulate_DRAM_output: process(clk, res_n) is
		variable counter: unsigned(10 downto 0) := (others => '0');  -- addresses 0 to 4095
	begin
		if(res_n = '0') then 
			dram_read_value_in <= (others =>'0');
			dram_ready_in <= '0';
		else
		if (clk'event and clk = '1') then

			counter := (counter+32)mod SIZE_DRAM_SIM;

			dram_read_value_in <= dram_simulation(to_integer(counter)+31 downto to_integer(counter));
			if (counter mod 4 = 0) then
				dram_ready_in <='1';
			else
				dram_ready_in <='0';
			end if; --counter

			if (counter >= 4063) then
				counter := (others => '0');
			end if;
		end if; --clk
		end if; --res_n
	end process simulate_DRAM_output;

--process for simulating some input from "DRAM-PUF" 
	simulate_DRAM_input: process(clk, res_n) is
	begin
		if(res_n = '0') then 
			dram_simulation <= (others =>'0');
		else
		if (clk'event and clk = '1') then
			if (dram_sel_out = '1') then
				dram_simulation((to_integer(unsigned(dram_address_out))mod SIZE_DRAM_SIM)+31 downto (to_integer(unsigned(dram_address_out))mod SIZE_DRAM_SIM)) <= dram_write_value_out;
			else

			end if; --dram_sel_out

		end if; --clk
		end if; --res_n
	end process simulate_DRAM_input;


end behav;
