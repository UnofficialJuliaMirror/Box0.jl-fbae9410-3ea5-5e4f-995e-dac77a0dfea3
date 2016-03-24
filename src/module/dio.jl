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

export LOW, HIGH, DISABLE, ENABLE, INPUT, OUTPUT
export Dio, Pin, PinGroup, UInt8
export input, output, high, low, toggle, enable, disable
export value, value_toggle, dir, hiz
export static_prepare
export pin, pin_group

immutable Dio
	header::Module_
	capab::Ptr{Capab}
	count::Ptr{Count}
	label::Ptr{Label}
	ref::Ptr{Ref_}
end

#pin
type Pin
	mod::Ptr{Dio}
	val::UInt8
end

pin(mod::Ptr{Dio}, val::UInt8) = Pin(mod, val)
pin(mod::Ptr{Dio}, val::Integer) = pin(mod, UInt8(val))

#pin group
type PinGroup
	mod::Ptr{Dio}
	vals::Array{UInt8}
end

pin_group(mod::Ptr{Dio}, vals::Array{UInt8}) = PinGroup(mod, vals)
#TODO: convert to array from tuple
pin_group(mod::Ptr{Dio}, val::UInt8...) = PinGroup(mod, val...)

const LOW = false
const HIGH = true

const DISABLE = false
const ENABLE = true

const INPUT = false
const OUTPUT = true

static_prepare(mod::Ptr{Dio}) =
	act(ccall(("b0_dio_static_prepare", "libbox0"), ResultCode, (Ptr{Dio}, ), mod))

for n in ("dir", "value", "hiz")
	func = @eval Symbol($n)
	func_get = @eval "b0_dio_"*$n*"_get"
	func_set = @eval "b0_dio_"*$n*"_set"

	@eval begin
		$func(mod::Ptr{Dio}, pin::UInt8, val::Cbool) =
			act(ccall(($func_set, "libbox0"), ResultCode,
				(Ptr{Dio}, UInt8, Cbool), mod, pin, val))

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func(mod::Ptr{Dio}, pin::UInt8, val::Bool) = $func(mod, pin, Cbool(val))

		$func(mod::Ptr{Dio}, pin::UInt8, val::Ref{Cbool}) =
			act(ccall(($func_get, "libbox0"), ResultCode,
				(Ptr{Dio}, UInt8, Ref{Cbool}), mod, pin, val))

		$func(mod::Ptr{Dio}, pin::UInt8) =
			(val = Ref{Cbool}(0); $func(mod, pin, val); return Bool(val[]);)

		$func(pin::Pin, val::Cbool) = $func(pin.mod, pin.val, val)

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func(pin::Pin, val::Bool) = $func(pin, Cbool(val))

		$func(pin::Pin, val::Ref{Cbool}) = $func(pin.mod, pin.val, val)
		$func(pin::Pin) = $func(pin.mod, pin.val)
	end

	func_get = @eval "b0_dio_multiple_"*$n*"_get"
	func_set = @eval "b0_dio_multiple_"*$n*"_set"

	@eval begin
		$func(mod::Ptr{Dio}, pins::Ptr{UInt8}, size::Csize_t, val::Cbool) =
			act(ccall(($func_set, "libbox0"), ResultCode,
				(Ptr{Dio}, Ptr{UInt8}, Csize_t, Cbool), mod, pins, size, val))

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func(mod::Ptr{Dio}, pins::Ptr{UInt8}, size::Csize_t, val::Bool) =
			$func(mod, pins, size, Cbool(val))

		$func(mod::Ptr{Dio}, pins::Ptr{UInt8}, vals::Ptr{Cbool}, size::Csize_t) =
			act(ccall(($func_get, "libbox0"), ResultCode,
				(Ptr{Dio}, Ptr{UInt8}, Ptr{Cbool}, Csize_t), mod, pins, vals, size))

		$func(mod::Ptr{Dio}, pins::Array{UInt8}, val::Cbool) =
			$func(mod, pointer(pins), Csize_t(length(pins)), val)

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func(mod::Ptr{Dio}, pins::Array{UInt8}, val::Bool) = $func(mod, pins, val)

		$func(mod::Ptr{Dio}, pins::Array{UInt8}, vals::Array{Cbool}) = (
			@assert length(pins) == length(vals);
			$func(mod, pointer(pins), pointer(vals), Csize_t(length(pins)))
		)

		$func(pin_group::Ptr{Pin}, val::Cbool) =
			$func(pin_group.mod, pin_group.vals, val)

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func(pin_group::Ptr{Pin}, val::Bool) = $func(pin_group, Cbool(val))

		$func(pin_group::Ptr{Pin}, vals::Ptr{Cbool}, size::Csize_t) = (
			@assert length(pin_group.vals) == size;
			$func(pin_group.mod, pointer(pin_group.vals), vals, size)
		)

		$func(pin_group::Ptr{Pin}, vals::Array{Cbool}) =
			$func(pin_group.mod, pin_group.vals, vals)
	end

	func_get = @eval "b0_dio_all_"*$n*"_get"
	func_set = @eval "b0_dio_all_"*$n*"_set"

	@eval begin
		$func(mod::Ptr{Dio}, val::Cbool) =
			act(ccall(($func_set, "libbox0"), ResultCode,
				(Ptr{Dio}, Cbool), mod, val))

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func(mod::Ptr{Dio}, val::Bool) = $func(mod, Cbool(val))

		# using this function can be dangerous.
		# it assume that the array length is equal to number of pins
		$func(mod::Ptr{Dio}, vals::Ptr{Cbool}) =
			act(ccall(($func_get, "libbox0"), ResultCode,
				(Ptr{Dio}, Ptr{Cbool}), mod, vals))

		$func(mod::Ptr{Dio}, vals::Array{Cbool}) = (
			@assert length(val) >= mod.count.value;
			$func(mod, pointer(vals))
		)
	end
end

#special case: value toggle
value_toggle(mod::Ptr{Dio}, pin::UInt8) =
	act(ccall(("b0_dio_value_toggle", "libbox0"), ResultCode,
		(Ptr{Dio}, UInt8), mod, pin))

value_toggle(mod::Ptr{Dio}, pins::Ptr{UInt8}, size::Csize_t) =
	act(ccall(("b0_dio_multiple_value_toggle", "libbox0"), ResultCode,
		(Ptr{Dio}, Ptr{UInt8}, Csize_t), mod, pins, size))

value_toggle(mod::Ptr{Dio}, pins::Array{UInt8}) =
	value_toggle(mod, pointer(pins), Csize_t(length(pins)))

value_toggle(mod::Ptr{Dio}) =
	act(ccall(("b0_dio_all_value_toggle", "libbox0"), ResultCode, (Ptr{Dio}, ), dio))

value_toggle(pin::Pin) = value_toggle(pin.mod, pin.val)

value_toggle(pin_group::PinGroup) = value_toggle(pin_group.mod, pin_group.vals)

#easy to use (single)
input(mod::Ptr{Dio}, pin::UInt8) = dir(mod, pin, INPUT)
output(mod::Ptr{Dio}, pin::UInt8) = dir(mod, pin, OUTPUT)
high(mod::Ptr{Dio}, pin::UInt8) = value(mod, pin, HIGH)
low(mod::Ptr{Dio}, pin::UInt8) = value(mod, pin, LOW)
toggle(mod::Ptr{Dio}, pin::UInt8) = value_toggle(mod, pin)
enable(mod::Ptr{Dio}, pin::UInt8) = hiz(mod, pin, DISABLE)
disable(mod::Ptr{Dio}, pin::UInt8) = hiz(mod, pin, ENABLE)

#easy to use (multiple)
input(mod::Ptr{Dio}, pins::Ptr{UInt8}) = dir(mod, pins, INPUT)
output(mod::Ptr{Dio}, pins::Ptr{UInt8}) = dir(mod, pins, OUTPUT)
high(mod::Ptr{Dio}, pins::Ptr{UInt8}) = value(mod, pins, HIGH)
low(mod::Ptr{Dio}, pins::Ptr{UInt8}) = value(mod, pins, LOW)
toggle(mod::Ptr{Dio}, pins::Ptr{UInt8}, size::Csize_t) = value_toggle(mod, pins, size)
toggle(mod::Ptr{Dio}, pins::Array{UInt8}) = value_toggle(mod, pins)
enable(mod::Ptr{Dio}, pins::Ptr{UInt8}) = hiz(mod, pins, DISABLE)
disable(mod::Ptr{Dio}, pins::Ptr{UInt8}) = hiz(mod, pins, ENABLE)

#easy to use (all)
input(mod::Ptr{Dio}) = dir(mod, INPUT)
output(mod::Ptr{Dio}) = dir(mod, OUTPUT)
high(mod::Ptr{Dio}) = value(mod, HIGH)
low(mod::Ptr{Dio}) = value(mod, LOW)
toggle(mod::Ptr{Dio}) = value_toggle(mod)
enable(mod::Ptr{Dio}) = hiz(mod, DISABLE)
disable(mod::Ptr{Dio}) = hiz(mod, ENABLE)

# easy to use (pin)
input(pin::Pin) = input(pin.mod, pin.val)
output(pin::Pin) = output(pin.mod, pin.val)
high(pin::Pin) = high(pin.mod, pin.val)
low(pin::Pin) = low(pin.mod, pin.val)
toggle(pin::Pin) = toggle(pin.mod, pin.val)
enable(pin::Pin) = enable(pin.mod, pin.val)
disable(pin::Pin) = disable(pin.mod, pin.val)

#easy to use (pin group)
input(pin_group::PinGroup) = input(pin_group.mod, pin_group.vals)
output(pin_group::PinGroup) = output(pin_group.mod, pin_group.vals)
high(pin_group::PinGroup) = high(pin_group.mod, pin_group.vals)
low(pin_group::PinGroup) = low(pin_group.mod, pin_group.vals)
toggle(pin_group::PinGroup) = toggle(pin_group.mod, pin_group.vals)
enable(pin_group::PinGroup) = enable(pin_group.mod, pin_group.vals)
disable(pin_group::PinGroup) = disable(pin_group.mod, pin_group.vals)
