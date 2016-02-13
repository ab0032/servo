
OCAMLC=ocamlc
CC=cc
CC_INCLUDE="-I`ocamlc -where`"

all: servo

test: mem_map32_test

%.o: %.c
	$(CC) -c $(CC_INCLUDE) $^

%.cmi: %.mli
	$(OCAMLC) -c $^

%.cmo: %.ml
	$(OCAMLC) -c $^


mem_map32_test.cmo: mem_map32_test.ml mem_map32.cmi mem_map32_stubs.o
	$(OCAMLC) -c mem_map32_test.ml

mem_map32_test: mem_map32_test.cmo mem_map32_test.cmi mem_map32.cmi mem_map32_stubs.o
	$(OCAMLC) -custom -o mem_map32_test  mem_map32_stubs.o mem_map32_test.cmo


servo.cmi: servo.mli bcm2835.cmo bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -c servo.mli

bcm2835.cmo: bcm2835.ml bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -c bcm2835.ml

servo.cmo: servo.ml servo.cmi bcm2835.cmo bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -c servo.ml

servo: servo.cmo servo.cmi bcm2835.cmo bcm2835.cmi mem_map32.cmi time.cmi mem_map32_stubs.o time_stubs.o
	$(OCAMLC) -custom -o servo  bcm2835.cmo mem_map32_stubs.o time_stubs.o servo.cmo

clean:
	rm -f *.o core *.cmi *.cmo servo mem_map32_test

run:
	echo run as root:
	echo ./servo

