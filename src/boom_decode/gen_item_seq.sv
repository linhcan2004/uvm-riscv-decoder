class gen_item_seq extends uvm_sequence;
    `uvm_object_utils(gen_item_seq)

    function new(string name = "gen_item_seq");
        super.new(name);
    endfunction

    rand int num;              // Total number of items to generate
    rand int select_extension; // Which ISA extension to test

    constraint c_num { soft num inside {[10:50]}; }
    constraint c_ext { select_extension inside {RV32I, RV64I, RV32M, RV64M, RV32A, RV64A}; }

    virtual task body();
        for (int i = 0; i < num; i++) begin
            item m_item = item::type_id::create("m_item");
            start_item(m_item);
            if (!m_item.randomize() with { extension == 4'(local::select_extension); })
                `uvm_fatal("SEQ", "Randomization failed!")
            `uvm_info("SEQ", $sformatf("[%0d/%0d] instr=0x%08h ext=%0d",
                      i+1, num, m_item.instr, m_item.extension), UVM_HIGH)
            finish_item(m_item);
        end
        `uvm_info("SEQ", $sformatf("Done: %0d items, ext=%0d", num, select_extension), UVM_LOW)
    endtask

endclass

