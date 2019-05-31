
YOSYS       = $(YOSYS_ROOT)/yosys
YOSYS_SMTBMC= $(YOSYS_ROOT)/yosys-smtbmc

ALL_TARGETS = 

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
        -p "synth -top ${3}" \
        -p "tee -o ${1}.rpt stat" \
        -p "write_verilog ${1}" 
synth_${3} : ${1}
ALL_TARGETS += ${1}
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

endef

P_ADDSUB_RTL   = rtl/p_addsub/p_addsub.v
P_ADDSUB_VERIF = rtl/p_addsub/p_addsub_ftb.v

$(eval $(call add_targets,$(P_ADDSUB_RTL),$(P_ADDSUB_VERIF),p_addsub))

B_BOP_RTL   = rtl/b_bop/b_bop.v
B_BOP_VERIF = rtl/b_bop/b_bop_ftb.v

$(eval $(call add_targets,$(B_BOP_RTL),$(B_BOP_VERIF),b_bop))

XC_SHA3_RTL   = rtl/xc_sha3/xc_sha3.v
XC_SHA3_VERIF = rtl/xc_sha3/xc_sha3_ftb.v

$(eval $(call add_targets,$(XC_SHA3_RTL),$(XC_SHA3_VERIF),xc_sha3))


all: $(ALL_TARGETS)

