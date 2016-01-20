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

export close, info, ping, manuf, name, serial
export start, next, stop

close(dev::Ptr{Device}) = act(ccall(("b0_device_close", "libbox0"), ResultCode, (Ptr{Device}, ), dev))
ping(dev::Ptr{Device}) = act(ccall(("b0_device_ping", "libbox0"), ResultCode, (Ptr{Device}, ), dev))
info(dev::Ptr{Device}) = act(ccall(("b0_device_info", "libbox0"), ResultCode, (Ptr{Device}, ), dev))

name(dev::Ptr{Device}) = bytestring(dev.name)
manuf(dev::Ptr{Device}) = bytestring(dev.manuf)
serial(dev::Ptr{Device}) = bytestring(dev.serial)

# internal work
modules_len(dev::Ptr{Device}) = unsafe_load(dev, 1).modules_len
modules(dev::Ptr{Device}) = unsafe_load(dev, 1).modules
module_offset_valid(dev::Ptr{Device}, i::Csize_t) = (i <= modules_len(dev))
unsafe_get_module(dev::Ptr{Device}, i::Csize_t) = unsafe_load(modules(dev), i)
function safe_get_module(dev::Ptr{Device}, i::Csize_t)
	if !module_offset_valid(dev, i)
		throw(ArgumentError("index out of range"))
	end
	return unsafe_get_module(dev, i)
end

# just for ease
length(dev::Ptr{Device}) = modules_len(dev)

# device iterator
start(dev::Ptr{Device}) = one(Csize_t)
next(dev::Ptr{Device}, state::Csize_t) = (unsafe_get_module(dev, state), state + one(state))
done(dev::Ptr{Device}, state::Csize_t) = (! module_offset_valid(dev, state))
