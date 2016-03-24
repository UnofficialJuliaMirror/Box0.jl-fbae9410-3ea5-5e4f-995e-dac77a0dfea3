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

export ChanSeq
export set, get

immutable ChanSeq
	header::Property
end

set(prop::Ptr{ChanSeq}, values::Ptr{UInt8}, count::Csize_t) =
	act(ccall(("b0_chan_seq_set", "libbox0"), ResultCode,
				(Ptr{ChanSeq}, Ptr{UInt8}, Csize_t), prop, values, count))

set(prop::Ptr{ChanSeq}, values::Ptr{UInt8}, count::Integer) =
	set(prop, values, Csize_t(count))

set(prop::Ptr{ChanSeq}, values::Array{UInt8}) =
	set(prop, pointer(values), length(values))

get(prop::Ptr{ChanSeq}, values::Ptr{UInt8}, count::Ref{Csize_t}) =
	act(ccall(("b0_chan_seq_get", "libbox0"), ResultCode,
				(Ptr{ChanSeq}, Ptr{UInt8}, Ptr{Csize_t}), prop, values, count))

get(prop::Ptr{ChanSeq}, values::Ptr{UInt8}, count::Integer) =
	(_count = Ref{Csize_t}(count); get(prop, values, _count); _count[])

get(prop::Ptr{ChanSeq}, values::Array{UInt8}) =
	get(prop, pointer(values), length(values))

# return the list (easy)
# assuming that: get will return at maximum max_count of array size
get(prop::Ptr{ChanSeq}, max_count::Integer = 256) =
	(arr = Array{UInt8}(max_count); count = get(prop, arr); resize!(arr, count))
