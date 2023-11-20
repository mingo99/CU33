# VCS
VCS := vcs -full64 -LDFLAGS -Wl,-no-as-needed
DEFINE_VPD := +define+DUMP_VPD
DEFINE_DSDB := +define+DUMP_FSDB

# DVE
DVE := dve -full64

# Define the top level module
TOP_LEVEL_MODULE := tb_conv2d_3x3
# TOP_LEVEL_MODULE := tb_test

# Simulation Timescale
TIMESCALE := timescale=1ps/1ps

# Define the source filelist
FILELIST := ../src/filelist.tcl

# Directory log files are written to
LOG_DIR := ./logs

all: create_filelist com sim

create_filelist:
	tclsh ../scripts/shell/create_sim_project.tcl sim_filelist.f $(FILELIST)

com: make_log_dir	
	$(VCS) +v2k -sverilog \
	-f sim_filelist.f \
	-debug_access \
	-$(TIMESCALE) \
	-l $(LOG_DIR)/com.log \
	-top $(TOP_LEVEL_MODULE) \

sim:
	time ./simv -l  $(LOG_DIR)/sim.log

make_log_dir :
	mkdir -p $(LOG_DIR)

make_data_dir :
	mkdir -p ../data/exp/
	mkdir -p ../data/act/
	
clean: clean_com clean_sim clean_verdi clean_res clean_vivado 
	rm -rf *.log logs/
	rm -rf sim_filelist.f

clean_com:
	rm -rf csrc simv.daidir simv com.log 

clean_sim:
	rm -rf *.key *.fsdb *.vcd *.vpd DVEfiles NOVAS_dump.log sim.log

clean_res:
	rm -rf conv_acc_out.txt

clean_verdi:
	rm -rf ./verdiLog ./novas.*

clean_vivado:
	rm -rf vivado* .Xil/

clean_data:
	rm -rf ../data/*

open_dve :
	$(DVE) -vpd ./sim_output_pluson.vpd &

open_verdi:
	verdi +v2k -sverilog -f sim_filelist.f -ssf ./sim_output_pluson.fsdb -sswr ./$(TOP_LEVEL_MODULE).rc &

compare:
	@cd ../scripts/python && python compare.py

gen_tb: make_data_dir
	@cd ../scripts/python && python testbench_gen.py
