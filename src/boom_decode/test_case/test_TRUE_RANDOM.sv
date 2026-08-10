class test_TRUE_RANDOM extends base_test;
  `uvm_component_utils(test_TRUE_RANDOM)
  function new(string name="test_TRUE_RANDOM", uvm_component parent=null);
    super.new(name, parent);
  endfunction
 
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seq.randomize() with {
        num inside {[MIN_NUM:MAX_NUM]};
    };
 
  endfunction
endclass
