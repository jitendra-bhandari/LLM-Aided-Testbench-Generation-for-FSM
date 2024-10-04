#!/bin/sh
# VCS Simulation 
vcs -full64 -sverilog *.v -l vcs.log -kdb -debug_access+all -lca -cm line+tgl+fsm+cond+branch -cm_fsmopt reportWait

./simv -cm line+tgl+fsm+cond+branch

# Get the coverage detail
urg -metric line+tgl+fsm+cond+branch -format text -dir simv.vdb
