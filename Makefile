PROJECT_FILE=device.qsf
#SOURCES=$(shell awk '/^set_global_assignment -name VERILOG_FILE/ {print $$NF}' $(PROJECT_FILE))
#TOPLEVEL=$(shell awk '/^set_global_assignment -name TOP_LEVEL_ENTITY/ {print $$NF}' $(PROJECT_FILE))

TOPLEVEL=device
TESTBENCH=$(wildcard *tb.v)

SOURCES = LPC_Peri.v device.v lpc_postcode.v lpc_com.v lpc_decode.v

PATH:=$(PATH):/c/altera/13.1/quartus/bin64

all: do_all stats

do_all: output_files/$(TOPLEVEL).pof

db/$(TOPLEVEL).map.qmsg: $(TOPLEVEL).qsf $(SOURCES)
	quartus_map --read_settings_files=on --write_settings_files=off $(TOPLEVEL) -c $(TOPLEVEL)

db/$(TOPLEVEL).fit.qmsg: db/$(TOPLEVEL).map.qmsg
	quartus_fit --read_settings_files=off --write_settings_files=off $(TOPLEVEL) -c $(TOPLEVEL)

db/$(TOPLEVEL).asm.qmsg: db/$(TOPLEVEL).fit.qmsg
	quartus_asm --read_settings_files=off --write_settings_files=off $(TOPLEVEL) -c $(TOPLEVEL)

output_files/$(TOPLEVEL).pof: db/$(TOPLEVEL).asm.qmsg

program: do_program stats

do_program: output_files/$(TOPLEVEL).pof $(TOPLEVEL).cdf
	quartus_pgm -c USB-Blaster $(TOPLEVEL).cdf

tb: $(SOURCES) $(TESTBENCH)
	iverilog -o $@ $^

test: tb
	vvp -n $<

test.vcd: test

stats: output_files/$(TOPLEVEL).pof
	@grep 'Total logic elements' output_files/$(TOPLEVEL).fit.rpt

clean:
	rm -rf db output_files incremental_db test.vcd tb
