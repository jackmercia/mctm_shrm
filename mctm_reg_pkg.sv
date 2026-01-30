package mctm_reg_pkg;
  // 说明：该package给出一个参考的RAL层次结构。
  // - mctm_reg_block: 单个MCTM实例(原9bit地址空间)的寄存器模型
  // - mctm_wrap_reg_block: 顶层wrap(11bit地址空间)包含4个子block，通过submap实现addr[10:8]选择
  // 注意：该代码为示例骨架，具体寄存器/偏移需要根据RTL寄存器表补全。

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ----------------------------
  // 单个mctm寄存器模型（示例）
  // ----------------------------
  class mctm_reg_block extends uvm_reg_block;
    `uvm_object_utils(mctm_reg_block)

    // 示例寄存器：CRR计数器/重装寄存器
    uvm_reg CRR;

    // 示例：6个比较寄存器
    uvm_reg CHxCR[6];

    function new(string name = "mctm_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      // 重要：create_map参数要与APB VIP/adapter一致。
      // 这里假设：byte addressing，little endian。
      default_map = create_map("default_map", 'h0, 1, UVM_LITTLE_ENDIAN, 1);

      // ----------------------------
      // 寄存器定义（占位示例）
      // ----------------------------
      // 中文注释：这里用简单的uvm_reg示例，真实项目建议使用uvm_reg_field定义字段

      CRR = uvm_reg::type_id::create("CRR",,get_full_name());
      CRR.configure(this, 16, "RW", 0);
      // 假设CRR offset=0x00
      default_map.add_reg(CRR, 'h00, "RW");

      foreach (CHxCR[i]) begin
        CHxCR[i] = uvm_reg::type_id::create($sformatf("CH%0dCR", i),,get_full_name());
        CHxCR[i].configure(this, 16, "RW", 0);
        // 假设CH0CR..CH5CR从0x10开始，每个+0x04（仅示例）
        default_map.add_reg(CHxCR[i], 'h10 + i*'h04, "RW");
      end

    endfunction
  endclass

  // ----------------------------------------
  // 顶层wrap寄存器模型（4个mctm子block）
  // ----------------------------------------
  class mctm_wrap_reg_block extends uvm_reg_block;
    `uvm_object_utils(mctm_wrap_reg_block)

    mctm_reg_block mctm_rm[4];

    function new(string name = "mctm_wrap_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      // 中文注释：wrap对外地址扩展为11bit，所以这里的map覆盖0x000~0x7FF
      // 仍然使用byte addressing示例。
      default_map = create_map("default_map", 'h0, 1, UVM_LITTLE_ENDIAN, 1);

      foreach (mctm_rm[i]) begin
        // 中文注释：每个子block独立建模，offset保持原9bit空间
        mctm_rm[i] = mctm_reg_block::type_id::create($sformatf("mctm_rm%0d", i),,get_full_name());
        mctm_rm[i].configure(this);
        mctm_rm[i].build();
        mctm_rm[i].lock_model();

        // 中文注释：关键点——submap base offset = i * 0x200
        // 由于子地址是9bit(0x000~0x1FF)，所以每个instance占用0x200窗口。
        default_map.add_submap(mctm_rm[i].default_map, i * 'h200);
      end
    endfunction
  endclass

endpackage
