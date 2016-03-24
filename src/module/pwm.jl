#
# This file is part of Box0.jl.
# Copyright (C) 2015 Kuldeep Singh Dhaka <kuldeepdhaka9@gmail.com>
#
# Box0.jl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Box0.jl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Box0.jl.  If not, see <http://www.gnu.org/licenses/>.
#

export Pwm, PwmReg
export width, period, set, calc, start, stop

type Pwm
	header::Module_
	bitsize::Ptr{Bitsize}
	capab::Ptr{Capab}
	count::Ptr{Count}
	label::Ptr{Label}
	ref::Ptr{Ref_}
	speed::Ptr{Speed}
end

typealias PwmReg Cuintmax_t

width(mod::Ptr{Pwm}, ch::UInt8, width::PwmReg) =
	act(ccall(("b0_pwm_width_set", "libbox0"), ResultCode,
		(Ptr{Pwm}, UInt8, PwmReg), mod, ch, width))

width(mod::Ptr{Pwm}, ch::UInt8, width::Ptr{PwmReg}) =
	act(ccall(("b0_pwm_width_get", "libbox0"), ResultCode,
		(Ptr{Pwm}, UInt8, Ptr{PwmReg}), mod, ch, width))

function width(mod::Ptr{Pwm}, ch::UInt8)
	val::PwmReg = 0
	width(mod, Ptr{PwmReg}(pointer_to_objref(val)), ch)
	return val
end

period(mod::Ptr{Pwm}, period::PwmReg) =
	act(ccall(("b0_pwm_period_set", "libbox0"), ResultCode,
		(Ptr{Pwm}, PwmReg), mod, period))

period(mod::Ptr{Pwm}, period::Ptr{PwmReg}) =
	act(ccall(("b0_pwm_period_get", "libbox0"), ResultCode,
		(Ptr{Pwm}, Ptr{PwmReg}), mod, period))

function period(mod::Ptr{Pwm})
	val::PwmReg = 0
	period(mod, Ptr{PwmReg}(pointer_to_objref(val)))
	return val
end

const DUTY_CYCLE_HALF = Float64(50)

set(mod::Ptr{Pwm}, ch::UInt8, freq::Ref{Float64}, duty_cycle::Ref{Float64} = DUTY_CYCLE_HALF,
							error::Ref{Float64} = C_NULL(Float64)) =
	act(ccall(("b0_pwm_set", "libbox0"), ResultCode,
		(Ptr{Pwm}, UInt8, Ref{Float64}, Ref{Float64}, Ref{Float64}),
		mod, ch, freq, duty_cycle, error))

# for someone who only want to set values regardless or any fetchback
set(mod::Ptr{Pwm}, ch::UInt8, freq::Float64, duty_cycle::Float64 = DUTY_CYCLE_HALF) =
	set(mod, ch, Ref(freq), Ref{duty_cycle})

calc(mod::Ptr{Pwm}, freq::Float64, max_error::Float64,
		speed::Ref{UInt32}, period::Ref{PwmReg}, best_result::Cbool = Cbool(true)) =
	act(ccall(("b0_pwm_calc", "libbox0"), ResultCode,
		(Ptr{Pwm}, Float64, Float64, Ref{UInt32}, Ref{PwmReg}),
		mod, freq, max_error, speed, period))

#NOTE: remove in future if julia convert Bool and Cbool transparently
calc(mod::Ptr{Pwm}, freq::Float64, max_error::Float64,
		speed::Ref{UInt32}, period::Ref{PwmReg}, best_result::Bool = true) =
	calc(mod, freq, max_error, speed, period, Cbool(best_result))

function calc(mod::Ptr{Pwm}, freq::Float64, error::Float64 = Float64(100))
	speed = Ref{UInt32}(0)
	period = Ref{PwmReg}(0)
	calc(mod, freq, error, speed, period)
	return speed[], period[]
end

stop(mod::Ptr{Pwm}) =
	act(ccall(("b0_pwm_stop", "libbox0"), ResultCode, (Ptr{Pwm}, ), mod))

start(mod::Ptr{Pwm}) =
	act(ccall(("b0_pwm_start", "libbox0"), ResultCode, (Ptr{Pwm}, ), mod))

pwm_calc_width(period::Float64, duty_cycle::Float64) =
	PwmReg(period * duty_cycle / 100.0)

pwm_calc_freq(speed::UInt32, period::PwmReg) = (speed / period)

pwm_calc_freq_error(required_freq::Float64, calc_freq::Float64) =
	((abs(required_freq - calc_freq) * 100.0) / required_freq)
