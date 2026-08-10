# TEST ?= test_RV32A
TEST ?= test_RV32I
# TEST ?= test_RV32M
# TEST ?= test_RV64A
# TEST ?= test_RV64I
# TEST ?= test_RV64M

run:
	xrun -uvm -sv -64 -uvmhome CDNS-1.2 \
	-timescale 1ns/1ps \
	+define+UVM_ON_TOP \
	+define+LENGTH=4 \
	-access +rwc \
	-f filelist.f \
	-top tb \
	-log xrun.log \
	+UVM_TESTNAME=$(TEST) \
	+UVM_VERBOSITY=UVM_MEDIUM

clean:
	rm -rf wave.shm xcelium.d *.history *.log

wave:
	simvision wave.shm

