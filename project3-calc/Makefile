# Makefile
all: calc ccalc

calc: calc.S
	arm-linux-gnueabi-gcc $< -o $@ -ggdb3 -static -mfloat-abi=hard -mfpu=vfp -lm
ccalc: ccalc.c
	arm-linux-gnueabi-gcc $< -o $@ -ggdb3 -static -mfpu=vfp -lm

clean:
	rm calc ccalc
