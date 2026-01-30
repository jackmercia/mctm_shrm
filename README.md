# mctm_wrap UVM RAL mapping example

This repository provides a reference UVM RAL modeling pattern for an APB wrapper (`mctm_wrap`) that contains 4 identical `mctm` instances.

Key idea: use `uvm_reg_block` hierarchy + `add_submap()` so `uvm_reg::write/read` automatically generates the correct 11-bit APB address with `addr[10:8]` selecting the target instance.
