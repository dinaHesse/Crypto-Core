library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.cryptocore_pckg.all;

entity key_manager is
 port (
    	clk   : in std_logic;
    	res_n   : in std_logic;
	
	-- Inputs:
		--from interface:
		key_address_in:		in std_logic_vector(3  downto 0); --16 keys 
		sel_in:			in std_logic;
		cntrl_in: 		in key_cntrl_type;
		puf_in:			in std_logic_vector(127 downto 0);
		--from rng:
		rn_in:			in std_logic_vector(1023 downto 0);
		rn_is_new:		in std_logic;

	-- Outputs:
		--to interface
		ready_out: 		out	std_logic;
		--to puf_connector
		read_puf_index:		out	unsigned(31 downto 0);
		read_puf: 		out	std_logic;
		--to rng:
		refresh_rn_out:		out	std_logic;

		--to aes:
		aes_key_out: 		out std_logic_vector(0 to N_BITS);
		aes_key_ready:		out std_logic;
		random_aes:		out std_logic_vector(367  downto 0)

    );

end key_manager;


architecture behav of key_manager is

	signal	key_reg :	key_reg_type;
	signal	generating_key_index:	integer range key_reg_type'length-1 downto 0;
	signal	is_generating: 	std_logic;
	signal 	seed_stored:	std_logic;

begin

	cntrl_key: process(clk, res_n) is
		variable	randomness:	std_logic_vector(367 downto 0):= (others=> '0');
	begin

		if(res_n = '0') then
			random_aes	<= (others => '0');
			ready_out <= '0';
			refresh_rn_out <= '0';
			aes_key_out <= (others=>'0');
			aes_key_ready <= '0';	
		else
		if (clk'event and clk = '1') then
			refresh_rn_out <= '0';
			random_aes	<= rn_in(367 downto 0);

			if (sel_in = '1') then
				refresh_rn_out <= '1';
				case cntrl_in is
				when aes => 	aes_key_out <= key_reg(to_integer(unsigned(key_address_in))); 
						aes_key_ready <= '1';
						ready_out <= '1';
	
				when genkey => 	--key_reg(to_integer(unsigned(key_address_in))) <= x"2b7e151628aed2a6abf7158809cf4f3c"; --(others => '0');--
						ready_out <= '0';
		
	   			when others => 	aes_key_out <= (others=>'0');
						ready_out <= '0';
						
				end case;

			else
				aes_key_out <= (others=>'0');
				ready_out <= '0';				
			end if;
		end if;
		end if;	

	end process cntrl_key;

-- 	store_seed_bits: process(clk, res_n) is
--
--		variable counter: integer := 0;
-- 	begin
-- 		if(res_n = '0') then
--			seed_bits <= (others => '0');
-- 			seed_flush_done <= '0';
--			counter := 0;
--			seed_stored <= '0';
-- 		else
-- 		if (clk'event and clk = '1') then
-- 			seed_flush_done <= '0';
-- 			if (seed_active_flush_in = '1') then
-- 				for k in 1 to seed_seedbits_in'length loop
--					seed_bits( ((6*k)-1+counter) downto ((6*k)-6+counter) ) <= seed_seedbits_in(k-1);	--richtige Reihenfolge? (95 - (6*k) downto 90-(6*k))
-- 				end loop;
--				counter := counter + to_integer(unsigned(seed_bit_counter_in));
-- 				seed_flush_done <= '1';
--				if (seed_bit_counter_in(7) = '1') then --wenn höchstes Bit = 1 ist -> extraction fertig (this bit just has this function)
--					seed_stored <= '1';
--				end if;
-- 			end if;
-- 		end if;
-- 		end if;	
--	end process store_seed_bits;

	gen_key: process(clk, res_n) is

	begin
		if(res_n = '0') then
			generating_key_index <= 0;
			is_generating <= '0';
			key_reg <= (others => (others => '0'));
			read_puf_index <= (others => '0');
			read_puf  <= '0';
		else
		if (clk'event and clk = '1') then
			read_puf <= '0';
			if (is_generating = '1') then
				if (puf_in /= x"00000000000000000000000000000000") then
					key_reg(generating_key_index) <= x"2b7e151628aed2a6abf7158809cf4f3c";--puf_in;
					is_generating <='0';
					generating_key_index <= 0;
					read_puf_index <= (others => '0');
				end if;
			elsif (sel_in = '1' and cntrl_in = genkey) then
				is_generating <='1';
				generating_key_index <= to_integer(unsigned(key_address_in));
				read_puf_index <= (others => '0');
				read_puf_index(3 downto 0) <= unsigned(key_address_in); 
				read_puf <= '1';
			else
			
 			end if;
		end if;
		end if;	
	end process gen_key;

end behav;



