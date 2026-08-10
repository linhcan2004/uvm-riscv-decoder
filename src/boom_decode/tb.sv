`include "uvm_macros.svh"
import uvm_pkg::*;
import package_decode::*;
import decode_table_package::*;

module tb;
  reg clk;

  always #10 clk =~ clk;
  decode_if _if (clk);

        DecodeUnit u0(
    // ENQ bundle: inputs to decoder
        .io_enq_uop_inst            (_if.instr),
        .io_enq_uop_debug_inst      (_if.true_random_instr),  // bypass in
        .io_enq_uop_is_rvc          (1'b0),                    // tie low (not in interface)
        .io_enq_uop_is_sfb          (_if.io_enq_uop_is_sfb),
        .io_enq_uop_ftq_idx         (6'b0),                    // tie low
        .io_enq_uop_edge_inst       (1'b0),                    // tie low
        .io_enq_uop_pc_lob          (6'b0),                    // tie low
        .io_enq_uop_taken           (1'b0),                    // tie low
        .io_enq_uop_xcpt_pf_if      (_if.io_enq_uop_xcpt_pf_if),
        .io_enq_uop_xcpt_ae_if      (_if.io_enq_uop_xcpt_ae_if),
        .io_enq_uop_bp_debug_if     (_if.io_enq_uop_bp_debug_if),
        .io_enq_uop_bp_xcpt_if      (_if.io_enq_uop_bp_xcpt_if),
        .io_enq_uop_debug_fsrc      (2'b0),                    // tie low
        // CSR decode inputs
        .io_csr_decode_fp_illegal     (_if.io_csr_decode_fp_illegal),
        .io_csr_decode_read_illegal   (_if.io_csr_decode_read_illegal),
        .io_csr_decode_write_illegal  (_if.io_csr_decode_write_illegal),
        .io_csr_decode_write_flush    (_if.io_csr_decode_write_flush),
        .io_csr_decode_system_illegal (_if.io_csr_decode_system_illegal),
        // Interrupt inputs
        .io_interrupt               (_if.io_interrupt),
        .io_interrupt_cause         (_if.io_interrupt_cause),
        // DEQ bundle: decoded outputs
        .io_deq_uop_uopc            (_if.uopc),
        .io_deq_uop_debug_inst      (_if.out_instr),           // bypass out
        .io_deq_uop_is_rvc          (),                        // bypass, unused
        .io_deq_uop_iq_type         (_if.iq_type),
        .io_deq_uop_fu_code         (_if.fu_code),
        .io_deq_uop_is_br           (_if.is_br),
        .io_deq_uop_is_jalr         (_if.is_jalr),
        .io_deq_uop_is_jal          (_if.is_jal),
        .io_deq_uop_is_sfb          (_if.io_deq_uop_is_sfb),   // bypass
        .io_deq_uop_ftq_idx         (),                        // bypass, unused
        .io_deq_uop_edge_inst       (),                        // bypass, unused
        .io_deq_uop_pc_lob          (),                        // bypass, unused
        .io_deq_uop_taken           (),                        // bypass, unused
        .io_deq_uop_imm_packed      (_if.imm_packed),
        .io_deq_uop_exception       (_if.exception),
        .io_deq_uop_exc_cause       (_if.exc_cause),
        .io_deq_uop_bypassable      (_if.bypassable),
        .io_deq_uop_mem_cmd         (_if.mem_cmd),
        .io_deq_uop_mem_size        (_if.mem_size),
        .io_deq_uop_mem_signed      (_if.mem_signed),
        .io_deq_uop_is_fence        (_if.is_fence),
        .io_deq_uop_is_fencei       (_if.is_fencei),
        .io_deq_uop_is_amo          (_if.is_amo),
        .io_deq_uop_uses_ldq        (_if.uses_ldq),
        .io_deq_uop_uses_stq        (_if.uses_stq),
        .io_deq_uop_is_sys_pc2epc   (_if.is_sys_pc2epc),
        .io_deq_uop_is_unique       (_if.is_unique),
        .io_deq_uop_flush_on_commit (_if.flush_on_commit),
        .io_deq_uop_ldst_is_rs1     (_if.ldst_is_rs1),
        .io_deq_uop_ldst            (_if.ldst),
        .io_deq_uop_lrs1            (_if.lrs1),
        .io_deq_uop_lrs2            (_if.lrs2),
        .io_deq_uop_lrs3            (_if.lrs3),
        .io_deq_uop_ldst_val        (_if.ldst_val),
        .io_deq_uop_dst_rtype       (_if.dst_rtype),
        .io_deq_uop_lrs1_rtype      (_if.lrs1_rtype),
        .io_deq_uop_lrs2_rtype      (_if.lrs2_rtype),
        .io_deq_uop_frs3_en         (_if.frs3_en),
        .io_deq_uop_fp_val          (_if.fp_val),
        .io_deq_uop_debug_fsrc      (),                        // bypass, unused
        // CSR decode output (bypass of io_enq_uop_inst)
        .io_csr_decode_inst         ()                         // unused
    );

  initial begin
    clk <= 0;
    uvm_config_db#(virtual decode_if)::set(null, "uvm_test_top", "decode_if", _if);
    run_test("");
  end

  initial begin
    $shm_open("wave.shm");
    $shm_probe(tb, "ACS");
  end
endmodule

