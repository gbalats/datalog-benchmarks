MKDIR    := mkdir
TIME     := /usr/bin/time
RM       := rm -f
M4       := m4
QUIET    := @

datadir  := data
dbdir    := db
schema   := schema.logic
datasets := $(wildcard data/*.csv)
tests    := $(wildcard tests/*.logic)

vpath %.csv data/


$(dbdir):
	$(MKDIR) $@


#============================
# Benchmark Template
#============================

define benchmark_template

$1.csv    := $(datadir)/edges-$1.csv
$1.db     := $(dbdir)/$1-graph
$1.script := script-$1.logic
$1.tests  := $(tests:tests/%.logic=$1-graph.%)


#-------------------------------------
#  Generate import scripts
#-------------------------------------

.INTERMEDIATE: $$($1.script)
$$($1.script): $$($1.csv)
	$(M4) --define=FILENAME=$$< import-template.logic > $$@


#-------------------------------------
#  Create one workspace per dataset
#-------------------------------------

$$($1.db).ph: $$($1.script) | $(dbdir)
	lb create $$($1.db) --overwrite
	lb addblock $$($1.db) -f $(schema)
	lb exec $$($1.db) -f $$<
	$(QUIET) touch $$@


#-------------------------------------------
#  Phony targets for testing and cleaning
#-------------------------------------------

.PHONY: $1-graph.setup
$1-graph.setup: $$($1.db).ph

.PHONY: $$($1.tests)
$$($1.tests): $1-graph.%: tests/%.logic $1-graph.setup
	@printf "Running test %-24s ... " $$*
	$(QUIET) $(TIME) -f "elapsed time: %e sec" lb addblock $$($1.db) -f $$<
	$(QUIET) lb removeblock $$($1.db) $$*

.PHONY: $1-graph.test
$1-graph.test: $$($1.tests)

.PHONY: $1-graph.clean
$1-graph.clean:
	lb delete $$($1.db)
	$(RM) $$($1.db).ph


endef


# !!!Generate rules per benchmark!!!
$(foreach dataset,$(datasets),$(eval $(call benchmark_template,$(dataset:data/edges-%.csv=%))))
