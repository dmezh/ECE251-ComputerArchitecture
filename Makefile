# Makefile
all: sort.out

sort.out: sort.S
	arm-linux-gnueabi-gcc $< -o $@ -ggdb3 -static

clean:
	rm sort.out
