library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.masked_aes_pkg.all;

library work;
	use work.keccak_globals.all;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_misc.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_textio.all;
	use ieee.std_logic_unsigned."+"; 

entity RNG_genInput is
 port (
    	clk:	 	in std_logic;
    	res_n:	 	in std_logic;
		
	-- Inputs:
	--von ausserhalb:
	refresh:	in std_logic;

	puf_rn:		in std_logic_vector(511 downto 0);

    	-- Outputs:
	rn_out:	out std_logic_vector(1023 downto 0);
	
	is_new:		out std_logic
	--to debug:
	--test: 		out std_logic;
	--logic_key: 		in std_logic_vector(127 downto 0) 

    );

end RNG_genInput;


architecture behav of RNG_genInput is

--component keccak
--  port (
--    clk     : in  std_logic;
--    rst_n   : in  std_logic;
--    start : in std_logic;
--    din     : in  std_logic_vector(63 downto 0);
--    din_valid: in std_logic;
--    buffer_full: out std_logic;
--    last_block: in std_logic;    
--    ready : out std_logic;
--    dout    : out std_logic_vector(63 downto 0);
--    dout_valid : out std_logic);
--end component;

--  	signal dout,din: std_logic_vector(N-1 downto 0); 
-- 	signal start,din_val,buffer_full,last_block,ready,dout_valid : std_logic;
--
-- 	type st_type is (INIT,read_first_input,st0,st1,END_HASH1,END_HASH2,STOP);
-- 	signal st : st_type;

-- components
component  keccak_copro
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;   
    start : in std_logic;
    addr: out addr_type;
    enR: out std_logic;
    enW: out std_logic;    
    data_from_mem: in std_logic_vector(63 downto 0);
    data_to_mem: out std_logic_vector(63 downto 0);
    done: out std_logic
    

);
end component;



	signal previous_rn:	std_logic_vector(511 downto 0);
	signal full_input:	std_logic_vector(1023 downto 0);

	signal start,enR,enW,done : std_logic;
	signal mem_output, mem_input : std_logic_vector( 63 downto 0);
	signal addr: addr_type;


subtype mem_element_type is std_logic_vector(63 downto 0);
type mem_table_type is array (63 downto 0) of mem_element_type;

--signal ram : mem_table_type;

begin

-- port map

coprocessor_map : keccak_copro port map(clk,res_n,start,addr,enR,enW,mem_output,mem_input,done);


full_input(511 downto 0) <= previous_rn;
full_input(1023 downto 512) <= puf_rn;


	cntrl_keccak: process(clk,res_n)
		variable rn_reg: std_logic_vector(4095 downto 0);
		variable input_counter: integer;
		variable output_counter: integer;
		variable generating: std_logic;
	begin
		if(res_n='0') then
			previous_rn <= (others => '0');
			rn_reg := (others => '0');
			input_counter := 0;
			output_counter := 0;
			mem_output <= (others => '0');
			generating := '0';
			rn_out <= (others => '0');
			start <= '0';
			is_new <= '0';
		else
			if(clk'event and clk = '1') then
				is_new <= '0';
				start <= '0';
				if(refresh = '1' and generating = '0') then
					input_counter := 0;
					generating := '1';
					start <= '1';
					rn_reg(1023 downto 0) := full_input;
				end if;

				if(generating = '1' and done = '1') then
					generating := '0';
					rn_out <= rn_reg(1023 downto 0);
					previous_rn <= rn_reg(1599 downto 1088);	
					is_new <= '1';				
				end if;

				if(generating = '1') then
					if (enR='1') then
						mem_output <= rn_reg((64*addr)+63 downto (64*addr));
						input_counter := input_counter +1;
					else
						
						mem_output <= (others=>'0');

					end if;
					if(enW='1') then
						rn_reg((64*addr)+63 downto (64*addr)) := mem_input;
					else

					end if;
				else
					mem_output <= (others=>'0');
				end if;

			end if;
		end if;
	end process cntrl_keccak;


--port map
--keccak_map : keccak port map(clk,res_n,start,din,din_val,buffer_full,last_block,ready,dout,dout_valid);
--
--p_main: process (clk,res_n)
--variable counter,count_hash,num_test: integer;
--variable temp: std_logic_vector(N-1 downto 0);	
--begin
--	if res_n = '0' then                 -- asynchronous rst_n (active low)
--		st <= INIT;
--		counter:=0;
--		din<=(others=>'0');
--		din_val <='0';
--		last_block<='0';
--		count_hash:=0;
--	
--	elsif clk'event and clk = '1' then  -- rising clk edge
--		case st is
--			when INIT =>
----				readline(filein,line_in);
----				read(line_in,num_test);
--				st<=read_first_input;
--				start<='1';
--				din_val<='0';
--				
--						
--					
--			
--			when read_first_input =>
--				start<='0';
--					
----				readline(filein,line_in);
----				if(line_in(1)='.') then
----					FILE_CLOSE(filein);
----					FILE_CLOSE(fileout);
----					assert false report "Simulation completed" severity failure;
----					st <= STOP;
----				else
----					if(line_in(1)='-') then						
----						st<= END_HASH1;
----						
----					else
--						din_val<='1';
--						counter:=0;	
----						hread(line_in,temp);
--						temp := full_input((counter*64)+63 downto (counter*64));
--						din<=temp;	
--						
--						st<=st0;
--											
----					end if;
--								
----				end if;
--			
--			when st0 =>
--
--				if(counter<16) then
--					if(counter<15) then
----						readline(filein,line_in);
----						hread(line_in,temp);
--						temp := full_input((counter*64)+63 downto (counter*64));
--						din<= temp;
--					end if;
--					counter:=counter+1;
--					st<=st0;
--					din_val<='1';
--				else
--					st <= st1;
--					din_val<='0';
--				end if;
--			when st1 =>
--				if(buffer_full='1') then
--				
--					st <= st1;
--				else
--					st <= END_HASH1;
--					--st <= read_first_input;
--								--din_val<='1';	--was already outcommented in testbench
--				end if;
--			when END_HASH1 =>
--				if(ready='0') then
--					st<=END_HASH1;
--				else
--					last_block<='1';
--					st<=END_HASH2;
--					counter:=0;
--				end if;
--			when END_HASH2 =>
--				last_block<='0';
--				if(dout_valid='1') then
--
--					temp:=dout;
----					hwrite(line_out,temp);
----					writeline(fileout,line_out);
--					if(counter<3) then
--						counter:=counter+1;
--					else
--						st <= STOP;
----						st<=read_first_input;
----						start<='1';
----						write(line_out, string'("-"));
----						writeline(fileout,line_out);
--					end if;
--				end if;
--			when STOP =>
--				if (refresh <= '1') then
--					st<=read_first_input;						st<=read_first_input;
--					start<='1';
--				end if;
--			end case;
--
--	end if;
--end process;

--	collect_output: process(clk,res_n) is
--		variable counter: integer;
--		variable rn_reg: std_logic_vector(10599 downto 0);
--	begin
--		is_new <= '0';
--		if(res_n = '0') then
--			is_new <= '0';
--			rn_out <= (others => '0');
--			counter := 0;
--			rn_reg := (others => '0');
--			previous_rn <= (others => '0');
--		else
--			if (clk'event and clk = '1') then
--				if (dout_valid = '1') then
--					rn_reg((counter*64)+63 downto (counter*64)) := dout;
--					counter := counter +1;
--				else
--					if (counter > 0) then
--						rn_out <= rn_reg(1023 downto 0);
--						previous_rn <= rn_reg(1599 downto 1088);
--						is_new <= '1';
--					end if;
--					counter := 0;
--				end if;
--			end if;
--		end if;
--		
--		
--	end process collect_output;	





--	start_input: process(clk,res_n) is
--		--variable counter: std_logic;
--		--variable test_reg: std_logic;
--	begin
--		if(res_n = '0') then
--			do_input <= '0';
--		else
--			if (clk'event and clk = '1') then
--				if refresh = '1' then
--					do_input <= '1';
--				else
--					d
--				end if;
--			end if;
--		end if;
--		
--		
--	end process gen_input;	



end behav;
