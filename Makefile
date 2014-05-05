MKDIR    := mkdir
RM       := rm -f

datadir  := data
dbdir    := db
schema   := schema.logic
datasets := $(wildcard data/*.csv)
tests    := $(wildcard tests/*.logic)

vpath %.csv data/


$(datadir):
	$(MKDIR) $@

#============================
# Benchmark Template
#============================

define benchmark_template

$1.csv    := $(datadir)/edges-$1.csv
$1.db     := $(dbdir)/$1-graph
$1.script := script-$1.import


#-------------------------------------
#  Generate import scripts
#-------------------------------------

.INTERMEDIATE: $$($1.script)
$$($1.script): $$($1.csv)
	@echo "option,delimiter,\"	\"" > $$@
	@echo "option,hasColumnNames,false" >> $$@
	@echo "fromFile,\"$$(abspath $$<)\",column:1,node:1,column:2,node:2" >> $$@
	@echo "toPredicate,Edge,node:1,node:2" >> $$@


#-------------------------------------
#  Create one workspace per dataset
#-------------------------------------

$$($1.db).ph: $$($1.script) | $(datadir)
	bloxbatch -db $$($1.db)/ -create -overwrite
	bloxbatch -db $$($1.db)/ -addBlock -file $(schema)
	bloxbatch -db $$($1.db)/ -import $$<
	@touch $$@


#-------------------------------------------
#  Phony targets for testing and cleaning
#-------------------------------------------

.PHONY: $1-test.setup
$1-test.setup: $$($1.db).ph

.PHONY: $1-test.clean
$1-test.clean:
	$(RM) -r $$($1.db)/
	$(RM) $$($1.db).ph


endef


# !!!Generate rules per benchmark!!!
$(foreach dataset,$(datasets),$(eval $(call benchmark_template,$(dataset:data/edges-%.csv=%))))
