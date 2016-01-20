import Box0
import Box0: Usb
import Box0: log, ain, static_prepare, static_start, close

dev = Usb.open_supported()
log(dev, Box0.DEBUG)
ain0 = ain(dev)
static_prepare(ain0)
speed = 60000 # 600KS/s  (assuming)
val = Array{Float32}(100)
static_start(ain0, val)
println(val)
close(ain0)
close(dev)

using PyPlot: plot, show, title
x = linspace(0, length(val) / float(speed), length(val))
y = val
plot(x, y, color="red")
title("AIN0 test data")
show()
