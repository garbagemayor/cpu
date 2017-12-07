library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity FlashAdapter is
	port(
		--时钟
		clk : in std_logic;
		rst : in std_logic;
		
		MemWrite : in std_logic;						--控制写DM的信号，='1'代表需要写
		
		dataIn : in std_logic_vector(15 downto 0);		--写内存时，要写入DM或IM的数据
		
		ram1_addr : out std_logic_vector(17 downto 0); 	--RAM1地址总线
		ram1_data : inout std_logic_vector(15 downto 0);--RAM1数据总线
		
		ram1_en : out std_logic;		--RAM1使能，='1'禁止，永远等于'1'
		ram1_oe : out std_logic;		--RAM1读使能，='1'禁止，永远等于'1'
		ram1_we : out std_logic;		--RAM1写使能，='1'禁止，永远等于'1'
		
		MemoryState : out std_logic_vector(1 downto 0);
		FlashStateOut : out std_logic_vector(2 downto 0);
		
		flashFinished : out std_logic := '0';
		
		--Flash
		flash_addr : out std_logic_vector(22 downto 0);		--flash地址线
		flash_data : inout std_logic_vector(15 downto 0);	--flash数据线
		
		flash_byte : out std_logic := '1';	--flash操作模式，常置'1'
		flash_vpen : out std_logic := '1';	--flash写保护，常置'1'
		flash_rp : out std_logic := '1';		--'1'表示flash工作，常置'1'
		flash_ce : out std_logic := '0';		--flash使能
		flash_oe : out std_logic := '1';		--flash读使能，'0'有效，每次读操作后置'1'
		flash_we : out std_logic := '1'		--flash写使能
	);
end FlashAdapter;

architecture Behavioral of MemoryUnit is

	signal flash_finished : std_logic := '0';
	--type FLASH_STATE is (STATE1, STATE2, STATE3, STATE4, STATE5, STATE6);
	--signal flashstate : FLASH_STATE := STATE1;	--从flash载入指令到ram2的状态
	signal flashstate : std_logic_vector(2 downto 0) := "001";
	signal current_addr : std_logic_vector(15 downto 0) := (others => '0');	--flash当前要读的地址
	
begin
	
	process(clk, rst)
	begin
	
		if (rst = '0') then
			ram2_we <= '1';
			
			ram1_addr <= (others => '0');
			
			dataOut <= (others => '0');
			insOut <= (others => '0');
			
			state <= "00";			--rst之谜……
			flashstate <= "001";
			--flash_finished <= '0';
			current_addr <= (others => '0');
			
		elsif (clk'event and clk = '1') then 
			if (flash_finished = '1') then			--从flash载入kernel指令到ram2已完成
				flash_byte <= '1';
				flash_vpen <= '1';
				flash_rp <= '1';
				flash_ce <= '1';	--禁止flash
				ram1_en <= '1';
				ram1_oe <= '1';
				ram1_we <= '1';
				ram1_addr(17 downto 0) <= (others => '0');
				ram2_en <= '0';
				ram2_addr(17 downto 16) <= "00";
				ram2_oe <= '1';
				ram2_we <= '1';
				wrn <= '1';
				rdn <= '1';
				
				case state is 
					--when "00" =>
					--	state <= "01";
						
					when "00" =>		--准备读指令
						if PCKeep = '0' then
							ram2_addr(15 downto 0) <= PCMuxOut;
						elsif PCKeep = '1' then
							ram2_addr(15 downto 0) <= PCOut;
						end if;
						ram2_data <= (others => 'Z');
						--ram2_addr(15 downto 0) <= PC;
						wrn <= '1';
						rdn <= '1';
						ram2_oe <= '0';
						state <= "01";
						
					when "01" =>		--读出指令，准备读/写 串口/内存
						ram2_oe <= '1';
						insOut <= ram2_data;
						if (MemWrite = '1') then	--如果要写
							rflag <= '0';
							if (ramAddr = x"BF00") then 	--准备写串口
								ram1_data(7 downto 0) <= dataIn(7 downto 0);
								wrn <= '0';
							else							--准备写内存
								ram2_addr(15 downto 0) <= ramAddr;
								ram2_data <= dataIn;
								ram2_we <= '0';
							end if;
						elsif (MemRead = '1') then	--如果要读
							if (ramAddr = x"BF01") then 	--准备读串口状态
								dataOut(15 downto 2) <= (others => '0');
								dataOut(1) <= data_ready;
								dataOut(0) <= tsre and tbre;
								if (rflag = '0') then	--读串口状态时意味着接下来可能要读/写串口数据
									ram1_data <= (others => 'Z');	--故预先把ram1_data置为高阻
									rflag <= '1';	--如果接下来要读，则可直接把rdn置'0'，省一个状态；要写，则rflag='0'，正常走写串口的流程
								end if;	
							elsif (ramAddr = x"BF00") then	--准备读串口数据
								rflag <= '0';
								rdn <= '0';
							else							--准备读内存
								ram2_data <= (others => 'Z');
								ram2_addr(15 downto 0) <= ramAddr;
								ram2_oe <= '0';
							end if;
						end if;	
						state <= "10";
						
					when "10" =>		--读/写 串口/内存
						if(MemWrite = '1') then		--写
							if (ramAddr = x"BF00") then		--写串口
								wrn <= '1';
							else							--写内存
								ram2_we <= '1';
							end if;
						elsif(MemRead = '1') then	--读
							if (ramAddr = x"BF01") then		--读串口状态（已读出）
								null;
							elsif (ramAddr = x"BF00") then 	--读串口数据
								rdn <= '1';
								dataOut(15 downto 8) <= (others => '0');
								dataOut(7 downto 0) <= ram1_data(7 downto 0);
							else							--读内存
								ram2_oe <= '1';
								dataOut <= ram2_data;
							end if;
						end if;
						state <= "00";
						
					when others =>
						state <= "00";
						
				end case;
				
			else				--从flash载入kernel指令到ram2尚未完成，则继续载入
				if (cnt = 1000) then
					cnt := 0;
					
					case flashstate is
						
						
						when "001" =>		--WE置0
							ram2_en <= '0';
							ram2_we <= '0';
							ram2_oe <= '1';
							wrn <= '1';
							rdn <= '1';
							flash_we <= '0';
							flash_oe <= '1';
							
							flash_byte <= '1';
							flash_vpen <= '1';
							flash_rp <= '1';
							flash_ce <= '0';
							
							flashstate <= "010";
							
						when "010" =>
							flash_data <= x"00FF";
							flashstate <= "011";
							
						when "011" =>
							flash_we <= '1';
							flashstate <= "100";
							
						when "100" =>
							flash_addr <= "000000" & current_addr & '0';
							flash_data <= (others => 'Z');
							flash_oe <= '0';
							flashstate <= "101";
							
						when "101" =>
							flash_oe <= '1';
							ram2_we <= '0';
							ram2_addr <= "00" & current_addr;
							ram2AddrOutput <= "00" & current_addr;	--调试
							ram2_data <= flash_data;
							flashstate <= "110";
						
						when "110" =>
							ram2_we <= '1';
							current_addr <= current_addr + '1';
							flashstate <= "001";
						
							
						when others =>
							flashstate <= "001";
						
					end case;
					
					if (current_addr > x"0249") then
						flash_finished <= '1';
					end if;
				else 
					if (cnt < 1000) then
						cnt := cnt + 1;
					end if;
				end if;	--cnt 
				
			end if;	--flash finished or not
			
		end if;	--rst/clk_raise
		
	end process;
	
	
	MemoryState <= state;
	flashFinished <= flash_finished;
	FlashStateOut <= flashstate;
	
	
end Behavioral;