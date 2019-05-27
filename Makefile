

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

all: $(P_ADDSUB_SMT2)
