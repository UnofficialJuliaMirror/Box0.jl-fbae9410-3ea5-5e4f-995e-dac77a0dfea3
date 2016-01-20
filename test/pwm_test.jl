import Box0: Usb
import Box0: pwm, start, set, stop, calc

ch0 = UInt8(0)

dev = Usb.open_supported()
pwm0 = pwm(dev)

speed, period = calc(pwm0, 1.0)
println("speed, period: ", speed, ", ", period)
set(pwm0, ch0, 1.0)

start(pwm0)

while true
	sleep(1)
end

stop(pwm0)

close(pwm0)
close(dev)
