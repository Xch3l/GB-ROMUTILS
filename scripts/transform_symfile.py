import sys

if len(sys.argv) < 2:
	print("No SYM file.", file=sys.stderr)
	print(f"\t{sys.argv[0]} file.sym", file=sys.stderr)
	exit(1)

with open(sys.argv[1], "r") as f:
	lines = f.read().splitlines()

editSym = False
for i in range(len(lines)):
	line = lines[i]

	if line == "[labels]":
		editSym = True
		continue

	if not editSym:
		continue

	if line == "":
		break

	# transform ROM addresses to WRAM addresses
	if line[:2] == "01": # bank
		addr = (int(line[3:7], 16) | 0xC000) & 0xFFFF
		lines[i] = f"00:{addr:>04x} {line[8:]}"

with open(sys.argv[1], "w") as f:
	for line in lines:
		f.write(line + "\n")
