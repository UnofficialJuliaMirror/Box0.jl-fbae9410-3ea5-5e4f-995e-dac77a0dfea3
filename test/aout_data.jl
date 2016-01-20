import Box0
import Box0: Usb
import Box0: log, aout, static_prepare, static_start, close

dev = Usb.open_supported()
log(dev, Box0.DEBUG)
aout0 = aout(dev, 0)
static_prepare(aout0)
val = Array{Float32}(100)
for i = 1:endof(val); val[i] = 1; end
println(val)
static_start(aout0, val)

#TODO: this do not work
try
	while true
		sleep(0.1)
	end
catch
	println("exiting")
end

static_stop(aout0)
close(aout0)
close(dev)
