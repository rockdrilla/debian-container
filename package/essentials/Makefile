#!/usr/bin/make -f
SHELL       :=/bin/sh
.SHELLFLAGS :=-ec
MAKEFLAGS   +=--no-print-directory

BIN = is-elf ufind xvp nproc.k2 uptime.k2
SHLIB = k2env.so

# using compressed debug sections
# CFLAGS += -gz

CPPFLAGS += -Wextra

NO_WARN = attributes unused-function unused-parameter unused-result
CPPFLAGS += $(addprefix -Wno-,$(NO_WARN))

NO_CXX = rtti exceptions
CXXFLAGS += $(addprefix -fno-,$(NO_CXX))

NO_WARN_CXX = class-memaccess
CXXFLAGS += $(addprefix -Wno-,$(NO_WARN_CXX))

.DEFAULT: all
.PHONY: all install clean clean-pgo test testdata $(addprefix test.,$(BIN)) $(addprefix testdata.,$(BIN))
all: $(BIN) $(SHLIB)

install:
	mkdir -p bin lib && \
	chmod 0755 $(BIN) && \
	cp -t bin $(BIN) && \
	cp -t lib $(SHLIB)

is-elf: is-elf.c.o

ufind: ufind.c.o

xvp: xvp.cc.o

nproc.k2: nproc.c.o

uptime.k2: uptime.cc.o

k2env.so: CFLAGS  += -fPIC
k2env.so: LDFLAGS += -shared -Wl,--no-as-needed,-ldl
k2env.so: shlib.k2env.c.o

$(BIN) $(SHLIB):
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.c.o: %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $^

%.cc.o: %.cc
	$(CXX) -c $(CFLAGS) $(CXXFLAGS) $(CPPFLAGS) -o $@ $^

GEN = *.o $(BIN) $(SHLIB) $(addsuffix .tdata,$(BIN)) $(addsuffix .tdata.*,$(BIN))
clean:
	$(if $(wildcard $(GEN)),rm -vf $(wildcard $(GEN)),true)

clean-pgo:
	$(if $(wildcard *.gcda),rm -vf $(wildcard *.gcda),true)

testdata: $(addprefix testdata.,$(BIN))

$(addprefix test.,$(BIN)): test.%: % testdata.%

test: $(addprefix test.,$(BIN))

testdata.xvp: xvp.tdata

xvp.tdata:
	PAGE_SIZE=$$(getconf PAGE_SIZE) ; \
	CHAR_BIT=$$(getconf CHAR_BIT) ; \
	LONG_BIT=$$(getconf LONG_BIT) ; \
	ARG_MAX=$$(( (PAGE_SIZE * 32) - (LONG_BIT/CHAR_BIT) )) ; \
	printf 1 > xvp.tdata.00 ; \
	{ cat xvp.tdata.00 ; printf '\0' ; } > xvp.tdata.01 ; \
	{ cat xvp.tdata.01 ; printf 2 ; } > xvp.tdata.02 ; \
	for i in $$(seq 1 100000) ; do printf '%s\0' $$i ; done > xvp.tdata.03 ; \
	for i in $$(seq 1 300000) ; do printf '%s\0' $$i ; done > xvp.tdata.04 ; \
	for i in $$(seq 1 $$((ARG_MAX - 3)) ) ; do printf a ; done > xvp.tdata.05 ; \
	{ cat xvp.tdata.05 ; printf a ; } > xvp.tdata.06 ; \
	{ cat xvp.tdata.06 ; printf a ; } > xvp.tdata.07 ; \
	{ cat xvp.tdata.07 ; printf a ; } > xvp.tdata.08 ; \
	touch $@

test.xvp:
	for f in xvp.tdata.* ; do \
	  echo "## $$f" ; \
	  ./xvp printf '%s\n' $$f | wc -l ; \
	  ./xvp sh -c 'echo $$#' -- $$f ; \
	done
