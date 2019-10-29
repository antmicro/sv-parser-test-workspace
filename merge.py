#!/usr/bin/env python3

import sys
import json

def main():
	outfile = sys.argv[1]
	infiles = sys.argv[2:]

	merged = []

	for f in infiles:
		with open(f, 'r') as fd:
			t = json.load(fd)
			merged.append(t)

	outf = dict()
	outf['type'] = 'AST_TOP'
	outf['nodes'] = merged

	with open(outfile, 'w') as fd:
		json.dump(outf, fd, indent=2)

if __name__ == "__main__":
	main()
