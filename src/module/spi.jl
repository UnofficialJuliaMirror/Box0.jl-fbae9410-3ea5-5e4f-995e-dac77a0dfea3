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

export SpiInHdWrite, SpiInHdRead, SpiInFd, SpiOutHdWrite, SpiOutHdRead, SpiOutFd
export Spi
export start, stop, active_state, spi_auto_gen
export SPI_CONFIG_CPHA, SPI_CONFIG_CPOL, SPI_CONFIG_MODE
export SPI_CONFIG_MODE_0, SPI_CONFIG_MODE_1, SPI_CONFIG_MODE_2, SPI_CONFIG_MODE_3
export SPI_CONFIG_FD, SPI_CONFIG_HD_READ, SPI_CONFIG_HD_WRITE
export SPI_CONFIG_MSB_FIRST, SPI_CONFIG_LSB_FIRST

const SPI_CONFIG_CPHA = UInt8(0x01)
const SPI_CONFIG_CPOL = UInt8(0x02)
SPI_CONFIG_MODE(mode) = (@assert 0 <= mode <= 3; UInt8(mode))
const SPI_CONFIG_MODE_0 = SPI_CONFIG_MODE(0)
const SPI_CONFIG_MODE_1 = SPI_CONFIG_MODE(1)
const SPI_CONFIG_MODE_2 = SPI_CONFIG_MODE(2)
const SPI_CONFIG_MODE_3 = SPI_CONFIG_MODE(3)
const SPI_CONFIG_FD = UInt8(0x00)
const SPI_CONFIG_HD_READ = UInt8(0x0C)
const SPI_CONFIG_HD_WRITE = UInt8(0x04)
const SPI_CONFIG_MSB_FIRST = UInt8(0x00)
const SPI_CONFIG_LSB_FIRST = UInt8(0x10)

function spi_array_type(bBitsize::UInt8)
	@assert bBitsize > 0
	@assert bBitsize <= 16 "Currently bBitsize > 16 not supported"
	bytes = UInt8(ceil(bBitsize / 8.0))
	[UInt8, UInt16][bytes]
end

spi_config(mode::UInt8, msb_first::Bool, comm_type::UInt8) =
	(SPI_CONFIG_MODE(mode) | (msb_first ? SPI_CONFIG_MSB_FIRST  : SPI_CONFIG_LSB_FIRST) | comm_type)

# OUT Full Duplex
type SpiOutFd{T}
	bSS::UInt8
	bmConfig::UInt8
	bBitsize::UInt8
	bCount::UInt8
	xData::Array{T}
end

SpiOutFd{T}(bSS::UInt8, bmConfig::UInt8, bBitsize::UInt8, bCount::UInt8, ::Type{T}) =
	SpiOutFd(bSS, bmConfig, bBitsize, bCount, Array{T}(bCount))

function SpiOutFd(bSS::UInt8, mode::UInt8, msb_first::Bool, bBitsize::UInt8, bCount::UInt8)
	bmConfig = spi_config(mode, msb_first, SPI_CONFIG_FD)
	t = spi_array_type(bBitsize)
	SpiOutFd(bSS, bmConfig, bBitsize, bCount, t)
end

# OUT Half Duplex Read
type SpiOutHdRead
	bSS::UInt8
	bmConfig::UInt8
	bBitsize::UInt8
	bRead::UInt8
end

SpiOutHdRead(bSS::UInt8, mode::UInt8, msb_first::Bool, bBitsize::UInt8, bRead::UInt8) = (
	bmConfig = spi_config(mode, msb_first, SPI_CONFIG_HD_READ);
	SpiOutHdRead(bSS, bmConfig, bBitsize, bRead)
)

# OUT Half Duplex Write
type SpiOutHdWrite{T}
	bSS::UInt8
	bmConfig::UInt8
	bBitsize::UInt8
	bWrite::UInt8
	xData::Array{T}
end

SpiOutHdWrite{T}(bSS::UInt8, bmConfig::UInt8, bBitsize::UInt8, bWrite::UInt8, ::Type{T}) =
	SpiOutHdWrite(bSS, bmConfig, bBitsize, bWrite, Array{T}(bWrite))

function SpiOutHdWrite(bSS::UInt8, mode::UInt8, msb_first::Bool, bBitsize::UInt8, bWrite::UInt8)
	bmConfig = spi_config(mode, msb_first, SPI_CONFIG_HD_WRITE)
	t = spi_array_type(bBitsize)
	SpiOutHdWrite(bSS, bmConfig, bBitsize, bWrite, t)
end

# IN Full Duplex
type SpiInFd{T}
	xData::Array{T}
end

SpiInFd{T}(bCount::UInt8, ::Type{T}) = SpiInFd{T}(Array{T}(bCount))

SpiInFd(bBitsize::UInt8, bCount::UInt8) = SpiInFd(bCount, spi_array_type(bBitsize))

# IN Half Duplex Read
type SpiInHdRead{T}
	xData::Array{T}
end

SpiInHdRead{T}(bRead::UInt8, ::Type{T}) = SpiInHdRead{T}(Array{T}(bRead))

SpiInHdRead(bBitsize::UInt8, bRead::UInt8) = SpiInHdRead(bRead, spi_array_type(bBitsize))

# IN Half Duplex Write
type SpiInHdWrite
	bWrite::UInt8
end

spi_auto_gen{T}(x::SpiOutFd{T}) = SpiInFd(x.bCount, T)
spi_auto_gen(x::SpiOutHdRead) = SpiInHdRead(x.bRead, spi_array_type(x.bBitsize))
spi_auto_gen{T}(x::SpiOutHdWrite{T}) = SpiInHdWrite(UInt8(0))

immutable Spi
	header::Module_
	bitsize::Ptr{Bitsize}
	buffer::Ptr{Buffer}
	capab::Ptr{Capab}
	count::Ptr{Count}
	label::Ptr{Label}
	ref::Ptr{Ref_}
	speed::Ptr{Speed}
end

start(mod::Ptr{Spi}, send::Ptr{Void}, send_len::Csize_t, recv::Ptr{Void}, recv_len::Csize_t,
		actual_recv_len::Ref{Csize_t} = C_NULL(Csize_t)) =
	act(ccall(("b0_spi_start", "libbox0"), ResultCode,
		(Ptr{Spi}, Ptr{Void}, Csize_t, Ptr{Void}, Csize_t, Ref{Csize_t}),
		mod, send, send_len, recv, recv_len, actual_recv_len))

start(mod::Ptr{Spi}, send::Ptr{Void}, send_len::Csize_t) =
	act(ccall(("b0_spi_start_out", "libbox0"), ResultCode,
		(Ptr{Spi}, Ptr{Void}, Csize_t), mod, send, send_len))

function spi_pack_array{T}(io::IO, arr::Array{T})
	for d in arr
		write(io, htol(d))
	end
end

function spi_pack_send(io::IO, send::Tuple)
	for i in send
		x = i[]
		if isa(x, SpiOutFd)
			write(io, htol(x.bSS))
			write(io, htol(x.bmConfig))
			write(io, htol(x.bBitsize))
			write(io, htol(x.bCount))
			spi_pack_array(io, x.xData)
		elseif isa(x, SpiOutHdWrite)
			write(io, htol(x.bSS))
			write(io, htol(x.bmConfig))
			write(io, htol(x.bBitsize))
			write(io, htol(x.bWrite))
			spi_pack_array(io, x.xData)
		elseif isa(x, SpiOutHdRead)
			write(io, htol(x.bSS))
			write(io, htol(x.bmConfig))
			write(io, htol(x.bBitsize))
			write(io, htol(x.bRead))
		else
			error("Unknown type of query used in tuple")
		end
	end
end

function spi_recv_pack(io::IO, recv::Tuple)
	for i in recv
		x = i[]
		if isa(x, SpiInFd)
			spi_pack_array(io, x.xData)
		elseif isa(x, SpiOutHdWrite)
			write(io, htol(x.bWrite))
		elseif isa(x, SpiOutHdRead)
			spi_pack_array(io, x.xData)
		else
			@assert "Type unknown"
		end
	end
end

function spi_unpack_array{T}(io::IO, arr::Array{T})
	for i in 1:length(arr)
		arr[i] = ltoh(read(io, T))
	end
end

function spi_unpack_recv(io::IO, recv::Tuple)
	for i in recv
		x = i[]
		if isa(x, SpiInFd)
			spi_unpack_array(io, x.xData)
		elseif isa(x, SpiInHdWrite)
			x.bWrite = ltoh(write(io, typeof(x.bWrite)))
		elseif isa(x, SpiInHdRead)
			spi_unpack_array(io, x.xData)
		else
			error("Unknown type of query used in tuple")
		end
		i[] = x
	end
end

function spi_verify_send_recv(send::Tuple, recv::Tuple)
	# verify that the recv buffer do not have more than send packets
	@assert length(send) >= length(recv)

	#verify for Out there is correct In type
	# if the recv tuple is smaller, then zip will limit the i, j values
	for (i, j) in zip(send, recv)
		i = i[]; j = j[]

		if isa(i, SpiOutHdRead)
			@assert isa(j, SpiInHdRead)
			@assert i.bRead == sizeof(j.xData)
		elseif isa(i, SpiOutHdWrite)
			@assert isa(j, SpiInHdWrite)
		elseif isa(i, SpiOutFd)
			@assert isa(j, SpiInFd)
			@assert sizeof(i.xData) == sizeof(j.xData)
		else
			error("Unknown type of query used in tuple")
		end
	end
end

#send: Tuple{Ref{$d}, Ref{$d} ...} where SpiOutFd, SpiOutHdWrite, SpiOutHdRead
#recv: Tuple{Ref{$d}, Ref{$d} ...} where SpiInFd, SpiInHdWrite, SpiInHdRead
function start(mod::Ptr{Spi}, send::Tuple, recv::Tuple,
						actual_recv_len::Ref{Csize_t} = C_NULL(Csize_t))

	spi_verify_send_recv(send, recv)

	# Send buffer
	s = IOBuffer()
	spi_pack_send(s, send)

	# recv buffer
	r = IOBuffer()
	spi_recv_pack(r, recv)

	# read data
	start(mod, Ptr{Void}(pointer(s.data)), Csize_t(length(s.data)),
				Ptr{Void}(pointer(r.data)), Csize_t(length(r.data)),
				actual_recv_len)

	# extract back data
	seek(r, 0)
	spi_unpack_recv(r, recv)
end

function start(mod::Ptr{Spi}, send::Tuple)
	s = IOBuffer()
	spi_pack_send(s, send)
	start(mod, Ptr{Void}(pointer(s.data)), length(s.data))
end

for (out, in) in [(SpiOutFd, SpiInFd), (SpiOutHdWrite, SpiInHdWrite), (SpiOutHdRead, SpiInHdRead)]
	@eval begin
		start(mod::Ptr{Spi}, send::Ref{$out}, recv::Ref{$in},
				actual_recv_len::Ref{Csize_t} = C_NULL(Csize_t)) =
			start(mod, (send, ), (recv, ), actual_recv_len)

		start(mod::Ptr{Spi}, send::Ref{$out}) = send(mod, (send, ))
	end
end

stop(mod::Ptr{Spi}) =
	act(ccall(("b0_spi_stop", "libbox0"), ResultCode, (Ptr{Spi}, ), mod))

active_state(mod::Ptr{Spi}, bSS::UInt8, val::Cbool) =
	act(ccall(("b0_spi_active_state_set", "libbox0"), ResultCode,
		(Ptr{Spi}, UInt8, Cbool), mod, bSS, val))

#NOTE: remove in future if julia convert Bool and Cbool transparently
active_state(mod::Ptr{Spi}, bSS::UInt8, val::Bool) =
	active_state(mod, bSS, Cbool(val))

active_state(mod::Ptr{Spi}, bSS::UInt8, val::Ref{Cbool}) =
	act(ccall(("b0_spi_active_state_get", "libbox0"), ResultCode,
		(Ptr{Spi}, UInt8, Ref{Cbool}), mod, bSS, val))
