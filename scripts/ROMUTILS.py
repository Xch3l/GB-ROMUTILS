from contextlib import contextmanager
from struct import pack, unpack

CMD_START   = 0x55
CMD_ROMDUMP = 0xA0
CMD_RAMDUMP = 0xA1
CMD_PEEK    = 0xA2
CMD_POKE    = 0xA3
CMD_TEST    = 0xAA
CMD_BAD     = 0xAF

def sendCommand(sp, cmd, data=b""):
	data = pack("<BB", CMD_START, cmd) + data
	sp.write(data)

def readByte(sp):
	sp.write(b"\0")
	return sp.read(1)

class ROMUTILS:
	@contextmanager
	def open(portName):
		import serial

		sp = serial.Serial(portName, 115200, timeout=.5)

		try:
			yield ROMUTILS(sp)
		finally:
			sp.close()

	def __init__(self, sp):
		self.sp = sp

	def sync(self):
		status = self.sp.read(2)

		if len(status) and status[0] == CMD_START:
			if status[1] == CMD_TEST:
				print(f"Sync {self.sp.read(2)}") # get sync value - should be "OK"
			else:
				print(f"Bad sync: {status}")

	def getSRAM(self):
		sp, timeout = self.sp, self.sp.timeout
		sp.timeout = 5

		try:
			sendCommand(sp, CMD_RAMDUMP)
			ack = readByte(sp)

			if ack == CMD_START: # read ack
				sram = readByte(sp)
				print(f"SRAM banks: {sram}")

				sp.write(pack("B", CMD_BAD)) # fail for now

			else:
				print(f"Bad sync: {ack}")

		finally:
			sp.timeout = timeout

	def peekByte(addr):
		sendCommand(self.sp, CMD_PEEK, pack("<H", addr))
		return self.sp.read(1)
