OPAM_LIB := $(shell opam config var lib 2>/dev/null)
OPAM_STUBS := $(shell opam config var stublibs 2>/dev/null)

.PHONY: all
all: build

.PHONY: build
build:
	dune build @install

.PHONY: test
test:
	dune runtest -j 1 --no-buffer -p owl

.PHONY: clean
clean:
	dune clean

.PHONY: install
install: build
	dune install
	[ -f "$(OPAM_LIB)/stubslibs/dllowl_stubs.so" ] \
	  && mv "$(OPAM_LIB)/stubslibs/dllowl_stubs.so" \
	        "$(OPAM_STUBS)/dllowl_stubs.so" || true
	[ -f "$(OPAM_LIB)/stubslibs/dllowl_opencl_stubs.so" ] \
	  && mv "$(OPAM_LIB)/stubslibs/dllowl_opencl_stubs.so" \
	        "$(OPAM_STUBS)/dllowl_opencl_stubs.so" || true
	$(RM) -d $(OPAM_LIB)/stubslibs || true

.PHONY: uninstall
uninstall:
	dune uninstall
	$(RM) $(OPAM_STUBS)/dllowl_stubs.so
	$(RM) $(OPAM_STUBS)/dllowl_opencl_stubs.so

.PHONY: doc
doc:
	opam install -y odoc
	dune build @doc
	cat docs/mathjax.js docs/highlight.pack.js >> _build/default/_doc/_html/highlight.pack.js
	cp -r _build/default/_doc/_html/* docs
	git add docs/*

.PHONY: distclean cleanall
distclean cleanall:
	dune uninstall && dune clean
	$(RM) -r $(find . -name .merlin)
	$(RM) $(OPAM_STUBS)/dllowl_stubs.so
	$(RM) $(OPAM_STUBS)/dllowl_opencl_stubs.so

PKGS=owl-base,owl,owl-zoo,owl-top
.PHONY: release
release:
	make install # as package distrib steps rely on owl-base etc
	opam install --yes dune-release
	dune-release tag
	dune-release distrib
	dune-release publish

	dune-release opam pkg -p owl-base
	dune-release opam pkg -p owl
	dune-release opam pkg -p owl-zoo
	dune-release opam pkg -p owl-top
	dune-release opam submit -p $(PKGS)

.PHONY: format
format:
	dune build @fmt --auto-promote

.PHONY: cloc
loc:
	cloc src/