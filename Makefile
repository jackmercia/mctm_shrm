# Minimal Makefile for VCS compile sanity (example)
# Note: Real projects typically have much more structure.

VCS ?= vcs
VCS_OPTS += -full64 -sverilog -timescale=1ns/1ps
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -l vcs_compile.log

all: compile

compile:
	$(VCS) $(VCS_OPTS) mctm_reg_pkg.sv -o simv

clean:
	rm -rf simv simv.daidir csrc *.log *.key ucli.key DVEfiles verdiLog
