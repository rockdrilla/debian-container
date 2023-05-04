#!/usr/bin/make -f
SHELL       :=/bin/sh
.SHELLFLAGS :=-ec
MAKEFLAGS   +=--no-print-directory

BIN = is-elf ufind xvp nproc.container
SHLIB = libnprocfix.so

CPPFLAGS += -Wextra

NO_WARN = attributes unused-function unused-parameter unused-result
CPPFLAGS += $(addprefix -Wno-,$(NO_WARN))

NO_CXX = rtti exceptions
CXXFLAGS += $(addprefix -fno-,$(NO_CXX))

NO_WARN_CXX = class-memaccess
CXXFLAGS += $(addprefix -Wno-,$(NO_WARN_CXX))

.DEFAULT: all
.PHONY: all install clean
all: $(BIN) $(SHLIB)

install:
	mkdir -p bin && cp -t bin $(BIN) && cp nprocfix.sh bin/nprocfix && chmod 0755 bin/*
	mkdir -p lib && cp -t lib $(SHLIB)

is-elf: is-elf.c.o

ufind: ufind.c.o

xvp: xvp.cc.o

nproc.container: nproc.c.o

libnprocfix.so: CFLAGS  += -fPIC
libnprocfix.so: LDFLAGS += -shared -Wl,--no-as-needed -ldl
libnprocfix.so: nprocfix.shlib.c.o

nprocfix.shallow: nprocfix.shallow.c.o

$(BIN) $(SHLIB):
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.c.o: %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $^

%.cc.o: %.cc
	$(CXX) -c $(CFLAGS) $(CXXFLAGS) $(CPPFLAGS) -o $@ $^

clean:
	rm -vf $(wildcard *.o) $(BIN) $(SHLIB)
