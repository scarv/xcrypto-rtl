
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

P_ADDSUB_RTL   = rtl/p_addsub/p_addsub.v
P_ADDSUB_VERIF = rtl/p_addsub/p_addsub_ftb.v
P_ADDSUB_SRC   = $(P_ADDSUB_VERIF) $(P_ADDSUB_RTL)
P_ADDSUB_SMT2  = build/p_addsub/p_addsub.smt2
P_ADDSUB_SYNTH = build/p_addsub/p_addsub.v
P_ADDSUB_VCD   = build/p_addsub/p_addsub.vcd

$(eval $(call tgt_smt2,$(P_ADDSUB_SMT2),$(P_ADDSUB_SRC),p_addsub_ftb))
$(eval $(call tgt_synth,$(P_ADDSUB_SYNTH),$(P_ADDSUB_SRC),p_addsub))
$(eval $(call tgt_bmc,p_addsub_ftb,$(P_ADDSUB_SMT2),$(P_ADDSUB_VCD)))
$(eval $(call tgt_cover,p_addsub_ftb,$(P_ADDSUB_SMT2),$(P_ADDSUB_VCD)))
$(eval $(call tgt_trace,p_addsub_ftb,$(P_ADDSUB_SMT2),$(P_ADDSUB_VCD)))

B_BOP_RTL   = rtl/b_bop/b_bop.v
B_BOP_VERIF = rtl/b_bop/b_bop_ftb.v
B_BOP_SRC   = $(B_BOP_VERIF) $(B_BOP_RTL)
B_BOP_SMT2  = build/b_bop/b_bop.smt2
B_BOP_SYNTH = build/b_bop/b_bop.v
B_BOP_VCD   = build/b_bop/b_bop.vcd

$(eval $(call tgt_smt2,$(B_BOP_SMT2),$(B_BOP_SRC),b_bop_ftb))
$(eval $(call tgt_synth,$(B_BOP_SYNTH),$(B_BOP_SRC),b_bop))
$(eval $(call tgt_bmc,b_bop_ftb,$(B_BOP_SMT2),$(B_BOP_VCD)))
$(eval $(call tgt_cover,b_bop_ftb,$(B_BOP_SMT2),$(B_BOP_VCD)))
$(eval $(call tgt_trace,b_bop_ftb,$(B_BOP_SMT2),$(B_BOP_VCD)))

XC_SHA3_RTL   = rtl/xc_sha3/xc_sha3.v
XC_SHA3_VERIF = rtl/xc_sha3/xc_sha3_ftb.v
XC_SHA3_SRC   = $(XC_SHA3_VERIF) $(XC_SHA3_RTL)
XC_SHA3_SMT2  = build/xc_sha3/xc_sha3.smt2
XC_SHA3_SYNTH = build/xc_sha3/xc_sha3.v
XC_SHA3_VCD   = build/xc_sha3/xc_sha3.vcd

$(eval $(call tgt_smt2,$(XC_SHA3_SMT2),$(XC_SHA3_SRC),xc_sha3_ftb))
$(eval $(call tgt_synth,$(XC_SHA3_SYNTH),$(XC_SHA3_SRC),xc_sha3))
$(eval $(call tgt_bmc,xc_sha3_ftb,$(XC_SHA3_SMT2),$(XC_SHA3_VCD)))
$(eval $(call tgt_cover,xc_sha3_ftb,$(XC_SHA3_SMT2),$(XC_SHA3_VCD)))
$(eval $(call tgt_trace,xc_sha3_ftb,$(XC_SHA3_SMT2),$(XC_SHA3_VCD)))

all: $(ALL_TARGETS)

