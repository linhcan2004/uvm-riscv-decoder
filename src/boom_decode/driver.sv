class driver extends uvm_driver #(item);
    `uvm_component_utils(driver)

    function new(string name = "driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual decode_if vif;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual decode_if)::get(this, "", "decode_if", vif))
            `uvm_fatal("DRV", "Could not get virtual decode_if")
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            item m_item;
            `uvm_info("DRV", "Waiting for item from sequencer", UVM_HIGH)
            seq_item_port.get_next_item(m_item);
            drive_item(m_item);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_item(item m_item);
        @(vif.cb);

        // Drive main instruction and debug bypass
        vif.cb.instr              <= m_item.instr;
        vif.cb.true_random_instr  <= m_item.true_random_instr;

        // Drive SFB control
        vif.cb.io_enq_uop_is_sfb  <= m_item.io_enq_uop_is_sfb;

        // Drive interrupt
        vif.cb.io_interrupt_cause <= m_item.io_interrupt_cause;
        vif.cb.io_interrupt       <= m_item.io_interrupt;

        // Drive CSR decode
        vif.cb.io_csr_decode_fp_illegal     <= m_item.io_csr_decode_fp_illegal;
        vif.cb.io_csr_decode_read_illegal   <= m_item.io_csr_decode_read_illegal;
        vif.cb.io_csr_decode_write_illegal  <= m_item.io_csr_decode_write_illegal;
        vif.cb.io_csr_decode_write_flush    <= m_item.io_csr_decode_write_flush;
        vif.cb.io_csr_decode_system_illegal <= m_item.io_csr_decode_system_illegal;

        // Drive exception inputs
        vif.cb.io_enq_uop_xcpt_pf_if  <= m_item.io_enq_uop_xcpt_pf_if;
        vif.cb.io_enq_uop_xcpt_ae_if  <= m_item.io_enq_uop_xcpt_ae_if;
        vif.cb.io_enq_uop_bp_debug_if <= m_item.io_enq_uop_bp_debug_if;
        vif.cb.io_enq_uop_bp_xcpt_if  <= m_item.io_enq_uop_bp_xcpt_if;
    endtask
endclass

