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

export Aout
export static_prepare, static_start, static_stop
export stream_prepare, stream_start, stream_stop, stream_write

immutable Aout
	header::Module
	bitsize::Ptr{Bitsize}
	buffer::Ptr{Buffer}
	capab::Ptr{Capabilities}
	count::Ptr{Count}
	chan_config::Ptr{ChannelConfiguration}
	chan_seq::Ptr{ChannelSequence}
	label::Ptr{Label}
	ref::Ptr{Reference}
	repeat::Ptr{Repeat}
	speed::Ptr{Speed}
	stream::Ptr{Stream}
end

#stream
stream_prepare(mod::Ptr{Aout}, stream_value::Ptr{StreamValue}) =
	act(ccall(("b0_aout_stream_prepare", "libbox0"), ResultCode,
			(Ptr{Aout}, Ptr{StreamValue}), mod, stream_value))

stream_start(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_stream_start", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

stream_stop(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_stream_stop", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

for d in [(Void, ""), (Float32, "_float"), (Float64, "_double")]
	t = d[1]
	func = @eval "b0_aout_stream_write"*$d[2]
	@eval begin
		stream_write(mod::Ptr{Aout}, data::Ptr{$t}, count::Csize_t) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Aout}, Ptr{$t}, Csize_t), mod, data, count))
	end
end

stream_write{T}(mod::Ptr{Aout}, data::Ptr{T}, count::Integer) =
	stream_write(mod, data, Csize_t(count))

stream_write{T}(mod::Ptr{Aout}, data::Array{T}) =
	stream_write(mod, pointer(data), length(data))


#static
static_prepare(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_static_prepare", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

static_stop(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_static_stop", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

for d in [(Void, ""), (Float32, "_float"), (Float64, "_double")]
	t = d[1]
	func = @eval "b0_aout_static_start"*$d[2]
	@eval begin
		static_start(mod::Ptr{Aout}, data::Ptr{$t}, count::Csize_t) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Aout}, Ptr{$t}, Csize_t), mod, data, count))
	end
end

static_start{T}(mod::Ptr{Aout}, data::Ptr{T}, count::Integer) =
	static_start(mod, data, Csize_t(count))

static_start{T}(mod::Ptr{Aout}, data::Array{T}) =
	static_start(mod, pointer(data), length(data))
