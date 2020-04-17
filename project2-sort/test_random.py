#!/usr/bin/python3

# This is very thrown-together

import sys
import subprocess
from random import seed
from random import random
from random import randint
from tqdm import tqdm
from signal import signal, SIGINT

def handler(signal_received, frame):
    print("\n\nStopping.\n")
    exit(1)

signal(SIGINT, handler)

#seed(817700)

randints = []
negatives = 0
reverseorder=False
revstring="n"
unsignedstring=""
positives=2147483647

if (sys.argv[2] == 'unsigned'):
	positives=4294967295
	unsignedstring="u"
else:
	negatives=-2147483647
	unsignedstring="s"


if (sys.argv[3] == 'reverse'):
	reverseorder=True
	revstring="r"
else:
	revstring="n"
	reverseorder=False


for i in tqdm(range(0, int(sys.argv[1])), bar_format='{l_bar}{bar:25}{r_bar}{bar:-25b}'):
	number_of_ints = randint(0,100)

	for x in range(0, number_of_ints):
		randints.append(randint(negatives,positives))

	f = open("_test.txt", 'w')
	for x in randints:
		f.write("%s\n" % x)
	f.close()

	subprocess.run(["./sort.out", "_test.txt", revstring, unsignedstring], stdout=subprocess.DEVNULL)
	sorted_list = sorted(randints, reverse=reverseorder)


	f = open("./sorted.txt", 'r')
	attempted_list = f.readlines()
	attempted_list = [int(x) for x in attempted_list]
	f.close()

	for i, item in enumerate(sorted_list):
		#print(item)
		if (attempted_list[i] != item):
			print("at line:",f'{i:2d}',"correct is [",f'{item:10d}',"] vs [",f'{attempted_list[i]:10d}', "]")


	result = attempted_list==sorted_list
	if (result==False):
		print("failed after %d" % i)
		break

	randints.clear()
