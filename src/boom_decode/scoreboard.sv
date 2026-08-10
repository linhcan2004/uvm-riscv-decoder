import decode_table_package::*;

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    uvm_analysis_imp #(item, scoreboard) m_analysis_imp;
    int unsigned pass_cnt;
    int unsigned fail_cnt;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_analysis_imp = new("m_analysis_imp", this);
    endfunction

    // ------------------------------------------------------------------
    // imm_packed golden model:
    //   [19:13] = inst[31:25]
    //   [12:8]  = inst[24:20]  (IS_I / IS_U / IS_J)
    //           = inst[11:7]   (IS_S / IS_B)
    //   [7:0]   = inst[19:12]
    // ------------------------------------------------------------------
    virtual function bit [19:0] golden_imm(bit [31:0] instr, bit [2:0] imm_sel);
        bit [4:0] mid;
        case (imm_sel)
            IS_I, IS_U, IS_J : mid = instr[24:20];
            IS_S, IS_B       : mid = instr[11:7];
            default           : mid = 5'bx;
        endcase
        return {instr[31:25], mid, instr[19:12]};
    endfunction

    // ------------------------------------------------------------------
    // GOLDEN MODEL -> maps instruction bits -> decode_ctrl_sig_s
    // Returns 1 if recognized, 0 if not yet in table.
    // ------------------------------------------------------------------
    virtual function bit golden_ctrl(bit [31:0] instr, output decode_ctrl_sig_s sig);
        bit [6:0] opcode = instr[6:0];
        bit [2:0] funct3 = instr[14:12];
        bit [6:0] funct7 = instr[31:25];
        bit [4:0] funct5 = instr[31:27]; // for AMO

        unique case (opcode)

            // LOAD (I-type)
            7'b0000011: begin
                unique case (funct3)
                    3'b000: begin sig = LB_struct;  return 1; end
                    3'b001: begin sig = LH_struct;  return 1; end
                    3'b010: begin sig = LW_struct;  return 1; end
                    3'b011: begin sig = LD_struct;  return 1; end // RV64
                    3'b100: begin sig = LBU_struct; return 1; end
                    3'b101: begin sig = LHU_struct; return 1; end
                    3'b110: begin sig = LWU_struct; return 1; end // RV64
                    default: return 0;
                endcase
            end

            7'b0001111: begin // MISC-MEM
                if (funct3 == 3'b000) begin sig = FENCE_struct;  return 1; end
                else                  begin sig = FENCEI_struct; return 1; end
            end

            // STORE (S-type)
            7'b0100011: begin
                unique case (funct3)
                    3'b000: begin sig = SB_struct; return 1; end
                    3'b001: begin sig = SH_struct; return 1; end
                    3'b010: begin sig = SW_struct; return 1; end
                    3'b011: begin sig = SD_struct; return 1; end // RV64
                    default: return 0;
                endcase
            end

            // OP-IMM: non-shift (I-type, ADDI/SLTI/SLTIU/XORI/ORI/ANDI)
            // shift-style (SLLI/SRLI/SRAI -> treated as opcode=0010011)
            7'b0010011: begin
                unique case (funct3)
                    3'b000: begin sig = ADDI_struct;  return 1; end
                    3'b010: begin sig = SLTI_struct;  return 1; end
                    3'b011: begin sig = SLTIU_struct; return 1; end
                    3'b100: begin sig = XORI_struct;  return 1; end
                    3'b110: begin sig = ORI_struct;   return 1; end
                    3'b111: begin sig = ANDI_struct;  return 1; end
                    3'b001: begin sig = SLLI_struct;  return 1; end // SLLI (funct7=000000x)
                    3'b101: begin
                        if (funct7[6:1] == 6'b000000) begin sig = SRLI_struct; return 1; end
                        if (funct7[6:1] == 6'b010000) begin sig = SRAI_struct; return 1; end
                        return 0;
                    end
                    default: return 0;
                endcase
            end

            // OP (R-type, opcode=0110011)
            7'b0110011: begin
                if (funct7 == 7'b0000001) begin  // M extension
                    unique case (funct3)
                        3'b000: begin sig = MUL_struct;    return 1; end
                        3'b001: begin sig = MULH_struct;   return 1; end
                        3'b010: begin sig = MULHSU_struct; return 1; end
                        3'b011: begin sig = MULHU_struct;  return 1; end
                        3'b100: begin sig = DIV_struct;    return 1; end
                        3'b101: begin sig = DIVU_struct;   return 1; end
                        3'b110: begin sig = REM_struct;    return 1; end
                        3'b111: begin sig = REMU_struct;   return 1; end
                        default: return 0;
                    endcase
                end else begin                      // Base integer ALU
                    unique case (funct3)
                        3'b000: begin
                            if (funct7 == 7'b0000000) begin sig = ADD_struct; return 1; end
                            if (funct7 == 7'b0100000) begin sig = SUB_struct; return 1; end
                            return 0;
                        end
                        3'b001: begin sig = SLL_struct;  return 1; end
                        3'b010: begin sig = SLT_struct;  return 1; end
                        3'b011: begin sig = SLTU_struct; return 1; end
                        3'b100: begin
                            if (funct7 == 7'b0000000) begin sig = XOR_struct; return 1; end
                            return 0;
                        end
                        3'b101: begin
                            if (funct7 == 7'b0000000) begin sig = SRL_struct; return 1; end
                            if (funct7 == 7'b0100000) begin sig = SRA_struct; return 1; end
                            return 0;
                        end
                        3'b110: begin sig = OR_struct;  return 1; end
                        3'b111: begin sig = AND_struct; return 1; end
                        default: return 0;
                    endcase
                end
            end

            // BRANCH (B-type)
            7'b1100011: begin
                unique case (funct3)
                    3'b000: begin sig = BEQ_struct;  return 1; end
                    3'b001: begin sig = BNE_struct;  return 1; end
                    3'b100: begin sig = BLT_struct;  return 1; end
                    3'b101: begin sig = BGE_struct;  return 1; end
                    3'b110: begin sig = BLTU_struct; return 1; end
                    3'b111: begin sig = BGEU_struct; return 1; end
                    default: return 0;
                endcase
            end

            // JAL / JALR / LUI / AUIPC
            7'b1101111: begin sig = JAL_struct;   return 1; end
            7'b1100111: begin
                if (funct3 == 3'b000) begin
                    sig = JALR_struct;
                    return 1;
                end
                return 0;
            end
            7'b0110111: begin sig = LUI_struct;   return 1; end
            7'b0010111: begin sig = AUIPC_struct; return 1; end

            // SYSTEM / CSR (opcode=1110011)
            7'b1110011: begin
                unique case (funct3)
                    3'b001: begin sig = CSRRW_struct;  return 1; end
                    3'b010: begin sig = CSRRS_struct;  return 1; end
                    3'b011: begin sig = CSRRC_struct;  return 1; end
                    3'b101: begin sig = CSRRWI_struct; return 1; end
                    3'b110: begin sig = CSRRSI_struct; return 1; end
                    3'b111: begin sig = CSRRCI_struct; return 1; end
                    default: return 0;
                endcase
            end

            // RV64I: OP-IMM-32 (opcode=0011011)
            7'b0011011: begin
                unique case (funct3)
                    3'b000: begin sig = ADDIW_struct; return 1; end
                    3'b001: begin sig = SLLIW_struct; return 1; end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            sig = SRLIW_struct;
                            return 1;
                        end
                        if (funct7 == 7'b0100000) begin
                            sig = SRAIW_struct;
                            return 1;
                        end
                        return 0;
                    end
                    default: return 0;
                endcase
            end

            // RV64I: OP-32 (opcode=0111011)
            7'b0111011: begin
                if (funct7 == 7'b0000001) begin  // RV64M
                    unique case (funct3)
                        3'b000: begin sig = MULW_struct;  return 1; end
                        3'b100: begin sig = DIVW_struct;  return 1; end
                        3'b101: begin sig = DIVUW_struct; return 1; end
                        3'b110: begin sig = REMW_struct;  return 1; end
                        3'b111: begin sig = REMUW_struct; return 1; end
                        default: return 0;
                    endcase
                end else begin
                    unique case (funct3)
                        3'b000: begin
                            if (funct7 == 7'b0000000) begin sig = ADDW_struct; return 1; end
                            if (funct7 == 7'b0100000) begin sig = SUBW_struct; return 1; end
                            return 0;
                        end
                        3'b001: begin sig = SLLW_struct; return 1; end
                        3'b101: begin
                            if (funct7 == 7'b0000000) begin sig = SRLW_struct; return 1; end
                            if (funct7 == 7'b0100000) begin sig = SRAW_struct; return 1; end
                            return 0;
                        end
                        default: return 0;
                    endcase
                end
            end

            // A extension (AMO, opcode=0101111)
            7'b0101111: begin
                unique case (funct3)
                    3'b010: begin  // RV32A (word)
                        unique case (funct5)
                            5'b00010: begin sig = LR_W_struct;      return 1; end
                            5'b00011: begin sig = SC_W_struct;      return 1; end
                            5'b00001: begin sig = AMOSWAP_W_struct; return 1; end
                            5'b00000: begin sig = AMOADD_W_struct;  return 1; end
                            5'b00100: begin sig = AMOXOR_W_struct;  return 1; end
                            5'b01100: begin sig = AMOAND_W_struct;  return 1; end
                            5'b01000: begin sig = AMOOR_W_struct;   return 1; end
                            5'b10000: begin sig = AMOMIN_W_struct;  return 1; end
                            5'b10100: begin sig = AMOMAX_W_struct;  return 1; end
                            5'b11000: begin sig = AMOMINU_W_struct; return 1; end
                            5'b11100: begin sig = AMOMAXU_W_struct; return 1; end
                            default:  return 0;
                        endcase
                    end
                    3'b011: begin  // RV64A (doubleword)
                        unique case (funct5)
                            5'b00010: begin sig = LR_D_struct;      return 1; end
                            5'b00011: begin sig = SC_D_struct;      return 1; end
                            5'b00001: begin sig = AMOSWAP_D_struct; return 1; end
                            5'b00000: begin sig = AMOADD_D_struct;  return 1; end
                            5'b00100: begin sig = AMOXOR_D_struct;  return 1; end
                            5'b01100: begin sig = AMOAND_D_struct;  return 1; end
                            5'b01000: begin sig = AMOOR_D_struct;   return 1; end
                            5'b10000: begin sig = AMOMIN_D_struct;  return 1; end
                            5'b10100: begin sig = AMOMAX_D_struct;  return 1; end
                            5'b11000: begin sig = AMOMINU_D_struct; return 1; end
                            5'b11100: begin sig = AMOMAXU_D_struct; return 1; end
                            default:  return 0;
                        endcase
                    end
                    default: return 0;
                endcase
            end

            default: return 0;
        endcase
    endfunction

    // WRITE -> called per clock by monitor via TLM port
    virtual function void write(item t);
        decode_ctrl_sig_s exp;
        bit [19:0] exp_imm;
        bit err = 0;
        bit [6:0] exp_uopc;
        bit [9:0] exp_fu_code;
        bit [1:0] exp_lrs2_rtype;
        bit [4:0] exp_mem_cmd;
        bit       exp_flush_on_commit;
        bit       exp_is_unique;
        bit [5:0] exp_lrs1;
        bit [5:0] exp_lrs2;
        bit       exp_ldst_is_rs1;

        if (!golden_ctrl(t.instr, exp)) begin
            `uvm_info("SCBD", $sformatf("instr=0x%08h opcode=%07b not in table, skip", t.instr, t.instr[6:0]), UVM_MEDIUM)
            return;
        end

        exp_uopc              = exp.uopc;
        exp_fu_code            = exp.fu_code;
        exp_lrs2_rtype         = exp.rs2_type;
        exp_mem_cmd            = exp.mem_cmd;
        exp_flush_on_commit    = exp.flush_on_commit;
        exp_is_unique          = exp.inst_unique;
        exp_lrs1               = t.instr[19:15];
        exp_lrs2               = t.instr[24:20];
        exp_ldst_is_rs1        = t.io_enq_uop_is_sfb;

        // SHORT FORWARD BRANCH OVERRIDES
        if (exp.is_br && t.io_enq_uop_is_sfb) begin
            exp_fu_code       = FU_JMP;
            exp_ldst_is_rs1   = 1'b0;
        end else if (t.io_enq_uop_is_sfb && exp.uopc == uopADD && t.instr[19:15] == 5'd0) begin
            exp_uopc          = uopMOV;
            exp_lrs1          = t.instr[11:7]; //RD -> lrs1
            exp_ldst_is_rs1   = 1'b1;
        end

        if (t.io_enq_uop_is_sfb && exp.rs2_type == RT_X) begin
            exp_lrs2_rtype    = RT_FIX;
            exp_lrs2          = t.instr[11:7]; // lưu rd vào rs2 (rs2 <- rd)
            exp_ldst_is_rs1   = 1'b0;
        end

        // CSR FLUSH OVERRIDES
        if (exp.fu_code == FU_CSR && t.io_csr_decode_write_flush && (exp.uopc == uopCSRRW || exp.uopc == uopCSRRS || exp.uopc == uopCSRRC)) begin
            exp_flush_on_commit = 1'b1;
            exp_is_unique       = 1'b1;
        end

        exp_imm = golden_imm(t.instr, exp.imm_sel);

        `uvm_info( "SCBD", $sformatf("CHK 0x%08h uopc(dut=%0d exp=%0d) iq=%0d fu=%0d sfb=%0b", t.instr, t.uopc, exp_uopc, t.iq_type, t.fu_code, t.io_enq_uop_is_sfb), UVM_LOW)

        if (t.uopc !== exp_uopc)                begin `uvm_error("SCBD", $sformatf("uopc FAIL instr=0x%08h dut=%0d exp=%0d",         t.instr, t.uopc, exp_uopc));           err=1; end
        if (t.iq_type !== exp.iq_type)          begin `uvm_error("SCBD", $sformatf("iq_type FAIL instr=0x%08h dut=%0d exp=%0d",       t.instr, t.iq_type, exp.iq_type));    err=1; end
        if (t.fu_code !== exp_fu_code)          begin `uvm_error("SCBD", $sformatf("fu_code FAIL instr=0x%08h dut=%0d exp=%0d",       t.instr, t.fu_code, exp_fu_code));    err=1; end

        if (!exp.is_br || !t.io_enq_uop_is_sfb) begin
            if (t.dst_rtype !== exp.dst_type) begin `uvm_error("SCBD", $sformatf("dst_rtype FAIL instr=0x%08h dut=%0d exp=%0d",       t.instr, t.dst_rtype, exp.dst_type)); err=1; end
        end
        if (t.lrs1_rtype !== exp.rs1_type)      begin `uvm_error("SCBD", $sformatf("lrs1_rtype FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr, t.lrs1_rtype, exp.rs1_type)); err=1; end
        if (t.lrs2_rtype !== exp_lrs2_rtype)    begin `uvm_error("SCBD", $sformatf("lrs2_rtype FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr, t.lrs2_rtype, exp_lrs2_rtype)); err=1; end
        if (t.mem_cmd    !== exp_mem_cmd)       begin `uvm_error("SCBD", $sformatf("mem_cmd    FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr, t.mem_cmd, exp_mem_cmd));     err=1; end
        if (t.uses_ldq   !== exp.uses_ldq)      begin `uvm_error("SCBD", $sformatf("uses_ldq   FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.uses_ldq,exp.uses_ldq));    err=1; end
        if (t.uses_stq   !== exp.uses_stq)      begin `uvm_error("SCBD", $sformatf("uses_stq   FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.uses_stq,exp.uses_stq));    err=1; end
        if (t.is_fence   !== exp.is_fence)      begin `uvm_error("SCBD", $sformatf("is_fence   FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.is_fence,exp.is_fence));    err=1; end
        if (t.is_fencei  !== exp.is_fencei)     begin `uvm_error("SCBD", $sformatf("is_fencei  FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.is_fencei,exp.is_fencei)); err=1; end
        if (t.is_amo     !== exp.is_amo)        begin `uvm_error("SCBD", $sformatf("is_amo     FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.is_amo,exp.is_amo));       err=1; end
        if (t.is_br      !== exp.is_br)         begin `uvm_error("SCBD", $sformatf("is_br      FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.is_br,exp.is_br));         err=1; end
        if (t.bypassable !== exp.bypassable)    begin `uvm_error("SCBD", $sformatf("bypassable FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.bypassable,exp.bypassable)); err=1; end
        if (t.fp_val     !== exp.fp_val)        begin `uvm_error("SCBD", $sformatf("fp_val     FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr,t.fp_val,exp.fp_val));       err=1; end
        if (t.flush_on_commit !== exp_flush_on_commit) begin `uvm_error("SCBD", $sformatf("flush_on_commit FAIL instr=0x%08h dut=%0d exp=%0d", t.instr,t.flush_on_commit,exp_flush_on_commit)); err=1; end
        if (t.is_unique  !== exp_is_unique)begin `uvm_error("SCBD", $sformatf("is_unique  FAIL instr=0x%08h dut=%0d exp=%0d",         t.instr,t.is_unique,exp_is_unique)); err=1; end

        // immediate packing
        if (exp.imm_sel !== IS_X)   // skip if imm is don't-care
            if (t.imm_packed !== exp_imm)   begin `uvm_error("SCBD", $sformatf("imm_packed FAIL instr=0x%08h dut=0x%05h exp=0x%05h", t.instr,t.imm_packed,exp_imm)); err=1; end

        // Kiểm tra giá trị thực của luồng dữ liệu
        if (t.lrs1 !== exp_lrs1)                begin `uvm_error("SCBD", $sformatf("lrs1       FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr, t.lrs1, exp_lrs1));         err=1; end
        if (t.lrs2 !== exp_lrs2)                begin `uvm_error("SCBD", $sformatf("lrs2       FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr, t.lrs2, exp_lrs2));         err=1; end
        if (t.ldst_is_rs1 !== exp_ldst_is_rs1) begin `uvm_error("SCBD", $sformatf("ldst_is_rs1 FAIL instr=0x%08h dut=%0d exp=%0d",     t.instr, t.ldst_is_rs1, exp_ldst_is_rs1)); err=1; end

        if (err) fail_cnt++;
        else begin
            pass_cnt++;
            `uvm_info("SCBD", $sformatf("PASS 0x%08h", t.instr), UVM_HIGH)
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCBD",
            $sformatf("--- RESULT: PASS=%0d  FAIL=%0d ---", pass_cnt, fail_cnt), UVM_NONE)
    endfunction

endclass

