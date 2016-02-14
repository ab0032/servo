
OCAMLC=ocamlc
CC=cc
CC_INCLUDE="-I`ocamlc -where`"

all: demo run

%.o: %.c
	$(CC) -c $(CC_INCLUDE) $^

%.cmi: %.mli
	$(OCAMLC) -c $^

%.cmo: %.ml
	$(OCAMLC) -c $^


servo.cmi: servo.mli bcm2835.cmo bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -c servo.mli

bcm2835.cmo: bcm2835.ml bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -c bcm2835.ml

servo.cmo: servo.ml servo.cmi bcm2835.cmo bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -c servo.ml

demo.cmo: demo.ml servo.cmo servo.cmi bcm2835.cmo bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -c demo.ml

demo: demo.cmo servo.cmo servo.cmi bcm2835.cmo bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -custom -o demo bcm2835.cmo mem_map32_stubs.o time_stubs.o servo.cmo demo.cmo 

clean:
	rm -f *.o core *.cmi *.cmo demo

run:
	@echo
	@echo "    " run as root:
	@echo "    " ./demo
	@echo

