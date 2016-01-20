import Box0: Usb
import Box0: DISABLE, dio, hiz, output, low, toggle, close

pin0 = UInt8(0)

dev = Usb.open_supported()
dio0 = dio(dev)
hiz(dio0, pin0, DISABLE)
output(dio0, pin0)
low(dio0, pin0)

while true
	toggle(dio0, pin0)
	sleep(1)
end

close(dio0)
close(dev)
