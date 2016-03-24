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

export open, close, cache_flush, info
export ain, aout, spi, i2c, pwm, dio, device, index, name

for (t::Type, n::AbstractString) in [(Ain, "ain"), (Aout, "aout"), (Spi, "spi"),
									(I2c, "i2c"), (Pwm, "pwm"), (Dio, "dio")]
	func_close = @eval "b0_"*$n*"_close"
	func_info = @eval "b0_"*$n*"_info"
	func_cache_flush = @eval "b0_"*$n*"_cache_flush"
	func_open = @eval "b0_"*$n*"_open"
	open_by_name = @eval Symbol($n)

	@eval begin
		close(mod::Ptr{$t}) = act(ccall(($func_close, "libbox0"),
			ResultCode, (Ptr{$t}, ), mod))

		info(mod::Ptr{$t}) = act(ccall(($func_info, "libbox0"),
			ResultCode, (Ptr{$t}, ), mod))

		cache_flush(mod::Ptr{$t}) = act(ccall(($func_cache_flush, "libbox0"),
			ResultCode, (Ptr{$t}, ), mod))

		open(dev::Ptr{Device}, mod::Ref{Ptr{$t}}, index::Cint = Cint(0)) =
			act(ccall(($func_open, "libbox0"), ResultCode,
					(Ptr{Device}, Ref{Ptr{$t}}, Cint), dev, mod, index))

		$open_by_name(dev::Ptr{Device}, index::Cint = Cint(0)) =
			(mod = Ref{Ptr{$t}}(0); open(dev, mod, index); mod[])

		# direct access to header
		device(mod::Ptr{$t}) = deref(mod).header.device
		index(mod::Ptr{$t}) = deref(mod).header.index
		name(mod::Ptr{$t}) = bytestring(deref(mod).header.name)
	end

	# access to properties using method
	for field in fieldnames(t)
		if field != :header
			@eval begin
				$field(mod::Ptr{$t}) = deref(mod).$field
				export $field
			end
		end
	end
end

function open(mod::Ptr{Module_})
	for (t::ModuleType, func::Function) in [(AIN, ain), (AOUT, aout),
							(SPI, spi), (I2C, i2c), (PWM, pwm), (DIO, dio)]
		if mod.type == t
			return func(device(mod), index(mod))
		end
	end
	error("Module(", mod, ") type unknown")
end
