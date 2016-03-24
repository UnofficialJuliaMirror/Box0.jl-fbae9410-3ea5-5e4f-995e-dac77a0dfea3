import Box0
import Box0: Usb
import Box0: log, ain, static_prepare, close, set, get, speed

dev = Usb.open_supported()
log(dev, Box0.DEBUG)
ain0 = ain(dev)
static_prepare(ain0)

println("setting", 1000)
set(speed(ain0), 1000)

data = get(speed(ain0))
println("got back", data)

close(ain0)
close(dev)
