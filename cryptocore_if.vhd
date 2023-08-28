---------------------------------------------------------------------------------
-- Company: 
-- Engineer: 	Dina Hesse
-- 
-- Module Name:    cryptocore_if
-- Project Name: 	Crypto-Core
-- Target Devices: 
-- Tool versions: v1.0
-- Description: 
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.cryptocore_pckg.all;

entity cryptocore_if is
 port (
    clk   : in std_logic;
    res_n   : in std_logic;
	
--extern:
	-- Inputs:
	address_in:	in std_logic_vector(31  downto 0);
	sel_in:		in std_logic;
	read_in: 	in std_logic;
	write_in: 	in std_logic;
	write_mask_in:	in std_logic_vector(3 downto 0);
	write_value_in:	in std_logic_vector(31 downto 0);
	
    --- Outputs:
	read_value_out: out std_logic_vector(31 downto 0);
	ready_out: out	std_logic;
	
--aes:
	plaintext_aes:	out std_logic_vector(0 to N_BITS);	
	start_aes: 	out std_logic;
	cipher_aes: 	in std_logic_vector(0 to N_BITS);
	busy_aes: 	in std_logic;

--key-controll:
	key_address_out:out std_logic_vector(3 downto 0);
	key_sel:	out std_logic;
	key_cntrl:	out key_cntrl_type
	--to debug:
	--test: out std_logic
    );

end cryptocore_if;


architecture behav of cryptocore_if is
	
	constant mem_adress : std_logic_vector(31 downto 0) := x"8000_0040"; 	--"10000000_00000000_00000000_01000000";
	constant datareg_adress : std_logic_vector(5 downto 0) := b"10_0000"; -- start of data registers

	signal	data_reg :	data_reg_type;
	signal	ciphertext_reg: ciphertext_reg_type;

	signal	instr: 		instr_type;

begin

	address_decoder: process(address_in) is
		variable address_reg: unsigned(31 downto 0) := (others => '0');
		variable address_short: unsigned (5 downto 0) := (others => '0');
	begin
		address_reg := unsigned(address_in(31 downto 0)); --0 to 63, we only need to address full blocks of 32 bits -> we can ignore the last two bits
		address_short := address_reg(7 downto 2);
		-- -> 4 addresses xx00, xx01, xx10, xx11 lead to the same instruction/data_register
		instr <= idle;
		if (address_reg >= x"03FFFF") then
		case to_integer(address_short) is
			when 0 to 3 => instr <= aes;			--aes instruction

			when 4	    => instr <= check;			--check if aes is busy (-> fffffff) or ready (->0000000) or error (->something)

			when 5 to 7 => instr <= hash;			--hash instruction

			when 8 to 11 => instr <= genkey;		--generate key instruction

			when 32 to 63 => instr <= datamem;		--data registers store or load	
       		
   			when others => instr <= idle;
       		
		end case;
		else
			instr <= idle;
		end if;
	end process address_decoder;


	data_register: process(clk,res_n) is
		variable address_reg: unsigned(4 downto 0) := (others => '0');
		variable write_value_reg: std_logic_vector(31 downto 0);
	begin
		write_value_reg := (others => '0');
		if(res_n = '0') then
			data_reg <= (others => (others => '0'));
			--data_reg(4) <= (others => '1'); --zu Testzwecken
			address_reg := (others => '0');
		else
		if (clk'event and clk = '1') then
			address_reg := unsigned(address_in(6 downto 2)); --0 bis 31
			if (sel_in = '1' and instr = datamem) then 
				if (write_in = '1') then
					case write_mask_in is
						when "1111" => write_value_reg := write_value_in;
						when "1100" => write_value_reg(15 downto 0) := write_value_in(31 downto 16);
						when "0011" => write_value_reg(15 downto 0) := write_value_in(15 downto 0);
						when "1000" => write_value_reg(7 downto 0) := write_value_in(31 downto 24);
						when "0100" => write_value_reg(7 downto 0) := write_value_in(23 downto 16);
						when "0010" => write_value_reg(7 downto 0) := write_value_in(15 downto 8);
						when "0001" => write_value_reg(7 downto 0) := write_value_in(7 downto 0);
						when others => report "no valid write_mask" severity warning;
					end case;
					data_reg(to_integer(address_reg)) <= write_value_reg; 
				end if; -- write
			end if; -- sel_in
		end if; --clk
		end if; --res_n
	end process data_register;



	output_read: process(clk, res_n) is
		variable address_reg: unsigned(5 downto 0) := (others => '0');
		variable output_reg: std_logic_vector(31 downto 0);
	begin
		if res_n = '0' then
			output_reg := (others => '0');
			address_reg := (others => '0');
		else
		if (clk'event and clk = '1') then
			address_reg := unsigned(address_in(7 downto 2)); --0 bis 63
			if (sel_in = '1' and read_in = '1') then
				case instr is
				when aes => output_reg := ciphertext_reg(to_integer(address_reg(1 downto 0)));	--variabler input
	
				when check => 	if (busy_aes = '1') then --if aes running
							output_reg := (others => '1');
						elsif (busy_aes = '0') then
							output_reg := (others => '0');
						end if; --busy

				when hash => output_reg := (others => '0');
	
				when genkey => output_reg := (others => '0');
	
				when datamem => --calculate data-reg-index = address-32
						output_reg := data_reg(to_integer(address_reg(4 downto 0)));
	
	   			when others => 	output_reg := (others => '0');
						
				end case;
			else
				output_reg := (others => '0');
			
			end if; --sel_in			
		end if;
		end if;
		read_value_out <= output_reg;

	end process output_read;


	manage_ready_out: process(res_n, clk) is 
		variable ready_reg: std_logic;
	begin

		if(res_n = '0') then
			ready_reg := '0';
			ready_out <= ready_reg;
		else
			if (clk'event and clk = '1') then
				if (ready_reg = '1') then	
					ready_reg := '0';
				else
					if (sel_in = '1') then
						ready_reg := '1';
					else
						ready_reg := '0';
					end if;
				end if; --ready_reg
				ready_out <= ready_reg;
			end if;
		end if;	
	end process manage_ready_out;	




--process which sends control-signals, input-data (plaintext ) to aes_if
--receives and stores ciphertext (?)
	cntrl_aes: process(clk,res_n) is

		variable address_reg: unsigned(15 downto 0) := (others => '0');
		
	begin
		if(res_n = '0') then
			plaintext_aes	<= (others => '0');
			start_aes 	<= '0';
			address_reg 	:= (others => '0'); 
		else
		if (clk'event and clk = '1') then
			if (instr = aes AND sel_in = '1' AND write_in = '1') then
				address_reg 	:= unsigned(write_value_in(31 downto 16)); 
				--start aes-encryption
				plaintext_aes <= data_reg(2*to_integer(address_reg(4 downto 1))) & data_reg(2*to_integer(address_reg(4 downto 1))+1) & data_reg(2*to_integer(address_reg(4 downto 1))+2) & data_reg(2*to_integer(address_reg(4 downto 1))+3); --x"3243f6a8885a308d313198a2e037073400000000000000000000000000000000"; --(others => '1'); --data-reg und so 
				start_aes <= '1';


			else
				--fetch ciphertext-result when aes is not running, otherwise set to FFF..FF
				--Could become a problem if cipher_aes is not constant while aes is not running. -> dann Variable einführen
				if (busy_aes = '0') then 
					ciphertext_reg(0) <= cipher_aes(0 to 31);
					ciphertext_reg(1) <= cipher_aes(32 to 63);
					ciphertext_reg(2) <= cipher_aes(64 to 95);
					ciphertext_reg(3) <= cipher_aes(96 to 127);				
				else
					ciphertext_reg <= (others => (others => '1'));
					plaintext_aes <= (others => '0'); 
					start_aes <= '0';
				end if;

			end if; -- instr
		end if;--clk
		end if;--res_n
		
	end process cntrl_aes;	


--process which sends controll-signals to key-manager: 
--key address
--which functionality? -> aes, hash,...
	cntrl_key: process(clk,res_n) is
		variable address_reg: std_logic_vector(15 downto 0) := (others => '0');
	begin
		
		if(res_n = '0') then
			key_sel <= '0';
			key_address_out <= (others => '0');
			key_cntrl <= idle;
			address_reg 	:= (others => '0'); 
		else
		if (clk'event and clk = '1') then
			key_sel <='0';
			key_address_out <= (others => '0');
			key_cntrl <= idle;
			address_reg 	:= write_value_in(15 downto 0); 

			if( sel_in = '1') then
				case instr is
				when aes => if (write_in = '1') then 	--start aes-encryption
						key_sel <= '1';
						key_cntrl <= aes;
						key_address_out <= address_reg(3 downto 0);
					    end if;
	
				when genkey => 	key_sel <= '1';		--generate key - if key with specific index already exists -> do nothing
						key_address_out <= address_reg(3 downto 0);
						key_cntrl <= genkey;
		
	   			when others => 	key_cntrl <= idle;
						
				end case;
			else

			end if;--sel_in
		end if;
		end if;
		
	end process cntrl_key;	


--	test_process: process(clk,res_n) is
--
--	begin
--		if(res_n = '0') then
--
--		else
--			if (clk'event and clk = '1') then
--
--			end if;
--		end if;
--		
--		--test <= test_reg;
--	end process test_process;	


end behav;



