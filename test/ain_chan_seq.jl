import Box0
import Box0: Usb
import Box0: log, ain, static_prepare, close, set, get, chan_seq

dev = Usb.open_supported()
log(dev, Box0.DEBUG)
ain0 = ain(dev)
static_prepare(ain0)

data = Array{UInt8}([0, 1, 3])

println("setting", data)
set(chan_seq(ain0), data)

data = get(chan_seq(ain0))
println("got back", data)

close(ain0)
close(dev)
