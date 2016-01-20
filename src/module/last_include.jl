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
export ain, aout, spi, i2c, pwm, dio

for (t::Type, n::AbstractString) in [(Ain, "ain"), (Aout, "aout"), (Spi, "spi"),
									(I2c, "i2c"), (Pwm, "pwm"), (Dio, "dio")]
	func = @eval "b0_"*$n*"_close"
	@eval close(mod::Ptr{$t}) = act(ccall(($func, "libbox0"), ResultCode, (Ptr{$t}, ), mod))
	func = @eval "b0_"*$n*"_info"
	@eval info(mod::Ptr{$t}) = act(ccall(($func, "libbox0"), ResultCode, (Ptr{$t}, ), mod))
	func = @eval "b0_"*$n*"_cache_flush"
	@eval cache_flush(mod::Ptr{$t}) = act(ccall(($func, "libbox0"), ResultCode, (Ptr{$t}, ), mod))

	func = @eval "b0_"*$n*"_open"
	@eval begin
		open(dev::Ptr{Device}, mod::Ref{Ptr{$t}}, index::Cint = Cint(0)) =
			act(ccall(($func, "libbox0"), ResultCode,
					(Ptr{Device}, Ref{Ptr{$t}}, Cint), dev, mod, index))
	end

	open_by_name = @eval Symbol($n)
	@eval begin
		$open_by_name(dev::Ptr{Device}, index::Cint = Cint(0)) =
			(mod = Ref{Ptr{$t}}(0); open(dev, mod, index); mod[])
	end
end

function open(mod::Ptr{Module})
	for (t::ModuleType, func::Function) in [(AIN, ain), (AOUT, aout),
							(SPI, spi), (I2C, i2c), (PWM, pwm), (DIO, dio)]
		if mod.type == t
			return func(mod.device, mod.index)
		end
	end
	error("Module(", mod, ") type unknown")
end
