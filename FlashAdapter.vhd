library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity FlashAdapter is
	port(
		--ʱ��
		clk : in std_logic;
		rst : in std_logic;
		
		MemWrite : in std_logic;						--����дDM���źţ�='1'������Ҫд
		
		dataIn : in std_logic_vector(15 downto 0);		--д�ڴ�ʱ��Ҫд��DM��IM������
		
		ram1_addr : out std_logic_vector(17 downto 0); 	--RAM1��ַ����
		ram1_data : inout std_logic_vector(15 downto 0);--RAM1��������
		
		ram1_en : out std_logic;		--RAM1ʹ�ܣ�='1'��ֹ����Զ����'1'
		ram1_oe : out std_logic;		--RAM1��ʹ�ܣ�='1'��ֹ����Զ����'1'
		ram1_we : out std_logic;		--RAM1дʹ�ܣ�='1'��ֹ����Զ����'1'
		
		MemoryState : out std_logic_vector(1 downto 0);
		FlashStateOut : out std_logic_vector(2 downto 0);
		
		flashFinished : out std_logic := '0';
		
		--Flash
		flash_addr : out std_logic_vector(22 downto 0);		--flash��ַ��
		flash_data : inout std_logic_vector(15 downto 0);	--flash������
		
		flash_byte : out std_logic := '1';	--flash����ģʽ������'1'
		flash_vpen : out std_logic := '1';	--flashд����������'1'
		flash_rp : out std_logic := '1';		--'1'��ʾflash����������'1'
		flash_ce : out std_logic := '0';		--flashʹ��
		flash_oe : out std_logic := '1';		--flash��ʹ�ܣ�'0'��Ч��ÿ�ζ���������'1'
		flash_we : out std_logic := '1'		--flashдʹ��
	);
end FlashAdapter;

architecture Behavioral of MemoryUnit is

	signal flash_finished : std_logic := '0';
	--type FLASH_STATE is (STATE1, STATE2, STATE3, STATE4, STATE5, STATE6);
	--signal flashstate : FLASH_STATE := STATE1;	--��flash����ָ�ram2��״̬
	signal flashstate : std_logic_vector(2 downto 0) := "001";
	signal current_addr : std_logic_vector(15 downto 0) := (others => '0');	--flash��ǰҪ���ĵ�ַ
	
begin
	
	process(clk, rst)
	begin
	
		if (rst = '0') then
			ram2_we <= '1';
			
			ram1_addr <= (others => '0');
			
			dataOut <= (others => '0');
			insOut <= (others => '0');
			
			state <= "00";			--rst֮�ա���
			flashstate <= "001";
			--flash_finished <= '0';
			current_addr <= (others => '0');
			
		elsif (clk'event and clk = '1') then 
			if (flash_finished = '1') then			--��flash����kernelָ�ram2�����
				flash_byte <= '1';
				flash_vpen <= '1';
				flash_rp <= '1';
				flash_ce <= '1';	--��ֹflash
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
						
					when "00" =>		--׼����ָ��
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
						
					when "01" =>		--����ָ�׼����/д ����/�ڴ�
						ram2_oe <= '1';
						insOut <= ram2_data;
						if (MemWrite = '1') then	--���Ҫд
							rflag <= '0';
							if (ramAddr = x"BF00") then 	--׼��д����
								ram1_data(7 downto 0) <= dataIn(7 downto 0);
								wrn <= '0';
							else							--׼��д�ڴ�
								ram2_addr(15 downto 0) <= ramAddr;
								ram2_data <= dataIn;
								ram2_we <= '0';
							end if;
						elsif (MemRead = '1') then	--���Ҫ��
							if (ramAddr = x"BF01") then 	--׼��������״̬
								dataOut(15 downto 2) <= (others => '0');
								dataOut(1) <= data_ready;
								dataOut(0) <= tsre and tbre;
								if (rflag = '0') then	--������״̬ʱ��ζ�Ž���������Ҫ��/д��������
									ram1_data <= (others => 'Z');	--��Ԥ�Ȱ�ram1_data��Ϊ����
									rflag <= '1';	--���������Ҫ�������ֱ�Ӱ�rdn��'0'��ʡһ��״̬��Ҫд����rflag='0'��������д���ڵ�����
								end if;	
							elsif (ramAddr = x"BF00") then	--׼������������
								rflag <= '0';
								rdn <= '0';
							else							--׼�����ڴ�
								ram2_data <= (others => 'Z');
								ram2_addr(15 downto 0) <= ramAddr;
								ram2_oe <= '0';
							end if;
						end if;	
						state <= "10";
						
					when "10" =>		--��/д ����/�ڴ�
						if(MemWrite = '1') then		--д
							if (ramAddr = x"BF00") then		--д����
								wrn <= '1';
							else							--д�ڴ�
								ram2_we <= '1';
							end if;
						elsif(MemRead = '1') then	--��
							if (ramAddr = x"BF01") then		--������״̬���Ѷ�����
								null;
							elsif (ramAddr = x"BF00") then 	--����������
								rdn <= '1';
								dataOut(15 downto 8) <= (others => '0');
								dataOut(7 downto 0) <= ram1_data(7 downto 0);
							else							--���ڴ�
								ram2_oe <= '1';
								dataOut <= ram2_data;
							end if;
						end if;
						state <= "00";
						
					when others =>
						state <= "00";
						
				end case;
				
			else				--��flash����kernelָ�ram2��δ��ɣ����������
				if (cnt = 1000) then
					cnt := 0;
					
					case flashstate is
						
						
						when "001" =>		--WE��0
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
							ram2AddrOutput <= "00" & current_addr;	--����
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