package mctm_reg_pkg;
  //======================================================================
  // 说明：该package给出一个参考的RAL层次结构，解决mctm_warp场景下
  //      addr[10:8]选择4个MCTM实例的问题。
  //
  // 核心思想：
  //   1) 对“单个mctm”(原addr[8:0]空间)建立mctm_reg_block
  //   2) 对“wrap”(addr[10:0]空间)建立mctm_wrap_reg_block，内部包含4个
  //      mctm_reg_block实例
  //   3) 通过uvm_reg_map::add_submap()给每个子block分配不同base offset，
  //      从而用户调用RAL自带write/read时，自动访问到正确的实例地址窗口
  //
  // 注意：
  //   - 本文件为“可编译的参考骨架”，真实项目需根据RTL寄存器表补全寄存器/字段。
  //   - 假设APB为byte addressing，且寄存器offset按32bit对齐(0x0,0x4,...)。
  //     如果你的RTL使用word addressing或其他对齐方式，需要同步调整：
  //       * create_map的n_bytes/byte_addressing
  //       * adapter(reg2bus/bus2reg)对地址是否shift
  //       * RTL寄存器译码方式
  //======================================================================

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ------------------------------------------------------------
  // 通用16bit RW寄存器（示例）
  // ------------------------------------------------------------
  class mctm_rw16_reg extends uvm_reg;
    `uvm_object_utils(mctm_rw16_reg)

    // 中文注释：用一个16bit字段代表整个寄存器。
    uvm_reg_field value;

    function new(string name = "mctm_rw16_reg");
      super.new(name, 16, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      // 中文注释：
      // value.configure(parent,
      //                size, lsb_pos,
      //                access,
      //                volatile,
      //                reset,
      //                has_reset,
      //                is_rand,
      //                individually_accessible);
      value = uvm_reg_field::type_id::create("value");
      value.configure(this,
                      16, 0,
                      "RW",
                      0,
                      'h0,
                      1,
                      0,
                      0);
    endfunction
  endclass

  // ------------------------------------------------------------
  // 单个mctm寄存器模型（示例）
  // ------------------------------------------------------------
  class mctm_reg_block extends uvm_reg_block;
    `uvm_object_utils(mctm_reg_block)

    // 示例寄存器：CRR计数器/重装寄存器
    mctm_rw16_reg CRR;

    // 示例：6个比较寄存器 CH0CR..CH5CR
    mctm_rw16_reg CHxCR[6];

    function new(string name = "mctm_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      // 中文注释：
      // create_map(name, base_addr, n_bytes, endian, byte_addressing)
      // - base_addr：该block内相对基地址
      // - n_bytes ：总线一次传输的字节数(例如APB 32bit通常为4)
      // - byte_addressing=1表示map里的offset以byte为单位
      default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN, 1);

      // ----------------------------
      // 寄存器定义（占位示例）
      // ----------------------------
      // 中文注释：真实项目通常每个寄存器一个class以表达字段；这里用通用16bit RW寄存器示例。

      CRR = mctm_rw16_reg::type_id::create("CRR");
      CRR.configure(this, null, "");
      CRR.build();
      // 假设CRR offset=0x00
      default_map.add_reg(CRR, 'h00, "RW");

      foreach (CHxCR[i]) begin
        CHxCR[i] = mctm_rw16_reg::type_id::create($sformatf("CH%0dCR", i));
        CHxCR[i].configure(this, null, "");
        CHxCR[i].build();
        // 假设CH0CR..CH5CR从0x10开始，每个+0x04（仅示例）
        default_map.add_reg(CHxCR[i], ('h10 + i*'h04), "RW");
      end

      // 中文注释：build完成后锁定模型，防止后续误修改
      lock_model();
    endfunction
  endclass

  // ------------------------------------------------------------
  // 顶层wrap寄存器模型（4个mctm子block）
  // ------------------------------------------------------------
  class mctm_wrap_reg_block extends uvm_reg_block;
    `uvm_object_utils(mctm_wrap_reg_block)

    // 中文注释：4个实例的寄存器模型
    mctm_reg_block mctm_rm[4];

    function new(string name = "mctm_wrap_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      // 中文注释：wrap对外地址扩展为11bit，所以空间大小为2^11=2048（按byte addressing即0x000~0x7FF）
      default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN, 1);

      foreach (mctm_rm[i]) begin
        // 中文注释：每个子block独立建模，offset保持原9bit空间(0x000~0x1FF)
        mctm_rm[i] = mctm_reg_block::type_id::create($sformatf("mctm_rm%0d", i));
        mctm_rm[i].configure(this);
        mctm_rm[i].build();

        // 中文注释：关键点——submap base offset = i * 0x200
        // 解释：子地址是9bit(0x000~0x1FF)，因此每个instance占用0x200窗口。
        default_map.add_submap(mctm_rm[i].default_map, (i * 'h200));
      end

      lock_model();
    endfunction
  endclass

endpackage
