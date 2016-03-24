#
# This file is part of Box0.jl.
# Copyright (C) 2016 Kuldeep Singh Dhaka <kuldeepdhaka9@gmail.com>
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

export Bitsize

immutable Bitsize
	header::Property
	values_len::Csize_t
	values::Ptr{UInt8}
end

set(prop::Ptr{Bitsize}, value::UInt8) =
	act(ccall(("b0_bitsize_set", "libbox0"), ResultCode,
				(Ptr{Bitsize}, UInt8), prop, value))

set(prop::Ptr{Bitsize}, value::Integer) = set(prop, UInt8(value))

get(prop::Ptr{Bitsize}, value::Ref{UInt8}) =
	act(ccall(("b0_bitsize_get", "libbox0"), ResultCode,
				(Ptr{Bitsize}, Ptr{UInt8}), prop, value))

get(prop::Ptr{Bitsize}) = (value = Ref{UInt8}(0); get(prop, value); value[])
