library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tyt_cpu2 is
	port (
		clk_50m	: in std_logic;
		clk_single : in std_logic;
		rst		: in std_logic;
		led		: out std_logic_vector(15 downto 0) := "0000000000000000";
		
		data_ram1 : inout  STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
		addr_ram1 : out  STD_LOGIC_VECTOR (17 downto 0) := "000000000000000000";
		OE_ram1 : out  STD_LOGIC := '1';
		WE_ram1 : out  STD_LOGIC := '1';
		EN_ram1 : out  STD_LOGIC := '0';
		data_ram2 : inout  STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
		addr_ram2 : out  STD_LOGIC_VECTOR (17 downto 0) := "000000000000000000";
		OE_ram2 : out  STD_LOGIC := '1';
		WE_ram2 : out  STD_LOGIC := '1';
		EN_ram2 : out  STD_LOGIC := '0';
		rdn: out STD_LOGIC := '1';
		wrn: out STD_LOGIC := '1';
		data_ready	: in std_logic;
		tbre		: in std_logic;
		tsre		: in std_logic;
		
		digit1	:	out  STD_LOGIC_VECTOR (6 downto 0) := "1111111";
		digit2	:	out  STD_LOGIC_VECTOR (6 downto 0) := "1111111"
	);
end tyt_cpu2;


architecture behavioral of tyt_cpu2 is

	subtype array16	is std_logic_vector(15 downto 0);
	subtype int5	is integer range 0 to 31;
	
	constant zero : array16 := "0000000000000000";
	
	constant  treg : array16 := "1000000000000001";
	constant spreg : array16 := "1000000000000010";
	constant ihreg : array16 := "1000000000000011";
	
	
	signal clk		:	std_logic := '1';
	
	signal state   : int5 := 0;	
	signal pc_next	: array16 := zero;
	
	signal JR_pc	: array16 := zero;
	signal JR_jump	: std_logic := '0';
	signal JR_nop	: std_logic := '0';
	
	signal B_pc	: array16 := zero;
	signal B_jump	: std_logic := '0';
	signal B_nop	: std_logic := '0';
	
	signal LW_pc	: array16 := zero;
	signal LW_jump	: std_logic := '0';		
	signal LW_nop	: std_logic := '0';
	signal access_ram2	: std_logic := '0';
	signal SW_ram2_data	: array16 := zero;
	signal SW_ram2_addr	: array16 := zero;
	signal SW_ram2_op	: int5 := 0;
	
	
	signal data_conf_A		: std_logic := '0';
	signal LW_conf_A		: std_logic := '0';
	signal a_reg	: array16 := zero;
	
	signal data_conf_B		: std_logic := '0';
	signal LW_conf_B		: std_logic := '0';
	signal b_reg	: array16 := zero;
	
	--	IF
	shared variable if_state	: int5 := 0;
	shared variable if_ins	: array16 := zero;
	shared variable if_data	: array16 := zero;
	shared variable if_pc	: array16 := zero;
	shared variable if_op	: int5 := 0;
	shared variable if_nop	: int5 := 0;
	
	--	IF/ID
	signal ifid_ins		: array16 := zero;
	signal ifid_op			: int5 := 0;
	signal ifid_pc			: array16 := zero;
	signal if_wb_data	: array16 := zero;
	
	--	ID
	shared variable id_state	: int5 := 0;
	shared variable id_ins	: array16 := zero;
	shared variable id_op	: int5 := 0;
	shared variable id_nop	: int5 := 0;
	shared variable id_pc	: array16 := zero;
	shared variable rx		: array16 := zero;
	shared variable ry		: array16 := zero;
	shared variable rz		: array16 := zero;
	shared variable imm		: array16 := zero;
	shared variable wb		: std_logic := '0';
	
	--	ID/EX
	signal idex_imm			: array16 := zero;
	signal idex_wb		: std_logic := '0';
	signal idex_op	: int5 := 0;
	signal idex_pc			: array16 := zero;
	signal idex_rz			: array16 := zero;
	
	--	EX
	shared variable ex_state	: int5 := 0;
	shared variable A	: array16 := zero;
	shared variable B	: array16 := zero;
	shared variable res	: array16 := zero;
	shared variable addr	: array16 := "1000000000000000";
	shared variable ex_imm	: array16 := zero;
	shared variable ex_lw : std_logic := '0';
	shared variable ex_wb : std_logic := '0';
	shared variable ex_br : std_logic := '0'; -- is branch or not
	shared variable ex_op	: int5 := 0;
	shared variable ex_nop	: int5 := 0;
	shared variable ex_pc	: array16 := zero;
	shared variable ex_rd	: array16 := zero;
	
	--	EX/ME
	signal exme_wb			: std_logic := '0';
	signal exme_pc			: array16 := zero;
	signal exme_op			: int5 := 0;
	signal exme_rz			: array16 := zero;
	signal exme_res		: array16 := zero; -- the data to write
	signal exme_addr		: array16 := "1000000000000000"; -- the data address
	
	--	ME
	shared variable me_state	: int5 := 0;
	shared variable data			: array16 := zero;
	shared variable me_wb 		: std_logic := '0';
	shared variable me_op		: int5 := 0;
	shared variable me_pc		: array16 := zero;
	shared variable me_rz		: array16 := zero;
	shared variable me_addr		: array16 := "1000000000000000";
	shared variable me_data		: array16 := zero;
	shared variable me_con 	: int5 := 0;
	shared variable clk_div 	: int5 := 0;
	
	--	ME/WB
	signal mewb_data		: array16 := zero;
	signal mewb_wb			: std_logic := '0';
	signal mewb_op			: int5 := 0;
	signal mewb_rz			: array16 := zero;
	signal wb_instant_rz			: array16 := zero;
	signal wb_just_nop		: std_logic := '0';
	shared variable wb_data 	: array16 := zero;
	
	--	WB
	shared variable wb_state	: int5 := 0;
	shared variable wb_rz	: array16 := zero;
	shared variable wb_nop	: int5 := 0;
	shared variable wb_release : int5 := 0;
	
	--	register
	signal r0				: array16 := zero;
	signal r1				: array16 := "0000000000000001";
	signal r2				: array16 := "1000011111111111";
	signal r3				: array16 := "0000000011111111";
	signal r4				: array16 := "0000000000000011";
	signal r5				: array16 := zero;
	signal r6				: array16 := zero;
	signal r7				: array16 := zero;
	signal T				: array16 := zero;
	signal SP				: array16 := "0000000000011100";
	signal IH				: array16 := "1010101010101010";
	
	
	function Sign_extend4(imm : std_logic_vector(3 downto 0)) return array16 is
	begin
		if imm(3) = '1' then
			return "111111111111" & imm;
		else
			return "000000000000" & imm;
		end if;
	end function;	
	
	function Sign_extend5(imm : std_logic_vector(4 downto 0)) return array16 is
	begin
		if imm(4) = '1' then
			return "11111111111" & imm;
		else
			return "00000000000" & imm;
		end if;
	end function;	
	
	function Sign_extend8(imm : std_logic_vector(7 downto 0)) return array16 is
	begin
		if imm(7) = '1' then
			return "11111111" & imm;
		else
			return "00000000" & imm;
		end if;
	end function;
	
	function Sign_extend11(imm : std_logic_vector(10 downto 0)) return array16 is
	begin
		if imm(10) = '1' then
			return "11111" & imm;
		else
			return "00000" & imm;
		end if;
	end function;
	
	function Zero_extend3(imm : std_logic_vector(2 downto 0)) return array16 is
	begin
		return "0000000000000" & imm;
	end function;
	
	function Zero_extend5(imm : std_logic_vector(4 downto 0)) return array16 is
	begin
		return "00000000000" & imm;
	end function;
	
	
	function Zero_extend8(imm : std_logic_vector(7 downto 0)) return array16 is
	begin
		return "00000000" & imm;
	end function;
	
	function Zero_extend11(imm : std_logic_vector(10 downto 0)) return array16 is
	begin
		return "00000" & imm;
	end function;
	
	function setreg(reg : std_logic_vector(2 downto 0)) return array16 is
	begin
		return "0000000000000" & reg;
	end function;
	
	procedure getreg(reg : array16; signal data : out array16) is
	begin
		case reg is
			when "0000000000000000" => data <= r0;
			when "0000000000000001" => data <= r1;
			when "0000000000000010" => data <= r2;
			when "0000000000000011" => data <= r3;
			when "0000000000000100" => data <= r4;
			when "0000000000000101" => data <= r5;
			when "0000000000000110" => data <= r6;
			when "0000000000000111" => data <= r7;
			when "1000000000000001" => data <= T;
			when "1000000000000010" => data <= SP;
			when "1000000000000011" => data <= IH;
			when others => data <= "0000000000000000";
		end case;
	end procedure;
	

begin
	
	------------------------------ IF ------------------------------
	process (clk)
	begin
		if (clk'event and clk = '1') then
			case if_state is
				when 0 =>  
					--	get correct PC
					if B_jump = '1' then
						if_pc := B_pc;
					elsif LW_jump = '1' then
						if_pc := LW_pc;
					elsif JR_jump = '1' then
						if_pc := JR_pc;
					else
						if_pc := pc_next;
					end if;

					-- when mem access ram2
					if access_ram2 = '0' then
						if_nop := 0;
					else
						if SW_ram2_op = 15 or SW_ram2_op = 16 then
							-- read
							if_nop := 1;
						else
							-- write
							if_nop := 2;
						end if;
					end if;
				when 1 =>
					EN_ram2 <= '0';
					if if_nop = 0 then
						addr_ram2 <= "00" & if_pc;
						data_ram2 <= "ZZZZZZZZZZZZZZZZ";
						OE_ram2 <= '0';
					elsif if_nop = 1 then
						addr_ram2 <= "00" & SW_ram2_addr;
						data_ram2 <= "ZZZZZZZZZZZZZZZZ";
						OE_ram2 <= '0';
					else
						WE_ram2 <= '1';
						OE_ram2 <= '1';
						data_ram2 <= SW_ram2_data;
						addr_ram2 <= "00" & SW_ram2_addr;
					end if;
				when 2 =>
					if if_nop = 0 then
						if_ins := data_ram2;
						OE_ram2 <= '1';
					elsif if_nop = 1 then
						if_data := data_ram2;
						OE_ram2 <= '1';
					else
						WE_ram2 <= '0';
					end if;
				when 3 =>
					if if_nop = 0 then
						pc_next <= if_pc + "1";
						ifid_pc <= if_pc + "1";
						ifid_ins <= if_ins;
						
						case if_ins(15 downto 11) is
							when "00001" =>
								--NOP
								if_op := 0;
							when "00010" =>
								--B
								if_op := 1;
							when "00100" =>
								--BEQZ
								if_op := 2;
							when "00101" =>
								--BNEZ
								if_op := 3;
							when "00110" =>
								case if_ins(1 downto 0) is
									when "00" =>
										--SLL
										if_op := 4;
									when "11" =>
										--SRA
										if_op := 5;
									when others =>
								end case;
							when "01000" =>
								--ADDIU3
								if_op := 6;
							when "01001" =>
								--ADDIU
								if_op := 7;
							when "01011" =>
								--SLTUI
								if_op := 8;
							when "01100" =>
								case if_ins(10 downto 8) is
									when "000" =>
										--BTEQZ
										if_op := 9;
									when "011" =>
										--ADDSP
										if_op := 10;
									when "100" =>
										--MTSP
										if_op := 11;
									when others=>
								end case;
							when "01101" =>
								--LI
								if_op := 12;
								--led <= setreg(if_ins(10 downto 8))+1;
							when "01110" =>
								--CMPI
								if_op := 13;
							when "01111" =>
								--MOVE
								if_op := 14;
							when "10010" =>
								--LWSP
								if_op := 15;
							when "10011" =>
								--LW
								if_op := 16;
							when "11010" =>
								--SWSP
								if_op := 17;
							when "11011" =>
								--SW
								if_op := 18;
							when "11100" =>
								case if_ins(1 downto 0) is
									when "01" =>
										--ADDU
										if_op := 19;
									when "11" =>
										--SUBU
										if_op := 20;
									when others =>
								end case;
							when "11101" =>
								case if_ins(4 downto 0) is
									when "00000" =>
										if if_ins(6) = '0' then
											--JR
											if_op := 21;
										elsif if_ins(6) = '1' then
											--MFPC
											if_op := 22;
										end if;
									when "01100" =>
										--AND
										if_op := 23;
									when "01010" =>
										--CMP
										if_op := 24;
									when "01101" =>
										--OR
										if_op := 25;
									when "00010" =>
										--SLT
										if_op := 26;
									when "01011" =>
										--NEG
										if_op := 27;
									when others =>
								end case;
										
							
							when "11110" =>
								case if_ins(0) is
									when '0' =>
										--MFIH
										if_op := 28;
									when '1' =>
										--MTIH
										if_op := 29;
									when others =>
								end case;
							
							when others =>
						end case;
						ifid_op <= if_op;
					elsif if_nop = 1 then
						if_wb_data <= if_data;
					end if;
					led(7 downto 0) <= if_pc(7 downto 0);
				when others =>
					--	do nothing
			end case;
			if if_state = 3 then
				if_state := 0;
			else
				if_state := if_state + 1;
			end if;
		end if;
	end process;
	
	
	------------------------------ ID ------------------------------
	process (clk)
	variable tmp_pc: array16 := zero;
	begin
		if clk'event and clk = '1' then
			case id_state is
				when 0 =>
					--	get OP
					if (B_nop = '1' or JR_nop = '1' or LW_nop = '1' or access_ram2 = '1') then
						id_op := 0;
					else
						id_op := ifid_op;
					end if;
					if access_ram2 = '1' then
						id_nop := 1;
					else
						id_nop := 0;
					end if;
					id_pc := ifid_pc;
					id_ins := ifid_ins;
					rx := "1111111111111111";
					ry := "1111111111111111";
					
				when 1 =>
					if id_nop = 0 then
						JR_jump <= '0';
						JR_nop <= '0';
						case id_op is
							when 0 =>
								--NOP
								
							when 1 =>
								--B
								wb := '0';
								imm := Sign_extend11( id_ins(10 downto 0));
								
							when 2 =>
								--BEQZ
								wb := '0';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg );
								imm := Sign_extend8( id_ins(7 downto 0) );
								
							when 3 =>
								--BNEZ
								wb := '0';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg );
								imm := Sign_extend8( id_ins(7 downto 0) );
								
							when 4 =>
								--SLL
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								imm := "0000000000000" & id_ins(4 downto 2);
								rz := setreg(id_ins(10 downto 8));
								
							when 5 =>
								--SRA
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								imm := "0000000000000" & id_ins(4 downto 2);
								rz := setreg(id_ins(10 downto 8));
								
							when 6 =>
								--ADDIU3
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg);
								rz := setreg(id_ins(7 downto 5));
								imm := Sign_extend5( id_ins(3) & id_ins(3 downto 0));
								
							when 7 =>	
								--ADDIU
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg);
								rz := setreg(id_ins(10 downto 8));
								imm := Sign_extend8( id_ins(7 downto 0));
								
							when 8 =>
								--SLTUI
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg );
								imm := "00000000" & id_ins(7 downto 0);
								rz := treg;
								
							when 9 =>
								--BTEQZ
								wb := '0';
								rx := treg;
								getreg( rx, a_reg );
								imm := Sign_extend8( id_ins(7 downto 0));
								
							when 10 =>
								--ADDSP
								wb := '1';
								rx := spreg;
								getreg( rx, a_reg );
								rz := spreg;
								imm := Sign_extend8( id_ins(7 downto 0));
								
							when 11 =>
								--MTSP
								wb := '1';
								rx := setreg( id_ins(7 downto 5));
								getreg( rx, a_reg);
								rz := spreg;
								
							when 12 =>
								--LI
								wb := '1';
								rz := setreg(id_ins(10 downto 8));
								imm := "00000000" & id_ins(7 downto 0);
								
							when 13 =>
								--CMPI
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg );
								imm := Sign_extend8(id_ins(7 downto 0));
								rz := spreg;
								
							when 14 =>
								--MOVE
								wb := '1';
								rx := setreg(id_ins(7 downto 5));
								rz := setreg(id_ins(10 downto 8));
								getreg(rx, a_reg);	
								
							when 15 =>
								--LWSP
								wb := '1';
								rx := spreg;
								getreg( rx, a_reg );
								rz := setreg(id_ins(10 downto 8));
								imm := Sign_extend8( id_ins(7 downto 0));
								
							when 16 =>
								--LW
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg );
								rz := setreg(id_ins(7 downto 5));
								imm := Sign_extend5( id_ins(4 downto 0));
								
							when 17 =>
								--SWSP
								wb := '0';
								rx := spreg;
								getreg( rx, a_reg );
								ry := setreg(id_ins(10 downto 8));
								getreg( ry, b_reg );
								imm := Sign_extend8( id_ins(7 downto 0));
								
							when 18 =>
								--SW
								wb := '0';
								rx := setreg(id_ins(10 downto 8));
								getreg( rx, a_reg );
								ry := setreg(id_ins(7 downto 5));
								getreg( ry, b_reg );
								imm := Sign_extend5( id_ins(4 downto 0));
								
							when 19 =>
								--ADDU
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								rz := setreg(id_ins(4 downto 2));
								
							when 20 =>
								--SUBU
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								rz := setreg(id_ins(4 downto 2));
								
							when 21 =>
								--JR
								wb := '0';
								JR_nop <= '1';
								JR_jump <= '1';
								getreg( setreg(id_ins(10 downto 8)), JR_pc);
								
							when 22 =>
								--MFPC
								wb := '1';
								rz := setreg(id_ins(10 downto 8));
								
							when 23 =>
								--AND
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								rz := setreg(id_ins(10 downto 8));
								
							when 24 =>
								--CMP
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								rz := treg;
								
							when 25 => 
								--OR
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								rz := setreg(id_ins(10 downto 8));
								
							when 26 =>
								--SLT
								wb := '1';
								rx := setreg(id_ins(10 downto 8));
								ry := setreg(id_ins( 7 downto 5));
								getreg( rx, a_reg );
								getreg( ry, b_reg );
								rz := treg;
							
							when 27 =>
								--NEG
								--to be continued
								
							when 28 =>
								--MFIH
								wb := '1';
								rx := ihreg;
								getreg( rx, a_reg );
								rz := setreg(id_ins(10 downto 8));
								
							when 29 =>
								--MTIH
								wb := '1';
								rx := setreg( id_ins(10 downto 8));
								getreg( rx, a_reg);
								rz := ihreg;
								
								
							when others =>
						end case;
					end if;
				
				when 2 =>
					if id_nop = 0 then
						idex_pc <= id_pc;
						idex_op <= id_op;
						idex_rz <= rz;
						idex_imm <= imm;
						idex_wb <= wb;
					end if;
					
				when 3 =>
				
				when others =>
					--	do nothing
			end case;
			if id_state = 3 then
				id_state := 0;
			else
				id_state := id_state + 1;
			end if;
		end if;
	end process;
	

	------------------------------ EX ------------------------------
	process (clk)
		variable tmp_int : integer;
		variable tmp_in2 : integer;
	begin
		if clk'event and clk = '1' then
			case ex_state is
				
				when 0 =>
					if B_nop = '1' or LW_nop = '1' or access_ram2 = '1' then
						ex_op := 0;
					else
						ex_op := idex_op;
					end if;
					if access_ram2 = '1' then
						ex_nop := 1;
					else 
						ex_nop := 0;
					end if;
					if data_conf_A = '1' then
						A := res;
					elsif LW_conf_A = '1' then
						A := data;
					else
						A := a_reg;
					end if;

					if data_conf_B = '1' then
						B := res;
					elsif LW_conf_B = '1' then
						B := data;
					else
						B := b_reg;
					end if;
					
					
					ex_wb := idex_wb;
					ex_pc := idex_pc;
					ex_rd := rz;
					ex_imm := imm;
					ex_lw := '0';
					ex_br := '0'; 
					
				when 1 =>
					case ex_op is
						when 0 =>
							--NOP
						when 1 =>
							--B
							ex_br := '1';
							res := ex_pc + ex_imm;
						when 2 =>
							--BEQZ
							if A = zero then
								ex_br := '1';
								res := ex_pc + ex_imm;
							end if;
						when 3 =>
							--BNEZ 
							if A /= zero then
								ex_br := '1';
								res := ex_pc + ex_imm;
							end if;
						when 4 =>
							---SLL
							if ex_imm = zero then
								tmp_int := 8;
								res := to_stdlogicvector(to_bitvector(B) sll tmp_int);
							else 
								tmp_int := conv_integer(ex_imm);
								res := to_stdlogicvector(to_bitvector(B) sll tmp_int);
							end if;
						when 5 =>
							--SRA
							if ex_imm = zero then
								tmp_int := 8;
								res := to_stdlogicvector(to_bitvector(B) sra tmp_int);
							else 
								tmp_int := conv_integer(ex_imm);
								res := to_stdlogicvector(to_bitvector(B) sra tmp_int);
							end if;
						when 6 =>
							--ADDIU3
							res := A + ex_imm;
						when 7 => 
							--ADDIU
							res := A + ex_imm;
						when 8 =>
							--SLTUI  
							if conv_integer(A) < conv_integer(ex_imm) then
								res := zero + 1;
							else
								res := zero;
							end if;
						when 9 =>
							--BTEQZ 
							if A = zero then
								ex_br := '1';
								res := ex_pc + ex_imm;
							end if;
						when 10 =>
							--ADDSP
							res := A + ex_imm;
						when 11 =>
							--MTSP
							res := A;
						when 12 =>
							--LI
							res := ex_imm;
						when 13 =>
							--CMPI
							if A = ex_imm then
								res := zero;
							else
								res := zero + 1;
							end if;
						when 14 =>
							--MOVE
							res := A;
						when 15 =>
							--LWSP
							addr := A + ex_imm;
							ex_lw := '1';
						when 16 =>
							--LW
							addr := A + ex_imm;		
							ex_lw := '1';
						when 17 =>
							--SWSP
							res := B;
							addr := A + ex_imm;
						when 18 =>
							--SW
							res := B;
							addr := A + ex_imm;
						when 19 =>
							--ADDU
							res := A + B;
						when 20 =>
							--SUBU
							res := A - B;
						when 22 =>
							--MFPC
							res := ex_pc;
						when 23 =>
							--AND
							res := A and B;
						when 24 =>
							--CMP
							if A = B then
								res := zero;
							else
								res := zero + 1;
							end if;
						when 25 =>
							--OR
							res := A or B;
						when 26 =>
							--SLT
							if A < B then
								res := "0000000000000001";
							else
								res := "0000000000000000";
							end if;
						when 27 =>
							--NEG
							res := 0 - B;
						when 28 =>
							--MFIH
							res := A;
						when 29 =>
							--MTIH
							res := A;
						when others =>
							--	do nothing
					end case;
				
				when 2 =>
				
				when 3 =>
					--	set register
					if ex_nop = 0 then
						B_jump <= '0';
						B_nop <= '0';
						LW_jump <= '0';
						LW_nop <= '0';
						
						data_conf_A <= '0';
						data_conf_B <= '0';
						
						exme_wb <= ex_wb;
						exme_pc <= ex_pc;
						exme_op <= ex_op;
						exme_rz <= ex_rd;
						exme_res <= res;
						exme_addr <= addr;
						
						if ex_lw = '0' and ex_wb = '1' and id_op /= 0 then
							if ex_rd = rx then
								data_conf_A <= '1';
							end if;
							if ex_rd = ry then
								data_conf_B <= '1';
							end if;
						end if;
						
						if ex_lw = '1' and id_op /= 0 then
							if ex_rd = rx or ex_rd = ry then
								LW_jump <= '1';
								LW_nop <= '1';
								LW_pc <= ex_pc;
							end if;
						end if;
						
						if ex_br = '1' then
							B_jump <= '1';
							B_nop <= '1';
							B_pc <= res;
						end if;
					end if;
				when others =>
					--	do nothing
				
			end case;	
			if ex_state = 3 then
				ex_state := 0;
			else
				ex_state := ex_state + 1;
			end if;
		end if;
	end process;
	
	
	------------------------------ ME ------------------------------
	process (clk)
	begin
		if clk'event and clk = '1' then
			-- led(15) <= data_ready;
			case me_state is
				when 0 =>
				
					me_wb := exme_wb;
					me_pc := exme_pc;
					me_op := exme_op;
					me_rz := exme_rz;
					me_addr := exme_addr;
					me_data := exme_res;
					
					--me_con LoadSerial= 1 LW=2  WriteSerial=3   SW=4   Other=0 
					me_con := 0;
					--exme_addr is the address to read/write
					--!assume that exme_res is the corresponding data.
					--	datamem prepare data
					case me_op is
						when 15 | 16 => --LW_SP  LW
							if me_addr = "1011111100000000" then -- load_serial
								--shut down ram1
								EN_ram1 <= '1';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
								--prepare serial
								rdn <= '1';
								wrn <= '1';
								data_ram1 <= "ZZZZZZZZZZZZZZZZ";
								me_con := 1;
							elsif me_addr = "1011111100000001" then -- load BF01
								EN_ram1 <= '1';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
							
								rdn <= '1';
								wrn <= '1';
								
								me_con := 5;
							else -- lw
								--prepare ram1
								EN_ram1 <= '0';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
								rdn <= '1';
								wrn <= '1';
								
								data_ram1 <= "ZZZZZZZZZZZZZZZZ";
								addr_ram1 <= "00" & exme_addr;                        
								me_con := 2;
							end if;
						when 17 | 18 => --SW_SP
							if me_addr = "1011111100000000" then -- write_serial
 								--shut down ram1
								EN_ram1 <= '1';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
								rdn <= '1';
								wrn <= '1';
								--prepare serial
								data_ram1 <= exme_res;
								me_con := 3;
							else -- SW
								-- prepare ram1
								EN_ram1 <= '0';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
								rdn <= '1';
								wrn <= '1';
								
								data_ram1 <= exme_res;
								addr_ram1 <= "00" & exme_addr;
								me_con := 4;
							end if;
						when others =>
							data := exme_res;
					end case;
					
				when 2 =>
					case me_con is
						when 1 =>
							--load_s
							rdn <= '0';
						when 2 =>
							--lw
							OE_ram1 <= '0';
						when 3 =>
							--write_s
							wrn <= '0';
						when 4 =>
							--sw
							WE_ram1 <= '0';
						when others => --do nothing
					end case;
					access_ram2 <= '0';
				when 3 =>
					
					--	get data
					case me_con is
						when 1 =>
							--load_s
							data := "00000000" & data_ram1(7 downto 0);
							rdn <= '1';  
						when 2 =>
							--lw
							data := data_ram1;
							OE_ram1 <= '1';
						when 3 =>
							--write_s
							wrn <= '1';
						when 4 =>
							--sw
							WE_ram1 <= '1';
						when 5 =>
							data := "00000000000000" & (data_ready) & (tbre and tsre);
						when others => --do nothing
					end case;
					
					if me_addr(15) = '0' then
						access_ram2 <= '1';
						SW_ram2_addr <= me_addr;
						SW_ram2_data <= me_data;
						SW_ram2_op <= me_op;
					end if;
					--	set register
					LW_conf_A <= '0';
					LW_conf_B <= '0';
					
					mewb_wb	 <= me_wb;
					mewb_op <= me_op;
					mewb_rz <= me_rz;
					mewb_data <= data;
					
					if me_wb = '1' and me_op /= 0 and id_op /= 0 then
						if me_rz = rx then  
							LW_conf_A <= '1';
						end if;
						if me_rz = ry then
							LW_conf_B <= '1';
						end if;
					end if;
					
				when others =>
					--	do nothing
				
			end case;
			if me_state = 3 then
				me_state := 0;
			else
				me_state := me_state + 1;
			end if;
		end if;
	end process;
	
	
	------------------------------ WB ------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			case wb_state is
				when 0 =>
					if access_ram2 = '1' then -- 暂停一个周期等ram2
						wb_nop := 1;
						wb_instant_rz <= mewb_rz;
					else
						if wb_just_nop = '1' then -- 如果是暂停回来,那么数据就从ram2来,地址从寄存器来
							wb_data := if_wb_data;
							wb_rz := wb_instant_rz;
							wb_release := 1;
						else -- 一般情况:访存不访问ram2
							wb_nop := 0;
							wb_data := mewb_data;
							wb_rz := mewb_rz;
						end if;
					end if;
				when 1 =>
					if wb_nop = 0 then
						case wb_rz is
							when "0000000000000000" => r0 <= wb_data;
							when "0000000000000001" => r1 <= wb_data;
							when "0000000000000010" => r2 <= wb_data;
							when "0000000000000011" => r3 <= wb_data;
							when "0000000000000100" => r4 <= wb_data;
							when "0000000000000101" => r5 <= wb_data;
							when "0000000000000110" => r6 <= wb_data;
							when "0000000000000111" => r7 <= wb_data;
							when "1000000000000001" =>  T <= wb_data;
							when "1000000000000010" => SP <= wb_data;
							when "1000000000000011" => IH <= wb_data;
							when others => -- do nothing
						end case;
					end if;
				when 2 =>
					if wb_nop = 1 then
						wb_just_nop <= '1';
					end if;
					if wb_release = 1 then
						wb_just_nop <= '0';
					end if;
				when 3 =>
					
				when others =>
					--	do nothing
			end case;
			if wb_state = 3 then
				wb_state := 0;
			else
				wb_state := wb_state + 1;
			end if;
		end if;
		state <= wb_state;
	end process;
	
	---------------------------------- DEBUG --------------------------------
	process(state)
	begin
		case state is
			when 0 => digit1<="0111111";
			when 1 => digit1<="0000110";
			when 2 => digit1<="1011011";
			when 3 => digit1<="1001111";
			when 4 => digit1<="1100110";
			when others=>digit1<="0000000";
		end case;
	end process;
	
	process(clk)
	begin
		case ifid_op is
			when 0 => digit2<="0111111"; --NOP
			when 1 => digit2<="0000110"; --B
			when 7 => digit2<="1011011"; --ADDIU
			when 12 => digit2<="1001111"; --LI
			when 18 => digit2<="1100110"; --SW
--			when 29 => digit2<="1101101"; --MTIH
			when 21 => digit2<="1101101"; --JR
			when 22 => digit2<="1111101"; --MFPC
			when 4 => digit2<="0000111"; --SLL
			when 16 => digit2<="1111111"; --LW
			when 2 => digit2<="1101111"; --BEQZ
			when others=>digit2<="0000000";
		end case;
		led(15 downto 8) <= r6(7 downto 0); --R6
	end process;
	
	process(clk_50m)
	begin
--		clk <= clk_50m;

--		if clk_50m'event and clk_50m = '1' then
--			if clk_div = 1 then
--				clk_div := 0;
--				clk <= not clk;
--			else
--				clk_div := clk_div + 1;
--			end if;
--		end if;
	end process;
	
	process(clk_single)
	begin
		clk <= clk_single;
	end process;
	
	
	
	
	
	
end behavioral;
