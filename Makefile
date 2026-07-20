# Flock - a sheepdog trial, for Playdate.
#
#   make            release build -> out/Flock.pdx
#   make smoke      instrumented build -> out/FlockSmoke.pdx (SEED=n)
#
# Staging copies source/* into build/<variant>/source and writes
# smokeflag.lua (pdc wants one source root; smokeflag is generated).

OUT := out
SEED ?= 1

all: release

release: build/release/source
	pdc build/release/source $(OUT)/Flock.pdx

smoke: build/smoke/source
	pdc build/smoke/source $(OUT)/FlockSmoke.pdx

build/release/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	echo 'SMOKE_BUILD = false' > $@/smokeflag.lua

build/smoke/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	printf 'SMOKE_BUILD = true\nSMOKE_SEED = %s\n' "$(SEED)" > $@/smokeflag.lua

clean:
	rm -rf build $(OUT)

.PHONY: all release smoke clean
