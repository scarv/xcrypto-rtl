
YOSYS       = $(YOSYS_ROOT)/yosys
YOSYS_SMTBMC= $(YOSYS_ROOT)/yosys-smtbmc

ALL_TARGETS = 
BMC_TARGETS = 
SYNTH_TARGETS = 

define tgt_smt2
${1} : ${2}
	@mkdir -p $(dir ${1})
	$(YOSYS) -qQT \
        -p "read_verilog -formal ${2}" \
        -p "prep -top ${3}" \
        -p "write_smt2 -wires ${1}" 
ALL_TARGETS += ${1}
endef

define tgt_synth
${1} : ${2}
	@mkdir -p $(dir ${1})
	$(YOSYS) -qQT \
        -p "read_verilog -formal ${2}" \
        -p "read_verilog -lib $(YOSYS_ROOT)/examples/cmos/cmos_cells.v" \
        -p "synth -top ${3}" \
        -p "dfflibmap -liberty $(YOSYS_ROOT)/techlibs/common/cells.lib" \
        -p "abc -liberty $(YOSYS_ROOT)/examples/cmos/cmos_cells.lib" \
        -p "tee -o ${1}.rpt stat" \
        -p "write_verilog ${1}" 
synth_${3} : ${1}
ALL_TARGETS += ${1}
SYNTH_TARGETS += ${1}
endef

define tgt_bmc
bmc_${1} : ${2} cov_${1}
	$(YOSYS_SMTBMC) \
        -t 5 \
        --dump-vcd ${3} \
        -s boolector \
        -m ${1} \
        ${2}
ALL_TARGETS += bmc_${1}
BMC_TARGETS += bmc_${1}
endef

define tgt_cover
cov_${1} : ${2}
	$(YOSYS_SMTBMC) \
        -t 5 -c \
        --dump-vcd ${3} \
        -s boolector \
        -m ${1} \
        ${2}
ALL_TARGETS += cov_${1}
endef

define tgt_trace
trs_${1} : ${2}
	$(YOSYS_SMTBMC) \
        -t 5 -g \
        --dump-vcd ${3} \
        -s boolector \
        -m ${1} \
        ${2}
ALL_TARGETS += trs_${1}
endef

define tgt_sim_build
${1} : ${2}
	@mkdir -p $(dir ${1})
	iverilog -g2012 -DWAVE_FILE=$(basename ${1}).vcd \
        -Wimplicit -Wselect-range -s ${3} -o ${1} ${2}
build_sim_${3} :  ${1}
ALL_TARGETS += ${1}
endef

define tgt_sim_run
${1} : ${2}
	vvp ${2}
run_sim_${3}: ${1}
endef


#
# Add a set of targets for a particular instruction
# 1 - RTL Source files
# 2 - Verification source files
# 3 - RTL top module name
define add_targets

$(eval $(call tgt_smt2,build/${3}/${3}.smt2,$1 $2,${3}_ftb))
$(eval $(call tgt_synth,build/${3}/${3}.v,$1 ,$3))
$(eval $(call tgt_bmc,${3}_ftb,build/${3}/${3}.smt2,build/${3}/${3}.vcd))
$(eval $(call tgt_cover,${3}_ftb,build/${3}/${3}.smt2,build/${3}/${3}.vcd))
$(eval $(call tgt_trace,${3}_ftb,build/${3}/${3}.smt2,build/${3}/${3}.vcd))

${3} : build/${3}/${3}.smt2 build/${3}/${3}.v bmc_${3}_ftb

endef

include rtl/b_bop/Makefile.in
include rtl/b_lut/Makefile.in
include rtl/p_addsub/Makefile.in
include rtl/p_mul/Makefile.in
include rtl/p_shfrot/Makefile.in
include rtl/xc_sha256/Makefile.in
include rtl/xc_sha3/Makefile.in
include rtl/xc_sha512/Makefile.in
include rtl/xc_aesmix/Makefile.in
include rtl/xc_aessub/Makefile.in
include rtl/xc_malu/Makefile.in
include rtl/xc_regfile/Makefile.in

all: $(ALL_TARGETS)

synth-all : $(SYNTH_TARGETS)

bmc-all : $(BMC_TARGETS)
