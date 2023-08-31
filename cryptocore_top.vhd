----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dina Hesse
-- 
-- Design Name: 
-- Module Name:    cryptocore_top - struct 

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.masked_aes_pkg.all;
use IEEE.numeric_std.all;

library work;
use work.cryptocore_pckg.all;
use work.masked_aes_pkg.all;

entity cryptocore_top is
 port (
    	clk   : in std_logic;
    	res_n   : in std_logic;
	
	--EXTERN:
	-- Inputs:
		address_extern_in:		in std_logic_vector(31  downto 0);
		sel_extern_in:			in std_logic;
		read_extern_in: 		in std_logic;
		write_extern_in: 		in std_logic;
		write_mask_extern_in:	in std_logic_vector(3 downto 0);
		write_value_extern_in:	in std_logic_vector(31 downto 0);

		seed_active_flush_in: in std_logic;
		seed_seedbits_in: in seed_bit_input_type;
		seed_bit_counter_in:	in std_logic_vector(7 downto 0);
		seed_flush_done:		out std_logic;	
	
    -- Outputs:
		read_value_extern_out: 	out std_logic_vector(31 downto 0);
		ready_extern_out: 		out	std_logic
	
    );
end cryptocore_top;

architecture struct of cryptocore_top is

	-- cryptocore_if to aes_if:
	signal plaintext_crypt_aes:	std_logic_vector(0 to N_BITS);
	signal start_crypt_aes:		std_logic;
	signal busy_aes_crypt:		std_logic;
	signal ciphertext_aes_crypt: 	std_logic_vector(0 to N_BITS);

	-- aes-signals:
	signal ciphertext_aes:		t_shared_gf8(N downto 0);
	signal plaintext_aes:		t_shared_gf8(N downto 0);
	signal key_aes:			t_shared_gf8(N downto 0);
	signal random_mngr_aes:		std_logic_vector(367 downto 0);
	signal random_aes:		std_logic_vector(111 downto 0);
	signal start_aes: 		std_logic; 
	signal reset_aes: 		std_logic; 
	signal done_aes: 		std_logic; -- ciphertext is ready

	--key signals:
	signal key_sel:			std_logic;
	signal key_ready:		std_logic;
	signal key_ready_mngr_aes:	std_logic;
	signal key_mngr_aes:		std_logic_vector(0 to N_BITS);
	signal key_address:		std_logic_vector(3 downto 0);
	signal key_cntrl:		key_cntrl_type;
	
	--puf signals:
	signal read_puf:		std_logic;
	signal read_puf_index:		unsigned(31 downto 0);
	signal puf_output:		std_logic_vector(127 downto 0);

	--PUF-Connection:
	signal PUF_address_out: 	 std_logic_vector(31  downto 0);
	signal PUF_sel_out:		 std_logic;
	signal PUF_read_value_in: 	 std_logic_vector(31  downto 0);
	signal PUF_write_mask_out: 	 std_logic_vector(3  downto 0);
	signal PUF_write_value_out: 	 std_logic_vector(31  downto 0);
	signal PUF_ready_in:		 std_logic;

	--RNG:
	signal rn_PUF:			std_logic_vector(511 downto 0);
	signal rn_RNG_key:		std_logic_vector(1023 downto 0);
	signal refresh_RNG:		std_logic;
	signal rn_is_new:		std_logic;

begin

	cryptocore_if: entity work.cryptocore_if
	port map(
		clk => clk,
		res_n => res_n,
--extern:
		--Input from extern
		address_in => address_extern_in,
		sel_in => sel_extern_in,
		read_in => read_extern_in,
		write_in => write_extern_in,
		write_mask_in => write_mask_extern_in,
		write_value_in => write_value_extern_in,

		--Output to extern:
		read_value_out => read_value_extern_out,
		ready_out => ready_extern_out,
--aes:
		--Output to aes_if:
		plaintext_aes => plaintext_crypt_aes,
		start_aes => start_crypt_aes,
		--Input from aes_if
		cipher_aes => ciphertext_aes_crypt,
		busy_aes => busy_aes_crypt,

		key_address_out => key_address,
		key_sel => key_sel,
		key_cntrl => key_cntrl
		
	);	


	aes_if: entity work.aes_if
	port map(
	    	clk   => clk,
	    	res_n  => res_n,
			
		-- Inputs:
		
		--from AES-module:
		-- Cyphertext C
	    	ciphertext => ciphertext_aes,
			done => done_aes,
		
		-- from host
			key_in => key_mngr_aes,
			plaintext_in => plaintext_crypt_aes,
			random_in => random_mngr_aes,
			pt_ready => start_crypt_aes,

			key_ready => key_ready_mngr_aes,
		
		
	    -- Outputs:
		--to AES:
	    	-- Plaintext shares
	    	plaintext => plaintext_aes,
	    	-- Key shares
	    	key => key_aes,
	    	-- Randomnes for remasking
	    	randomness => random_aes,
	    	-- Control signals
	    	start_out => start_aes,
			reset_out => reset_aes,
	
		--to Host:
		cipher_out => ciphertext_aes_crypt,
		busy => busy_aes_crypt
	);

		
	dom_aes: entity work.aes_top
	port map(
		ClkxCI => clk,
	    	RstxBI => reset_aes,
		--- Inputs:
	    	-- Plaintext shares
	    	PTxDI => plaintext_aes,
	    	-- Key shares
	    	KxDI => key_aes,

	    	-- Randomnes for remasking
	    	Zmul1xDI(0) => random_aes(3 downto 0),  -- for y1 * y0
	    	Zmul2xDI(0) => random_aes(7 downto 4),  -- for O * y1
	    	Zmul3xDI(0) => random_aes(11 downto 8),  -- for O * y0
	    	Zinv1xDI(0) => random_aes(13 downto 12),  -- for inverter
	    	Zinv2xDI(0) => random_aes(15 downto 14),  -- ...
	    	Zinv3xDI(0) => random_aes(17 downto 16),  -- ...
	    	-- Blinding values for Y0*Y1 and Inverter
	    	Bmul1xDI(0) => random_aes(21 downto 18),             -- for y1 * y0
	    	Bmul1xDI(1) => random_aes(21 downto 18),             -- for y1 * y0
			Binv1xDI(0) => random_aes(27 downto 26),              -- for inverter
			Binv1xDI(1) => random_aes(27 downto 26),              -- for inverter
	    	Binv2xDI(0) => random_aes(31 downto 30),            -- ...
	    	Binv2xDI(1) => random_aes(31 downto 30),            -- ...
	    	Binv3xDI(0) => random_aes(35 downto 34),             -- ...
	    	Binv3xDI(1) => random_aes(35 downto 34),             -- ...	    	-- Control signals

	    	StartxSI => start_aes, -- Start the core
	    	-- Output:
	    	DonexSO  => done_aes, -- ciphertext is ready
	    	-- Cyphertext C
	    	CxDO    => ciphertext_aes
	);
	

	key_manager: entity work.key_manager
	port map(
		clk => clk,
		res_n => res_n,

		key_address_in => key_address,
		sel_in => key_sel,
		cntrl_in => key_cntrl,

		puf_in => puf_output,

		rn_in  => rn_RNG_key,
		rn_is_new => rn_is_new,

		read_puf_index => read_puf_index,
		read_puf => read_puf,

		refresh_rn_out => refresh_RNG,

		aes_key_out => key_mngr_aes,
		aes_key_ready => key_ready_mngr_aes,
		random_aes => random_mngr_aes	


	);

	puf_connector: entity work.puf_connector
	port map(
		clk => clk,
		res_n => res_n,

		read_in => read_puf,
		read_index => read_puf_index,
		key_out => puf_output,
 
--	--PUF-Connection:		--only necessary if no PUF connected
--        	PUF_address_out => PUF_address_out,
--        	PUF_sel_out => PUF_sel_out,
--        	PUF_read_value_in => PUF_read_value_in,
--        	PUF_write_mask_out => PUF_write_mask_out,
--        	PUF_write_value_out => PUF_write_value_out,
--        	PUF_ready_in => PUF_ready_in,

	--Random Numbers
		rn_PUF_out => rn_PUF,
	--seed-Bits
		active_flush_in => seed_active_flush_in,
		seedbits_in => seed_seedbits_in,
		seed_bit_counter_in => seed_bit_counter_in,
		flush_done => seed_flush_done
 	);


	RNG_genInput: entity work.RNG_genInput
	port map(
		clk => clk,
		res_n => res_n,		

		refresh => refresh_RNG,
		puf_rn	=> rn_PUF,

		rn_out => rn_RNG_key,
		is_new => rn_is_new
	);

end struct;

