# ECE-251  Project 2 - Sort
Sorts a given list of up to 100 32-bit integers.


## Build:
```
$ make
```
## Prerequisites:
- ARMv7 cross toolchain
- ARM machine or appropriate emulator/QEMU (note executable is statically linked)
## Usage:
```
$ ./sort.out [filename] [r or n] [s or u]
```
r==reverse, n==normal (ascending) ||| s==signed, u==unsigned


## Using the fuzzer/tester
sort.out should be in the same directory
```
$ ./test_random.py [iterations] [signed/unsigned] [normal/reverse]
```
Example: 
```
$ ./test_random.py 300 unsigned normal
```
