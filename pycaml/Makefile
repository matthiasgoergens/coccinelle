#pad: was called Makefile.deb-pycaml before

OCAMLMAKEFILE = OCamlMakefile
PY_PREFIX = $(shell python getprefix.py)
PY_VERSION = $(shell python getversion.py)
CLIBS = python$(PY_VERSION) pthread dl util m c

SOURCES = pycaml.ml pycaml_ml.c
RESULT = pycaml
THREADS = yes
NO_CUSTOM = NO_CUSTOM

CFLAGS = -fPIC
ifeq ("$(PY_VERSION)","2.4")
export CPPFLAGS =-DPYTHON24
endif

LIBDIRS = $(PY_PREFIX)/lib/python$(PY_VERSION)/config
INCDIRS = $(PY_PREFIX)/include/python$(PY_VERSION)
OCAMLLDFLAGS = -linkall

all.opt: native-code-library pycaml.customtop

all: pycaml.customtop

pycaml.customtop: byte-code-library
	cp -f dllpycaml_stubs.so ../
	ocamlmktop -o pycaml.customtop pycaml.cma

clean::
	rm -f pycaml.customtop
	rm -f *.cm[aiox] *.a

distclean:: clean
	rm -rf ._d
	rm -f ../dllpycaml_stubs.so

depend: # added by julia, undoubtedly wrong

-include $(OCAMLMAKEFILE)
