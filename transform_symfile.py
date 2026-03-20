with open("ROMUTILS.sym", "r") as f:
	symfile = f.read().splitlines()

editSym = False
for i in range(len(symfile)):
	line = symfile[i]

	if line == "[labels]":
		editSym = True
		continue

	if not editSym:
		continue

	if line == "":
		break

	# transform ROM to WRAM addresses
	bank = line[:2]
	addr = int(line[3:7], 16)
	label = line[8:]

	if bank == "01":
		bank = "00"
		addr = (addr | 0xC000) & 0xFFFF
		symfile[i] = f"{bank}:{addr:04x} {label}"

with open("ROMUTILS.sym", "w") as f:
	for line in symfile:
		f.write(line)
		f.write("\n")
