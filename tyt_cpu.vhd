
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;


entity tyt_cpu is
	port (
		clk		: in std_logic;
		--clk_50m	: in std_logic;
		--rst		: in std_logic;
		led		: out std_logic_vector(15 downto 0) := "0000000000000000";
		OE_ram1 : out  STD_LOGIC := '1';
		WE_ram1 : out  STD_LOGIC := '1';
		EN_ram1 : out  STD_LOGIC := '0';
		data_ram1 : inout  STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
		addr_ram1 : out  STD_LOGIC_VECTOR (17 downto 0) := "000000000000000000";
		OE_ram2 : out  STD_LOGIC := '1';
		WE_ram2 : out  STD_LOGIC := '1';
		EN_ram2 : out  STD_LOGIC := '0';
		data_ram2 : inout  STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
		addr_ram2 : out  STD_LOGIC_VECTOR (17 downto 0) := "000000000000000000"
		--rdn: out STD_LOGIC := '1';
		--wrn: out STD_LOGIC := '1';
		--data_ready	: in std_logic;
		--tbre		: in std_logic;
		--tsre		: in std_logic;
		--digit1	:	out  STD_LOGIC_VECTOR (6 downto 0) := "1111111";
		--digit2	:	out  STD_LOGIC_VECTOR (6 downto 0) := "1111111"
	);
end tyt_cpu;

architecture Behavioral of tyt_cpu is
	subtype array16	is std_logic_vector(15 downto 0);
	subtype int5  is integer range 0 to 31;

	constant zero    : array16 :="0000000000000000";
	constant zeroreg : array16 :="1000000000000000";
	constant treg    : array16 :="1000000000000001";
	constant spreg   : array16 :="1000000000000010";
	constant ihreg   : array16 :="1000000000000011";

	--signal my_clk	: std_logic := "1";

	shared variable pc : array16 := zero;


	signal B_nop : std_logic := '0';
	signal JR_nop : std_logic := '0';
	signal LW_nop : std_logic := '0';

	signal B_jump : std_logic := '0';
	signal JR_jump : std_logic := '0';
	signal LW_jump : std_logic := '0';

	signal pc_next : array16 :=zero;
	signal pc_reg : array16 :=zero;
	signal pc_res : array16 :=zero;
	signal pc_LW : array16 :=zero;

	signal LW_conf_A : std_logic := '0';
	signal LW_conf_B : std_logic := '0';
	signal data_conf_A : std_logic := '0';
	signal data_conf_B : std_logic := '0';

	--	IF
	shared variable if_state : int5 := 0;
	shared variable if_ins : array16 := zero;
	shared variable if_pc : array16 := zero;
	shared variable if_op : int5 := 0;

	--	IF/ID
	signal ifid_op : int5 := 0;
	signal ifid_pc : array16 := zero;
	signal ifid_ins : array16 :=zero;



	--	ID
	shared variable id_state : int5 := 0;
	shared variable id_op : int5 := 0;
	shared variable id_ins : array16 :=zero;
	shared variable id_pc : array16 :=zero;

	shared variable JR_pc : array16 :=zero;

	signal a_reg : array16 := zero;
	signal b_reg : array16 := zero;
	shared variable id_imm : array16 := zero;
	shared variable rx : array16 :=zero;
	shared variable ry : array16 :=zero;
	shared variable rz : array16 :=zero;    --result register
	shared variable ex : std_logic := '0';	 --ex control
	shared variable me : int5 := 0;  		 --me control
	shared variable wb : std_logic := '0';  --wb control


	--	ID/EX
	signal idex_op : int5 := 0;
	signal idex_pc : array16 := zero;
	signal idex_rx : array16 := zero;
	signal idex_ry : array16 := zero;
	signal idex_rz : array16 := zero;
	signal idex_a : array16 := zero;
	signal idex_b : array16 := zero;
	signal idex_imm : array16 := zero;
	signal idex_me : int5 := 0;
	signal idex_wb : std_logic := '0';

	--	EX
	shared variable ex_state : int5 := 0;
	shared variable ex_op : int5 := 0;
	shared variable ex_pc : array16 :=zero;
	shared variable A : array16 :=zero;
	shared variable B : array16 :=zero;
	shared variable res : array16 :=zero;
	shared variable addr : array16 :=zero;
	shared variable ex_rx : array16 :=zero;
	shared variable ex_ry : array16 :=zero;
	shared variable ex_rz : array16 :=zero;
	shared variable ex_imm : array16 :=zero;
	shared variable ex_a : array16 :=zero;
	shared variable ex_b : array16 :=zero;
	shared variable ex_me : int5 := 0;
	shared variable ex_wb : std_logic := '0';




	--	EX/ME
	signal exme_op : int5 := 0;
	signal exme_pc :array16 := zero;
	signal ex_res : array16 := zero;
	signal exme_rz : array16 := zero;
	signal exme_me : int5 := 0;
	signal exme_wb : std_logic := '0';
	signal exme_SW : array16 :=zero;

	--	ME
	shared variable me_state : int5 := 0;
	shared variable me_op : int5 := 0;
	shared variable me_pc :array16 := zero;
	shared variable me_res : array16 :=zero;
	shared variable me_rz : array16 :=zero;
	shared variable me_me : int5 := 0;
	shared variable me_wb : std_logic := '0';
	shared variable me_SW : array16 :=zero;
	shared variable data : array16 :=zero;

	--	ME/WB

	signal mewb_res : array16 := zero;
	signal mewb_op : int5 := 0;
	signal mewb_rz : array16 := zero;
	signal mewb_wb : std_logic := '0';

	--	WB
	shared variable wb_state : int5 := 0;
	shared variable wb_res : array16 := zero;
	shared variable wb_op : int5 := 0;
	shared variable wb_rz : array16 := zero;
	shared variable wb_wb : std_logic := '0';


	--	reg
	signal r0				: array16 := "0000000000000000";
	signal r1				: array16 := "0000000000000000";
	signal r2				: array16 := "0000000000000000";
	signal r3				: array16 := "0000000000000000";
	signal r4				: array16 := "0000000000000000";
	signal r5				: array16 := "0000000000000000";
	signal r6				: array16 := "0000000000000000";
	signal r7				: array16 := "0000000000000000";
	signal T					: array16 := "0000000000000000";
	signal SP				: array16 := "0000000000000000";
	signal IH				: array16 := "0000000000000000";

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
----------------------------- IF -------------------------------
	process (clk)
	begin
		if (clk'event and clk = '1') then
			case if_state is
				when 0 =>
					if JR_jump = '1' then --JR type
						if_pc := pc_reg;
					elsif B_jump = '1' then --B type
						if_pc := pc_res;
					elsif LW_jump = '1' then --LW type
						if_pc := pc_LW;
					else
						if_pc := pc_next;
					end if;
					EN_ram1 <= '0';
					WE_ram1 <= '1';
					addr_ram1 <= if_pc & "00";
					data_ram1 <= "ZZZZZZZZZZZZZZZZ";
				when 1 =>
					--JR_jump <= '0';
					--B_jump <= '0';
					--LW_jump <= '0';
					OE_ram1 <= '0';
				when 2 =>
					if_ins := data_ram1;
					led <= if_ins;
					OE_ram1 <= '1';
				when 3 =>
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
				when 4 =>
					pc_next <= if_pc + '1';
					ifid_op <= if_op;
					ifid_ins <= if_ins;
					ifid_pc <= pc_next;



				when others =>
			end case;
			if if_state = 4 then
				if_state := 0;
			else
				if_state := if_state +1;
			end if;
		end if;
	end process;

----------------------------- ID -------------------------------

	process(clk)
	begin
		if (clk'event and clk = '1') then
			case id_state is
				when 0 =>

					if (B_nop = '1' or JR_nop = '1') or LW_nop = '1' then
						id_op := 0;
					else
						id_op := ifid_op;
						id_ins := ifid_ins;
						id_pc := ifid_pc;
					end if;



					--B_nop <= '0';
					JR_nop <= '0';
					JR_jump <= '0';
					--LW_nop <= '0';

					rx := "1111111111111111";
					ry := "1111111111111111";
					rz := "1111111111111111";

					me := 0;
					wb := '0';

				when 1 =>

				when 2 =>

				when 3 =>
					case id_op is
						when 0 =>
							--NOP
						when 1 =>
							--B
							wb := '0';
							id_imm := Sign_extend11( id_ins(10 downto 0));

						when 2 =>
							--BEQZ
							wb := '0';
							rx := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 3 =>
							--BNEZ
							wb := '0';
							rx := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 4 =>
							--SLL
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := rx;
							getreg(rx, a_reg);
							getreg(ry, b_reg);
							id_imm := Zero_extend3(id_ins(4 downto 2));

						when 5 =>
							--SRA
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := rx;
							getreg(rx, a_reg);
							getreg(ry, b_reg);
							id_imm := Zero_extend3(id_ins(4 downto 2));

						when 6 =>
							--ADDIU3
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := setreg(id_ins(7 downto 5));
							getreg(rx, a_reg);
							id_imm := Sign_extend4(id_ins(3 downto 0));

						when 7 =>
							--ADDIU
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := rx;
							getreg(rx, a_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 8 =>
							--SLTUI
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := treg;
							getreg(rx, a_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 9 =>
							--BTEQZ
							wb := '0';
							rx := treg;
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 10 =>
							--ADDSP
							wb := '1';
							rx := spreg;
							rz := rx;
							getreg(rx, a_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 11 =>
							--MTSP
							wb := '1';
							rx := setreg(id_ins(7 downto 5));
							rz := spreg;
							getreg(rx, a_reg);

						when 12 =>
							--LI
							wb := '1';
							rz := setreg(id_ins(10 downto 8));
							id_imm := Zero_extend8(id_ins(7 downto 0));

						when 13 =>
							--CMPI
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := treg;
							getreg(rx, a_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 14 =>
							--MOVE
							wb := '1';
							rx := setreg(id_ins(7 downto 5));
							rz := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);

						when 15 =>
							--LWSP
							wb := '1';
							me := 2;
							rx := spreg;
							rz := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 16 =>
							--LW
							wb := '1';
							me := 2;
							rx := setreg(id_ins(10 downto 8));
							rz := setreg(id_ins(7 downto 5));
							getreg(rx, a_reg);
							id_imm := Sign_extend5(id_ins(4 downto 0));

						when 17 =>
							--SWSP
							wb := '0';
							me := 1;
							rx := spreg;
							ry := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);
							getreg(ry, b_reg);
							id_imm := Sign_extend8(id_ins(7 downto 0));

						when 18 =>
							--SW
							wb := '0';
							me := 1;
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							getreg(rx, a_reg);
							getreg(ry, b_reg);
							id_imm := Sign_extend5(id_ins(4 downto 0));

						when 19 =>
							--ADDU
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := setreg(id_ins(4 downto 2));
							getreg(rx, a_reg);
							getreg(ry, b_reg);

						when 20 =>
							--SUBU
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := setreg(id_ins(4 downto 2));
							getreg(rx, a_reg);
							getreg(ry, b_reg);

						when 21 =>
							--JR
							wb := '0';
							JR_nop <= '1';
							JR_jump <= '1';
							getreg(setreg(id_ins(10 downto 8)), pc_reg);

						when 22 =>
							--MFPC
							wb := '1';
							rx :=setreg(id_ins(10 downto 8));
							-----r[x]<=PC         be continued

						when 23 =>
							--AND
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := rx;
							getreg(rx, a_reg);
							getreg(ry, b_reg);

						when 24 =>
							--CMP
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := treg;
							getreg(rx, a_reg);
							getreg(ry, b_reg);

						when 25 =>
							--OR
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := rx;
							getreg(rx, a_reg);
							getreg(ry, b_reg);

						when 26 =>
							--SLT
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							rz := treg;
							getreg(rx, a_reg);
							getreg(ry, b_reg);

						when 27 =>
							--NEG
							wb := '1';
							rx := setreg(id_ins(7 downto 5));
							rz := setreg(id_ins(10 downto 8));

							-- r[x]<=0-r[y]     tobe continued



						when 28 =>
							--MFIH
							wb := '1';
							rx := ihreg;
							rz := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);

						when 29 =>
							--MTIH
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := ihreg;
							getreg(rx, a_reg);


						when others =>

					end case;

			when 4 =>


				idex_pc <= id_pc;
				idex_op <= id_op;

				idex_me <= me;
				idex_wb <= wb;

				idex_rx <= rx;
				idex_ry <= ry;
				idex_rz <= rz;
				idex_a <= a_reg;
				idex_b <= b_reg;
				idex_imm <= id_imm;

			when others =>
			end case;
			if id_state = 4 then
				id_state := 0;
			else
				id_state := id_state +1;
			end if;
		end if;
	end process;

----------------------------- EX -------------------------------

	process(clk)
	begin
		if (clk'event and clk = '1') then
			case ex_state is
				when 0 =>



				when 1 =>

					if  B_nop = '1' then
						ex_op := 0;
					else
						ex_op := idex_op;
						ex_rx := idex_rx;
						ex_ry := idex_ry;
						ex_rz := idex_rz;
						ex_a := idex_a;
						ex_b := idex_b;
						ex_imm := idex_imm;

						ex_pc := idex_pc;
						ex_me := idex_me;
						ex_wb := idex_wb;
					end if;

					if data_conf_A='1' then
						A := ex_res;
					elsif LW_conf_A ='1' then
						A := me_res;
					else
						A := ex_a;
					end if;

					if data_conf_B='1' then
						B := ex_res;
					elsif LW_conf_B ='1' then
						B := me_res;
					else
						B := ex_b;
					end if;

					data_conf_A <= '0';
					--LW_conf_A <= '0';
					data_conf_B <= '0';
					--LW_conf_B <= '0';

					B_nop <= '0';
					B_jump <= '0';
					LW_nop <= '0';
					LW_jump <= '0';


				when 2 =>
				when 3 =>
					case ex_op is
						when 0 =>
							--NOP
						when 1 =>
							--B
							B_nop <= '1';
							B_jump <= '1';
							pc_res <= ex_pc + ex_imm;
						when 2 =>
							--BEQZ
							if A = zero then
								B_nop <= '1';
								B_jump <= '1';
								pc_res <= ex_pc + ex_imm;
							end if;
							--  to be continued
						when 3 =>
							--BNEZ
							if A /= zero then
								B_nop <= '1';
								B_jump <= '1';
								pc_res <= ex_pc + ex_imm;
							end if;
						when 4 =>
							---SLL
							if ex_imm = zero then
								res := to_stdlogicvector(to_bitvector(B) sll 8);
							else
								res := to_stdlogicvector(to_bitvector(B) sll conv_integer(ex_imm));
							end if;
						when 5 =>
							--SRA
							if ex_imm = zero then
								res := to_stdlogicvector(to_bitvector(B) sra 8);
							else
								res := to_stdlogicvector(to_bitvector(B) sra conv_integer(ex_imm));
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
								res := "0000000000000001";
							else
								res := "0000000000000000";
							end if;
						when 9 =>
							--BTEQZ
							if A = zero then
								B_nop <= '1';
								B_jump <= '1';
								pc_res <= ex_pc + ex_imm;
							end if;
							-- to be continued
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
								res := "0000000000000000";
							else
								res := "0000000000000001";
							end if;
						when 14 =>
							--MOVE
							res := A;
						when 15 =>
							--LWSP
							res := A + ex_imm;
						when 16 =>
							--LW
							res := A + ex_imm;
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
								res := "0000000000000000";
							else
								res := "0000000000000001";
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
							res := "0000000000000000" - A;
						when 28 =>
							--MFIH
							res := A;
						when 29 =>
							--MTIH
							res := A;
						when others =>


					end case;
				when 4 =>


					if  ex_wb = '1' and id_op /= 0 and ex_op /= 0 then
						if ex_rz = rx then
							data_conf_A <= '1';
						end if;
						if ex_rz = ry then
							data_conf_B <= '1';
						end if;
					end if;

					if (ex_op = 15 or ex_op = 16) and id_op /= 0 then
						if ex_rz = rx or ex_rz = ry then
							LW_jump <= '1';
							LW_nop <= '1';
							pc_LW <= ex_pc;
						end if;
					end if;


					ex_res <= res;
					exme_me <= ex_me;
					exme_wb <= ex_wb;
					exme_pc <= ex_pc;
					exme_op <= ex_op;
					exme_rz <= ex_rz;
					exme_SW <= addr;


				when others =>
			end case;
			if ex_state = 4 then
				ex_state := 0;
			else
				ex_state := ex_state + 1;
			end if;
		end if;
	end process;



----------------------------- ME -------------------------------

	process(clk)
	begin
		if (clk'event and clk = '1') then
			case me_state is
				when 0 =>
					me_me := exme_me;
					me_wb := exme_wb;
					me_pc := exme_pc;
					me_op := exme_op;
					me_res := ex_res;
					me_rz := exme_rz;
					me_SW := exme_SW;

					LW_conf_A <= '0';
					LW_conf_B <= '0';
				when 1 =>

				when 2 =>
					case me_me is
						when 1 =>
							--SW
							EN_ram2 <= '0';
							WE_ram2 <= '1';
							OE_ram2 <= '1';
							data_ram2 <= me_res;
							addr_ram2 <= "00" & me_SW;
						when 2 =>
							--LW
							EN_ram2 <= '0';
							WE_ram2 <= '1';
							OE_ram2 <= '1';
							data_ram2 <= "ZZZZZZZZZZZZZZZZ";
							addr_ram2 <= "00" & me_res;
						when others =>
							data := me_res;
					end case;

				when 3 =>
					case me_me is
						when 1 =>
							--SW
							WE_ram2 <= '0';
						when 2 =>
							--LW
							OE_ram2 <= '0';
						when others =>
					end case;

				when 4 =>
					case me_me is
						when 1 =>
							--SW
							WE_ram2 <= '1';
						when 2 =>
							--LW
							data := data_ram2;
							OE_ram2 <= '1';
						when others =>
					end case;


					if me_wb = '1' and me_op /= 0 and id_op /= 0 then
						if me_rz = rx then
							LW_conf_A <= '1';
						end if;
						if me_rz = ry then
							LW_conf_B <= '1';
						end if;
					end if;

					mewb_res <= data;
					mewb_wb <= wb;
					mewb_op <= me_op;
					mewb_rz <= me_rz;

				when others =>
			end case;
			if me_state = 4 then
				me_state := 0;
			else
				me_state := me_state + 1;
			end if;
		end if;
	end process;




----------------------------- WB -------------------------------

	process(clk)
	begin
		if (clk'event and clk = '1') then
			case wb_state is
				when 0 =>
					if mewb_wb = '1' and mewb_op /= 0 then
						case mewb_rz is
							when "0000000000000000" => r0 <= me_res;
							when "0000000000000001" => r1 <= me_res;
							when "0000000000000010" => r2 <= me_res;
							when "0000000000000011" => r3 <= me_res;
							when "0000000000000100" => r4 <= me_res;
							when "0000000000000101" => r5 <= me_res;
							when "0000000000000110" => r6 <= me_res;
							when "0000000000000111" => r7 <= me_res;
							when "1000000000000001" =>  T <= me_res;
							when "1000000000000010" => SP <= me_res;
							when "1000000000000011" => IH <= me_res;
							when others =>
						end case;
					end if;
					--led <= me_res;
				when 1 =>
				when 2 =>
				when 3 =>
				when 4 =>

				when others =>
			end case;
			if wb_state = 4 then
				wb_state := 0;
			else
				wb_state := wb_state +1;
			end if;
		end if;
	end process;


end Behavioral;
