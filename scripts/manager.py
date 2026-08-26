from ROMUTILS import ROMUTILS
import sys, serial

port = sys.argv[1] if len(sys.argv) >= 2 else None

if not port:
	import serial.tools.list_ports as listPorts

	# List available ports
	ports = listPorts.comports()
	print("No port selected. Listing available ports:")

	if len(ports) == 0:
		print("  <none>")
		exit(0)

	for i in range(len(ports)):
		print(f"{i: >3}: {ports[i]}")
	print("")

	try:
		sel = input("Select port [0]: ")
		sel = int(sel) if sel else 0

		if sel < 0 or sel >= len(ports):
			print("Invalid port number")
			exit(1)

		port = ports[sel].name
	except KeyboardInterrupt:
		exit(0)

print(f"Connecting to {port}... ", end="")
with ROMUTILS.open(port) as r:
	print("OK!")

	try:
		# testing protocol
		r.getSRAM()

		while 1:
			r.sync()

			#print(r.peekByte(0x0134))
	except KeyboardInterrupt:
		pass
