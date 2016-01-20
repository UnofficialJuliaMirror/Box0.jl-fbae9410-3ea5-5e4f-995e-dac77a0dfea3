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

export info, search, name
export DIO, AOUT, AIN, SPI, I2C, PWM, CAN, CEC, CMP, UNIO

const DIO = ModuleType(1)
const AOUT = ModuleType(2)
const AIN = ModuleType(3)
const SPI = ModuleType(4)
const I2C = ModuleType(5)
const PWM = ModuleType(6)
const UNIO = ModuleType(7)

name(mod::Ptr{Module}) = bytestring(mod.name)
info(mod::Ptr{Module}) = act(ccall(("b0_module_info", "libbox0"), ResultCode, (Ptr{Module}, ), mod))

function search(dev::Ptr{Device}, type_::ModuleType, index::Integer)
	local mod::Ptr{Module}
	act(ccall(("b0_module_search", "libbox0"),
		ResultCode, (Ptr{Device}, Ptr{Ptr{Module}}, ModuleType, Cint),
		dev, pointer_from_objref(mod), type_, index))
	return mod
end