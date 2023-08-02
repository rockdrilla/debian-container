#!/usr/bin/make -f
SHELL       :=/bin/sh
.SHELLFLAGS :=-ec
MAKEFLAGS   +=--no-print-directory

BIN = is-elf ufind xvp nproc.container uptime.container
SHLIB = libincontainer.so

CFLAGS += -g -flto=1 -fuse-linker-plugin -ffat-lto-objects -flto-partition=none

CPPFLAGS += -Wextra

NO_WARN = attributes unused-function unused-parameter unused-result
CPPFLAGS += $(addprefix -Wno-,$(NO_WARN))

NO_CXX = rtti exceptions
CXXFLAGS += $(addprefix -fno-,$(NO_CXX))

NO_WARN_CXX = class-memaccess
CXXFLAGS += $(addprefix -Wno-,$(NO_WARN_CXX))

.DEFAULT: all
.PHONY: all install clean clean-pgo
all: $(BIN) $(SHLIB)

install:
	mkdir -p bin && cp -t bin $(BIN) && cp nprocfix.sh bin/nprocfix && chmod 0755 bin/*
	mkdir -p lib && cp -t lib $(SHLIB)

is-elf: is-elf.c.o

ufind: ufind.c.o

xvp: xvp.cc.o

nproc.container: nproc.c.o

uptime.container: uptime.cc.o

libincontainer.so: CFLAGS  += -fPIC
libincontainer.so: LDFLAGS += -shared -Wl,--no-as-needed,-ldl
libincontainer.so: shlib.incontainer.c.o

$(BIN) $(SHLIB):
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

%.c.o: %.c
	$(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $^

%.cc.o: %.cc
	$(CXX) -c $(CFLAGS) $(CXXFLAGS) $(CPPFLAGS) -o $@ $^

clean:
	$(if $(wildcard *.o $(BIN) $(SHLIB)),rm -vf $(wildcard *.o $(BIN) $(SHLIB)),true)

clean-pgo:
	$(if $(wildcard *.gcda),rm -vf $(wildcard *.gcda),true)
