# Makefile
all: strings.out

strings.out: strings.S
	arm-linux-gnueabi-gcc $< -o $@ -ggdb3 -static

clean:
	rm strings.out
