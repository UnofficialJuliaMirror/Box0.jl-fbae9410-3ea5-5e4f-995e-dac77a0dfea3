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

export Ain
export mod, open, close, cache_flush, info
export static_prepare, static_start, static_stop
export stream_prepare, stream_start, stream_stop

immutable Ain
	header::Module_
	bitsize::Ptr{Bitsize}
	buffer::Ptr{Buffer};
	capab::Ptr{Capab}
	count::Ptr{Count}
	chan_config::Ptr{ChanConfig}
	chan_seq::Ptr{ChanSeq}
	label::Ptr{Label}
	ref::Ptr{Ref_}
	speed::Ptr{Speed}
	stream::Ptr{Stream}
end

#stream
stream_prepare(mod::Ptr{Ain}, stream_value::Ptr{StreamValue}) =
	act(ccall(("b0_ain_stream_prepare", "libbox0"), ResultCode,
			(Ptr{Ain}, Ptr{StreamValue}), mod, stream_value))

stream_start(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_stream_start", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))

for d in [(Void, ""), (Float32, "_float"), (Float64, "_double")]
	t = d[1]
	func = @eval "b0_ain_stream_write"*$d[2]
	@eval begin
		static_start(mod::Ptr{Ain}, data::Ptr{$t}, count::Csize_t,
					actual_count::Ptr{Csize_t} = C_NULL(Csize_t)) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Ain}, Ptr{$t}, Csize_t, Ptr{Csize_t}), mod, data, count, actual_count))
	end
end

stream_read{T}(mod::Ptr{Ain}, samples::Ptr{T}, count::Integer) =
	stream_read(mod, samples, Csize_t(count))

stream_read{T}(mod::Ptr{Ain}, samples::Array{T}) =
	stream_read(mod, pointer(samples), length(samples))

stream_stop(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_stream_stop", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))

#static
static_prepare(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_static_prepare", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))

for d in [(Void, ""), (Float32, "_float"), (Float64, "_double")]
	t = d[1]
	func = @eval "b0_ain_static_start"*$d[2]
	@eval begin
		static_start(mod::Ptr{Ain}, data::Ptr{$t}, count::Csize_t) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Ain}, Ptr{$t}, Csize_t), mod, data, count))
	end
end

static_start{T}(mod::Ptr{Ain}, samples::Ptr{T}, count::Integer) =
	static_start(mod, samples, Csize_t(count))

static_start{T}(mod::Ptr{Ain}, samples::Array{T}) =
	static_start(mod, pointer(samples), length(samples))

static_stop(mod::Ptr{Ain}) = act(ccall(("b0_ain_static_stop", "libbox0"),
		ResultCode, (Ptr{Ain}, ), mod))
