import Box0: Usb, ResultException, WARN
import Box0: i2c, close, slave_detect, log

dev = Usb.open_supported()
log(dev, WARN)
i2c0 = i2c(dev)

found = false

for i::UInt8 in 0b0001000:0b1110111
	try
		if slave_detect(i2c0, i)
			println("Slave detected on: 0x", hex(i))
			found = true
		end
	catch e
		if !isa(e, ResultException)
			throw(e)
		end
	end
end

if !found
	println("No I2C Slave found!")
end

close(i2c0)
close(dev)
