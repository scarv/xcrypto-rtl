
TARGETS = 

define tgt_smt2
${1} : ${2}
	@mkdir -p $(dir ${1})
	yosys -QT \
        -p "read_verilog -formal ${2}" \
        -p "prep -top ${3}" \
        -p "write_smt2 -wires ${1}" 
endef

define tgt_bmc
bmc_${1} : ${2} cov_${1}
	yosys-smtbmc \
        -t 5 \
        --dump-vcd ${3} \
        -s boolector \
        -m ${1} \
        ${2}
endef

define tgt_cover
cov_${1} : ${2}
	yosys-smtbmc \
        -t 5 -c \
        --dump-vcd ${3} \
        -s boolector \
        -m ${1} \
        ${2}
endef

define tgt_trace
trs_${1} : ${2}
	yosys-smtbmc \
        -t 5 -g \
        --dump-vcd ${3} \
        -s boolector \
        -m ${1} \
        ${2}
endef

P_ADDSUB_RTL   = rtl/p_addsub/p_addsub.v
P_ADDSUB_VERIF = verif/p_addsub/fml_p_addsub.v
P_ADDSUB_SRC   = $(P_ADDSUB_VERIF) $(P_ADDSUB_RTL)
P_ADDSUB_SMT2  = build/p_addsub/fml_p_addsub.smt2
P_ADDSUB_VCD   = build/p_addsub/fml_p_addsub.vcd

$(eval $(call tgt_smt2,$(P_ADDSUB_SMT2),$(P_ADDSUB_SRC),fml_p_addsub))
$(eval $(call tgt_bmc,fml_p_addsub,$(P_ADDSUB_SMT2),$(P_ADDSUB_VCD)))
$(eval $(call tgt_cover,fml_p_addsub,$(P_ADDSUB_SMT2),$(P_ADDSUB_VCD)))
$(eval $(call tgt_trace,fml_p_addsub,$(P_ADDSUB_SMT2),$(P_ADDSUB_VCD)))

TARGETS += $(P_ADDSUB_SMT2) bmc_fml_p_addsub


B_BOP_RTL   = rtl/b_bop/b_bop.v
B_BOP_VERIF = verif/b_bop/fml_b_bop.v
B_BOP_SRC   = $(B_BOP_VERIF) $(B_BOP_RTL)
B_BOP_SMT2  = build/b_bop/fml_b_bop.smt2
B_BOP_VCD   = build/b_bop/fml_b_bop.vcd

$(eval $(call tgt_smt2,$(B_BOP_SMT2),$(B_BOP_SRC),fml_b_bop))
$(eval $(call tgt_bmc,fml_b_bop,$(B_BOP_SMT2),$(B_BOP_VCD)))
$(eval $(call tgt_cover,fml_b_bop,$(B_BOP_SMT2),$(B_BOP_VCD)))
$(eval $(call tgt_trace,fml_b_bop,$(B_BOP_SMT2),$(B_BOP_VCD)))

TARGETS += $(B_BOP_SMT2) bmc_fml_b_bop

XC_SHA3_RTL   = rtl/xc_sha3/xc_sha3.v
XC_SHA3_VERIF = verif/xc_sha3/fml_xc_sha3.v
XC_SHA3_SRC   = $(XC_SHA3_VERIF) $(XC_SHA3_RTL)
XC_SHA3_SMT2  = build/xc_sha3/fml_xc_sha3.smt2
XC_SHA3_VCD   = build/xc_sha3/fml_xc_sha3.vcd

$(eval $(call tgt_smt2,$(XC_SHA3_SMT2),$(XC_SHA3_SRC),fml_xc_sha3))
$(eval $(call tgt_bmc,fml_xc_sha3,$(XC_SHA3_SMT2),$(XC_SHA3_VCD)))
$(eval $(call tgt_cover,fml_xc_sha3,$(XC_SHA3_SMT2),$(XC_SHA3_VCD)))
$(eval $(call tgt_trace,fml_xc_sha3,$(XC_SHA3_SMT2),$(XC_SHA3_VCD)))

TARGETS += $(B_BOP_SMT2) bmc_fml_b_bop

all: $(TARGETS)

