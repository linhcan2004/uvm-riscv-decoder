package package_decode;

    // convert to string
    function string convert2str(bit a);
        return $sformatf("Instruction=%0d", a);
    endfunction

    // localparam
        // Short forward branch active?
        localparam IS_SFB_ACTIVE = 1; // choose between 0 and 1
        // number of generated instruction
        localparam MIN_NUM = 10000;
        localparam MAX_NUM = 10000;
        // extension
        localparam RV32I         = 0;
        localparam RV64I         = 1;
        localparam RV32M         = 2;
        localparam RV64M         = 3;
        localparam RV32A         = 4;
        localparam RV64A         = 5;
        // RV32 Types
        localparam RV32I_RType = 0;
        localparam RV32I_IType = 1;
        localparam RV32I_SType = 2;
        localparam RV32I_BType = 3;
        localparam RV32I_UType = 4;
        localparam RV32I_JType = 5;
        // RV64 Types
        localparam RV64I_RType = 0;
        localparam RV64I_IType = 1;
        localparam RV64I_SType = 2;
        localparam RV64I_RType_I = 0;
        localparam RV64I_RType_W = 1;

endpackage

