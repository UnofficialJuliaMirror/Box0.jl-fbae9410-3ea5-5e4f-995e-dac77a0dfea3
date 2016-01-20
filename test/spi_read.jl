import Box0: Usb
import Box0: start, spi, close, spi_auto_gen
import Box0: SpiOutFd, SpiInFd
import Box0: SPI_CONFIG_MODE_0

const ss0 = UInt8(0)
const bitsize = UInt8(8)
const mode = UInt8(0)
const msb_first = false
const COUNT = UInt8(5)

dev = Usb.open_supported()
spi0 = spi(dev)

out = SpiOutFd(ss0, mode, msb_first, bitsize, COUNT)
in = spi_auto_gen(out)

out.xData[1] = 0x01
out.xData[2] = 0x02
out.xData[3] = 0x03
out.xData[4] = 0x04
out.xData[4] = 0x05

start(spi0, (Ref(out), ), (Ref(in), ))
if out.xData == in.xData
	println("Data matched!")
else
	println("We have problem, data did not match")
end

close(spi0)
close(dev)
