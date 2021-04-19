library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tyt_cpu2 is
	port (
		clk_50m	: in std_logic;
		clk_11m  : in std_logic;
		clk_single : in std_logic;
		rst		: in std_logic;
		led		: out std_logic_vector(15 downto 0) := "0000000000000000";

		flash_byte : out std_logic;
		flash_vpen : out std_logic;
		flash_ce : out std_logic;
		flash_oe : out std_logic;
		flash_we : out std_logic;
		flash_rp : out std_logic;
		flash_addr : out std_logic_vector(22 downto 1);
		flash_data : inout std_logic_vector(15 downto 0);

		data_ram1 : inout  STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
		addr_ram1 : out  STD_LOGIC_VECTOR (17 downto 0) := "000000000000000000";
		OE_ram1 : out  STD_LOGIC := '1';
		WE_ram1 : out  STD_LOGIC := '1';
		EN_ram1 : out  STD_LOGIC := '0';
		--data_ram2 : inout  STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
		--addr_ram2 : out  STD_LOGIC_VECTOR (17 downto 0) := "000000000000000000";
		--OE_ram2 : out  STD_LOGIC := '1';
		--WE_ram2 : out  STD_LOGIC := '1';
		--EN_ram2 : out  STD_LOGIC := '0';
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
	subtype int5	is integer range 0 to 63;

	constant zero : array16 := "0000000000000000";

	constant  treg : array16 := "1000000000000001";
	constant spreg : array16 := "1000000000000010";
	constant ihreg : array16 := "1000000000000011";


	signal clk		:	std_logic := '1';
	--signal clk2		:	std_logic := '1';
	signal clk_nouse : std_logic := '0';
	signal pre_read : std_logic := '0';


	signal bp_pc	: array16 := zero;
	signal bp_jump	: std_logic := '0';


	shared variable pre_state : int5 := 0;
	shared variable pre_pc    : array16 := zero;
	shared variable pre_data  : array16 := zero;

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


	signal data_conf_A		: std_logic := '0';
	signal LW_conf_A		: std_logic := '0';
	signal a_reg	: array16 := zero;

	signal data_conf_B		: std_logic := '0';
	signal LW_conf_B		: std_logic := '0';
	signal b_reg	: array16 := zero;

	--	IF
	shared variable if_state	: int5 := 0;
	shared variable if_ins	: array16 := zero;
	shared variable if_pc	: array16 := zero;
	shared variable if_op	: int5 := 0;

	--	IF/ID
	signal ifid_ins		: array16 := zero;
	signal ifid_op			: int5 := 0;
	signal ifid_pc			: array16 := zero;

	--	ID
	shared variable id_state	: int5 := 0;
	shared variable id_ins	: array16 := zero;
	shared variable id_op	: int5 := 0;
	shared variable id_pc	: array16 := zero;
	shared variable rx		: array16 := zero;
	shared variable ry		: array16 := zero;
	signal id_rx				: array16 := zero;
	signal id_ry				: array16 := zero;
	shared variable rz		: array16 := zero;
	shared variable imm		: array16 := zero;
	shared variable wb		: std_logic := '0';
	shared variable me		: int5 := 0;

	--	ID/EX
	signal idex_imm			: array16 := zero;
	signal idex_wb		: std_logic := '0';
	signal idex_me		: int5 := 0;
	signal idex_op	: int5 := 0;
	signal idex_pc			: array16 := zero;
	signal idex_rz			: array16 := zero;

	--	EX
	shared variable ex_state	: int5 := 0;
	shared variable A			: array16 := zero;
	shared variable B			: array16 := zero;
	shared variable res		: array16 := zero;
	shared variable addr		: array16 := zero;
	shared variable ex_imm	: array16 := zero;
	shared variable ex_lw 	: std_logic := '0';
	shared variable ex_wb 	: std_logic := '0';
	shared variable ex_me	: int5 := 0;
	shared variable ex_br 	: std_logic := '0'; -- is branch or not
	shared variable ex_op	: int5 := 0;
	shared variable ex_pc	: array16 := zero;
	shared variable ex_rd	: array16 := zero;

	--	EX/ME
	signal exme_wb			: std_logic := '0';
	signal exme_me			: int5 := 0;
	signal exme_pc			: array16 := zero;
	signal exme_op			: int5 := 0;
	signal exme_rz			: array16 := zero;
	signal exme_res		: array16 := zero; -- the data to write
	signal exme_addr		: array16 := zero; -- the data address

	--	ME
	shared variable me_state	: int5 := 0;
	shared variable data			: array16 := zero;
	shared variable me_wb 		: std_logic := '0';
	shared variable me_me		: int5 := 0;
	shared variable me_op		: int5 := 0;
	shared variable me_pc		: array16 := zero;
	shared variable me_rz		: array16 := zero;
	shared variable me_con 	: int5 := 0;

	--	ME/WB
	signal mewb_data		: array16 := zero;
	signal mewb_wb			: std_logic := '0';
	signal mewb_op			: int5 := 0;
	signal mewb_rz			: array16 := zero;


	--	WB
	shared variable wb_state	: int5 := 0;

	--	register
	signal r0				: array16 := zero;
	signal r1				: array16 := zero;
	signal r2				: array16 := zero;
	signal r3				: array16 := zero;
	signal r4				: array16 := zero;
	signal r5				: array16 := zero;
	signal r6				: array16 := zero;
	signal r7				: array16 := zero;
	signal T					: array16 := zero;
	signal SP				: array16 := zero;
	signal IH				: array16 := zero;

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


	flash_byte <= '1';
	flash_vpen <= '1';
	flash_ce <= '0';
	flash_rp <= '1';


	--flash_data <= x"00FF";
	--flash_we <= '1';
	--flash_oe <= '0';
	--flash_addr <= "000000" & if_pc;


	------------------------------ IF ------------------------------





	------------------------------ ID ------------------------------
	process (clk)
	begin
		if (clk'event and clk = '1') then
			case state is

				when 50 =>
					id_pc := ifid_pc;
					id_ins := ifid_ins;
					id_op := 0;
					rx := "1111111111111111";
					ry := "1111111111111111";



					if (B_nop = '1' or JR_nop = '1') or LW_nop = '1' then
						id_ins := "0000100000000000";
					else
						--id_op := ifid_op;
					end if;

					JR_jump <= '0';

					JR_nop <= '0';

					wb := '0';
					me := 0;

					case id_ins(15 downto 11) is
						when "00001" =>
							--NOP
							id_op := 0;
						when "00010" =>
							--B
							id_op := 1;
							imm := Sign_extend11(id_ins(10 downto 0));
						when "00100" =>
							--BEQZ
							id_op := 2;
							rx := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);
							imm := Sign_extend8(id_ins(7 downto 0));
						when "00101" =>
							--BNEZ
							id_op := 3;
							rx := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);
							imm := Sign_extend8(id_ins(7 downto 0));
						when "00110" =>
							case id_ins(1 downto 0) is
								when "00" =>
									--SLL
									id_op := 4;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins( 7 downto 5));
									imm := "0000000000000" & id_ins(4 downto 2);
									rz := setreg(id_ins(10 downto 8));
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when "11" =>
									--SRA
									id_op := 5;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins( 7 downto 5));
									imm := "0000000000000" & id_ins(4 downto 2);
									rz := setreg(id_ins(10 downto 8));
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when others =>
							end case;
						when "01000" =>
							--ADDIU3
							id_op := 6;
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := setreg(id_ins(7 downto 5));
							imm := Sign_extend5( id_ins(3) & id_ins(3 downto 0));
							getreg(rx, a_reg);
						when "01001" =>
							--ADDIU
							id_op := 7;
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := setreg(id_ins(10 downto 8));
							imm := Sign_extend8( id_ins(7 downto 0));
							getreg(rx, a_reg);
						when "01011" =>
							--SLTUI
							id_op := 8;
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := treg;
							imm := "00000000" & id_ins(7 downto 0);
							getreg(rx, a_reg);
						when "01100" =>
							case id_ins(10 downto 8) is
								when "000" =>
									--BTEQZ
									id_op := 9;
									rx := treg;
									imm := Sign_extend8( id_ins(7 downto 0));
									getreg(rx, a_reg);
								when "011" =>
									--ADDSP
									id_op := 10;
									wb := '1';
									rx := spreg;
									rz := spreg;
									imm := Sign_extend8( id_ins(7 downto 0));
									getreg(rx, a_reg);
								when "100" =>
									--MTSP
									id_op := 11;
									wb := '1';
									rx := setreg( id_ins(7 downto 5));
									rz := spreg;
									getreg(rx, a_reg);
								when others=>
							end case;
						when "01101" =>
							--LI
							id_op := 12;
							--led <= setreg(id_ins(10 downto 8))+1;
							--led <= "1110001110001111";
							wb := '1';
							rz := setreg(id_ins(10 downto 8));
							imm := "00000000" & id_ins(7 downto 0);
						when "01110" =>
							--CMPI
							id_op := 13;
							wb := '1';
							rx := setreg(id_ins(10 downto 8));
							rz := spreg;
							imm := Sign_extend8(id_ins(7 downto 0));
							getreg(rx, a_reg);
						when "01111" =>
							--MOVE
							id_op := 14;
							wb := '1';
							rx := setreg(id_ins(7 downto 5));
							rz := setreg(id_ins(10 downto 8));
							getreg(rx, a_reg);

						when "10010" =>
							--LWSP
							id_op := 15;
							wb := '1';
							me := 1;
							rx := spreg;
							rz := setreg(id_ins(10 downto 8));
							imm := Sign_extend8( id_ins(7 downto 0));
							getreg(rx, a_reg);
						when "10011" =>
							--LW
							id_op := 16;
							wb := '1';
							me := 1;
							rx := setreg(id_ins(10 downto 8));
							rz := setreg(id_ins(7 downto 5));
							imm := Sign_extend5( id_ins(4 downto 0));
							getreg(rx, a_reg);
						when "11010" =>
							--SWSP
							id_op := 17;
							me := 2;
							rx := spreg;
							ry := setreg(id_ins(10 downto 8));
							imm := Sign_extend8( id_ins(7 downto 0));
							getreg(rx, a_reg);
							getreg(ry, b_reg);
						when "11011" =>
							--SW
							id_op := 18;
							me := 2;
							rx := setreg(id_ins(10 downto 8));
							ry := setreg(id_ins(7 downto 5));
							imm := Sign_extend5( id_ins(4 downto 0));
							getreg(rx, a_reg);
							getreg(ry, b_reg);
						when "11100" =>
							case id_ins(1 downto 0) is
								when "01" =>
									--ADDU
									id_op := 19;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins( 7 downto 5));
									rz := setreg(id_ins(4 downto 2));
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when "11" =>
									--SUBU
									id_op := 20;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins( 7 downto 5));
									rz := setreg(id_ins(4 downto 2));
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when others =>
							end case;
						when "11101" =>
							case id_ins(4 downto 0) is
								when "00000" =>
									if id_ins(6) = '0' then
										--JR
										id_op := 21;
										JR_nop <= '1';
										JR_jump <= '1';
										getreg(setreg(id_ins(10 downto 8)), JR_pc);
									elsif id_ins(6) = '1' then
										--MFPC
										id_op := 22;
										wb := '1';
										rz := setreg(id_ins(10 downto 8));
									end if;
								when "01100" =>
									--AND
									id_op := 23;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins( 7 downto 5));
									rz := setreg(id_ins(10 downto 8));
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when "01010" =>
									--CMP
									id_op := 24;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins( 7 downto 5));
									rz := treg;
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when "01101" =>
									--OR
									id_op := 25;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins(7 downto 5));
									rz := setreg(id_ins(10 downto 8));
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when "00010" =>
									--SLT
									id_op := 26;
									wb := '1';
									rx := setreg(id_ins(10 downto 8));
									ry := setreg(id_ins( 7 downto 5));
									rz := treg;
									getreg(rx, a_reg);
									getreg(ry, b_reg);
								when "01011" =>
									--NEG
									id_op := 27;
								when others =>
							end case;


						when "11110" =>
							case id_ins(0) is
								when '0' =>
									--MFIH
									id_op := 28;
									wb := '1';
									rx := ihreg;
									rz := setreg(id_ins(10 downto 8));
									getreg(rx, a_reg);
								when '1' =>
									--MTIH
									id_op := 29;
									wb := '1';
									rx := setreg( id_ins(10 downto 8));
									rz := ihreg;
									getreg(rx, a_reg);
								when others =>
							end case;

						when others =>
					end case;
					--ifid_op <= if_op;
					id_rx <= rx;
					id_ry <= ry;

				when 51 =>

				--when 52 =>

				--when 53 =>


				--when 54 =>

					idex_pc <= id_pc;
					idex_op <= id_op;
					idex_rz <= rz;
					idex_imm <= imm;
					idex_wb <= wb;
					idex_me <= me;

				when others =>
					--	do nothing
			end case;
		end if;
	end process;


	------------------------------ EX ------------------------------
	process (clk)
	begin
		if (clk'event and clk = '1') then
			case state is

				when 50 =>
					if B_nop = '1' or LW_nop = '1' then
						ex_op := 0;
					else
						ex_op := idex_op;
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
					ex_me := idex_me;
					ex_pc := idex_pc;
					ex_rd := rz;
					ex_imm := imm;
					ex_lw := '0';
					ex_br := '0';

				when 51 =>
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
					end case;

				when 52 =>

				--when 53 =>

				--when 54 =>
					B_jump <= '0';
					LW_jump <= '0';

					B_nop <= '0';

					LW_nop <= '0';
					data_conf_A <= '0';
					data_conf_B <= '0';

					exme_wb <= ex_wb;
					exme_me <= ex_me;
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
				when others =>

			end case;
		end if;
	end process;


	------------------------------ ME ------------------------------
	process (clk, rst)
	begin
		if (clk'event and clk = '1') then
			case state is
				when 0 =>
					--if (rst = '0') then
						--pre_pc := zero;
						--if_pc := zero;
					--end if;
					led <= pre_pc;
					pre_read <= '0';
					flash_data <= x"00FF";
				when 10 =>
					led <= "1000000000000000";
					flash_we <= '1';
				when 20 =>
					led <= "1100000000000000";
					flash_oe <= '0';
					flash_addr <= "000000" & pre_pc;
					flash_data <= (others => 'Z');
				when 30 =>
					led <= "1110000000000000";
					pre_data := flash_data;
					EN_ram1 <= '0';
					WE_ram1 <= '1';
					OE_ram1 <= '1';
					led <= pre_data + 10;
					data_ram1 <= pre_data;
					addr_ram1 <= "00" & pre_pc;
				when 35 =>
					led <= "1111000000000000";
					WE_ram1 <= '0';
				when 40 =>
					led <= "1111100000000000";
					WE_ram1 <= '1';
				when 45 =>
					led <= "1111110000000000";
					pre_pc := pre_pc + 1;
					led <= pre_pc;

					if (pre_pc = "0000000011111111") then
						pre_read <= '1';
					end if;
					--digit2 <= rst & "000000";
				when 50 =>


					me_wb := exme_wb;
					me_pc := exme_pc;
					me_op := exme_op;
					me_me := exme_me;
					me_rz := exme_rz;

					me_con := 0;
					if B_jump = '1' then
						if_pc := B_pc;
					elsif LW_jump = '1' then
						if_pc := LW_pc;
					elsif JR_jump = '1' then
						if_pc := JR_pc;
					else
						if_pc := ifid_pc;
					end if;
						EN_ram1 <= '0';
						addr_ram1 <= "00" & if_pc;
						data_ram1 <= "ZZZZZZZZZZZZZZZZ";
						OE_ram1 <= '0' AFTER 5ns;

				when 51 =>
				--when 52 =>
						OE_ram1 <= '1';
						led <= if_ins;
						ifid_pc <= if_pc + "1";


					ifid_ins <= data_ram1;

					case me_me is
						when 1 =>
							if exme_addr = "1011111100000000" then
								EN_ram1 <= '1';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
								rdn <= '1';
								wrn <= '1';
								data_ram1 <= "ZZZZZZZZZZZZZZZZ";
								me_con := 1;
							elsif exme_addr = "1011111100000001" then
								EN_ram1 <= '1';
								WE_ram1 <= '1';
								OE_ram1 <= '1';

								rdn <= '1';
								wrn <= '1';

								me_con := 5;
							else
								EN_ram1 <= '0';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
								rdn <= '1';
								wrn <= '1';

								data_ram1 <= "ZZZZZZZZZZZZZZZZ";
								addr_ram1 <= "00" & exme_addr;
								me_con := 2;
							end if;
						when 2 =>
							if exme_addr = "1011111100000000" then
								EN_ram1 <= '1';
								WE_ram1 <= '1';
								OE_ram1 <= '1';
								rdn <= '1';
								wrn <= '1';
								data_ram1 <= exme_res;
								me_con := 3;
							else
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


					case me_con is
						when 1 =>
							rdn <= '0' AFTER 5ns;
						when 2 =>
							OE_ram1 <= '0' AFTER 5ns;
						when 3 =>
							wrn <= '0' AFTER 5ns;
						when 4 =>
							WE_ram1 <= '0' AFTER 5ns;
						when others =>
					end case;
				when 52 =>
				--when 54 =>
					case me_con is
						when 1 =>
							data := "00000000" & data_ram1(7 downto 0);
							rdn <= '1';
						when 2 =>
							data := data_ram1;
							OE_ram1 <= '1';
						when 3 =>
							wrn <= '1';
						when 4 =>
							WE_ram1 <= '1';
						when 5 =>
							data := "00000000000000" & (data_ready) & (tbre and tsre);
						when others =>
					end case;

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
			end case;
		end if;

	end process;


	------------------------------ WB ------------------------------
	process(clk, rst)
	begin
		if (clk'event and clk = '1') then
			case state is
				when 50 =>
					if mewb_wb	 = '1' and mewb_op /=0 then
						case mewb_rz is
							when "0000000000000000" => r0 <= mewb_data;
							when "0000000000000001" => r1 <= mewb_data;
							when "0000000000000010" => r2 <= mewb_data;
							when "0000000000000011" => r3 <= mewb_data;
							when "0000000000000100" => r4 <= mewb_data;
							when "0000000000000101" => r5 <= mewb_data;
							when "0000000000000110" => r6 <= mewb_data;
							when "0000000000000111" => r7 <= mewb_data;
							when "1000000000000001" =>  T <= mewb_data;
							when "1000000000000010" => SP <= mewb_data;
							when "1000000000000011" => IH <= mewb_data;
							when others => -- do nothing
						end case;
					end if;


				when 51 =>

				when 52 =>

				when 53 =>

				when 54 =>

				when others =>
					--	do nothing
			end case;
		end if;
		--state <= wb_state;
	end process;

	---------------------------------- DEBUG --------------------------------
	process(clk, state, rst)
	begin
		if (clk'event and clk = '1') then
			if (state = 49 and pre_read = '0') then --or rst = '0'  then
				state <= 0;
			elsif (state = 52 and pre_read = '1') then
				state <= 50;
			else
				state <= state + 1;
			end if;
		end if;
		case state is
			when 0 => digit1<="0111111";
			when 10 => digit1<="0000110";
			when 20 => digit1<="1011011";
			when 30 => digit1<="1001111";
			when 40 => digit1<="1100110";
			when 50 => digit2<="0111111";
			when 51 => digit2<="0000110";
			when 52 => digit2<="1011011";
			when 53 => digit2<="1001111";
			when 54 => digit2<="1100110";
			when others=>--digit2<="0000000";
		end case;
		digit2 <= rst & "000000";
	end process;

	process(clk_50m)
	begin
		clk <= clk_50m;
	end process;

	process(clk_11m)
	begin
		--clk <= clk_11m;
	end process;

	process(clk)
	begin
		--if (clk2'event and clk2 = '1') then
			--clk <= not clk;
		--end if;
	end process;

	process(clk_single)
	begin
		--digit1 <= "000000" & clk_single;
		--digit2 <= "000000" & pre_read;
		--clk <= clk_single;
	end process;
end behavioral;
