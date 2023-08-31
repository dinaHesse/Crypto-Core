---------------------------------------------------------------------------------
-- Company: 
-- Engineer: 

-- Design Name: 
-- Module Name:    aes_if
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.masked_aes_pkg.all;

library work;
use work.cryptocore_pckg.all;


entity aes_if is
 port (
    	clk   : in std_logic;
    	res_n   : in std_logic;
		
	-- Inputs:
	
	--from AES-module:
		-- Cyphertext C
		ciphertext : 	in  t_shared_gf8(N downto 0);
		done : 			in std_logic; -- ciphertext is ready
	
	-- from host
		key_in : 		in std_logic_vector(0 to N_BITS);
		plaintext_in: 		in std_logic_vector(0 to N_BITS);
		random_in:		in std_logic_vector(367  downto 0);
		pt_ready:		in std_logic;
		key_ready:		in std_logic;
	
	
    -- Outputs:
	--to AES-module:
    	-- Plaintext shares
    	plaintext : 	out t_shared_gf8(N downto 0);
    	-- Key shares
    	key : 			out t_shared_gf8(N downto 0);
    	-- Randomnes for remasking
    	randomness: 	out std_logic_vector (111  downto 0);
    	-- Control signals
    	start_out : 	out  std_logic; -- Start the core
	reset_out : 	out std_logic;

	--to host:
	cipher_out: 	out std_logic_vector(0 to N_BITS);
	busy: 			out std_logic
			
	
		--to debug:
		--test: 		out std_logic;
		--logic_key: 	in std_logic_vector(127 downto 0) 

    );

end aes_if;


architecture behav of aes_if is

	signal cipher_kommt: 	std_logic;
	signal was_start: 	std_logic;
	--signal key_reg :	std_logic_vector(0 to N_BITS);
	--signal	pt_reg :	std_logic_vector(0 to N_BITS);
	signal	random_reg :	std_logic_vector(111 downto 0);
	signal get_cipher_intern: 	std_logic;
	signal	start_intern: std_logic;
	signal	cipher_ready: std_logic;
	signal start_in:	std_logic;
begin

	start_in <= key_ready AND pt_ready;

	randomness <= random_in(111 downto 0);

	gen_input: process(clk,res_n) is
		variable key_reg: std_logic_vector(0 to (N_BITS*2)+1); --:= x"2b7e151628aed2a6abf7158809cf4f3c00000000000000000000000000000000"; -- <- Testvectors
		variable pt_reg: std_logic_vector (0 to N_BITS*2+1); --:= x"3243f6a8885a308d313198a2e037073400000000000000000000000000000000";
		variable random_reg: std_logic_vector (111 downto 0) := (others => '0');
		variable counter: integer range 0 to 15:= 0;
		variable was_done: std_logic;

	begin
			
		if (res_n = '0') then
			key(0) <= (others=> '0');
			key(1) <= (others=> '0');
			plaintext(0) <= (others=> '0');
			plaintext(1) <= (others=> '0');
			start_out <= '0';
			was_start <= '0';
			was_done := '0';

		else
			if clk'event and clk = '1' then
				start_out <= '0';
	
				
				if start_in = '1' and was_start = '0' then
					key_reg(0 to 127) := key_in xor random_in(239 downto 112);
					pt_reg(0 to 127) := plaintext_in xor random_in(367 downto 240);
					key_reg(128 to 255) := random_in(239 downto 112);
					pt_reg(128 to 255) := random_in(367 downto 240);
					start_out <= '1';
					was_start <= '1';
					was_done := '0';
					counter := 0;
				end if;							
				
				if was_start = '1'  then
						key(0) <= key_reg ((8*(counter mod 16)) to 7+(8*(counter mod 16)));
						key(1) <= key_reg (128+(8*(counter mod 16)) to 135+(8*(counter mod 16)));
						plaintext(0) <= pt_reg ((8*(counter mod 16)) to 7+(8*(counter mod 16)));
						plaintext(1) <= pt_reg (128+(8*(counter mod 16)) to 135+(8*(counter mod 16)));	
						
						if counter = 15 then
							counter := 0;
						else
							counter := counter + 1;
						end if;
					
					if done = '1' then
						if was_done = '0' then
							was_done := '1';
						else	
							was_done := '0';
							was_start <= '0';
							
						end if;
					end if;
				end if;

			
				
			end if;
		end if;
		cipher_kommt <= was_done;
	end process gen_input;
	
	
	
	get_result: process(clk,res_n) is
		variable cipher_reg: std_logic_vector(0 to (N_BITS*2)+1):= (others => '0');
		variable counter: integer range 0 to 16:= 16;
		
	begin
		if(res_n = '0') then
			cipher_reg 	:= (others => '0');
			busy <= '0';
			reset_out <= '0';
		else
		if clk'event and clk = '1' then
			reset_out <= '1';
			if start_in = '1' then
				busy <= '1';
			else
				if cipher_kommt = '1' and done = '1' then  --gerade ready geworden
						counter := 0;
						cipher_reg := (others => '0');
						busy <= '1';						
				end if;
				if counter < 16 then
						cipher_reg((8*counter) to 7+(8*counter)) := ciphertext(0);
						cipher_reg(128+(8*counter) to 135+(8*counter)) := ciphertext(1);
						counter := counter + 1;
						if counter = 16 then
							busy <= '0';	
							reset_out <= '0';	
							cipher_reg(0 to 127) := cipher_reg(0 to 127) xor cipher_reg(128 to 255);						
						end if;
				end if; 
			end if;
		end if;
		end if;
		cipher_out <= cipher_reg(0 to 127);
	end process get_result;		
	
	
--	test_process: process(clk,res_n) is
--		variable counter: std_logic;
--		variable test_reg: std_logic;
--	begin
--		if(res_n = '0') then
--			test_reg := '0';
--			counter := '0';
--		else
--			if (clk'event and clk = '1') then
--				if key_reg = "" then
--					counter := '1';
--					test_reg := '0';
--				else
--					counter := '0';
--					test_reg := '1';
--				end if;
--			end if;
--		end if;
--		
--		test <= test_reg;
--	end process test_process;	


end behav;


