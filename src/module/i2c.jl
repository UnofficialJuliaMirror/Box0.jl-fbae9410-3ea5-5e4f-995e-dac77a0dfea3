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

export Spi, I2cOutRead, I2cOutWrite, I2cInRead, I2cInWrite
export start, stop
export write8_read, read, write, slave_detect, slave_id

i2c_address(bSlaveAddr::UInt8, read::Bool) = ((bSlaveAddr << 1) | (read ? 0x01 : 0x00))

type I2cOutRead
	bAddress::UInt8
	bRead::UInt8

	I2cOutRead(bSlaveAddr::UInt8, bRead::UInt8) = (
		@assert bRead <= 254;
		new(i2c_address(bSlaveAddr, true), bRead)
	)
end

type I2cOutWrite
	bAddress::UInt8
	bWrite::UInt8
	bData::Array{UInt8}
end

I2cOutWrite(bSlaveAddr, bWrite) = (
	@assert bWrite <= 254;
	I2cOutWrite(i2c_address(bSlaveAddr, false), bWrite, Array{UInt8}(bWrite))
)

# in-read-query
type I2cInRead
	bACK::UInt8
	bData::Array{UInt8}
end

I2cInRead(len::UInt8) = I2CInRead(0, Array{UInt8}(len))

# in-write-query
type I2cInWrite
	bACK::UInt8
end

immutable I2c
	header::Module_
	buffer::Ptr{Buffer}
	label::Ptr{Label}
	ref::Ptr{Ref_}
	version::Ptr{I2cVersion}
end

start(mod::Ptr{I2c}, send::Ptr{Void}, send_len::Csize_t, recv::Ptr{Void}, recv_len::Csize_t,
		actual_recv_len::Ref{Csize_t} = C_NULL(Csize_t)) =
	act(ccall(("b0_i2c_start", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{Void}, Csize_t, Ptr{Void}, Csize_t, Ref{Csize_t}),
		mod, send, send_len, recv, recv_len, actual_recv_len))

start(mod::Ptr{I2c}, send::Ptr{Void}, send_len::Csize_t) =
	act(ccall(("b0_i2c_start_out", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{Void}, Csize_t), mod, send, send_len))

function i2c_array_pack(io::IO, arr::Array{UInt8})
	for d in arr
		write(io, htol(d))
	end
end

function i2c_send_pack(io::IO, send::Tuple)
	for i in send
		x = i[]
		if isa(x, I2cOutWrite)
			write(io, htol(x.bAddress))
			write(io, htol(x.bWrite))
			i2c_array_pack(io, x.bData)
		elseif isa(x, I2cOutRead)
			write(io, htol(x.bAddress))
			write(io, htol(x.bRead))
		else
			error("Unknown type of query used in tuple")
		end
	end
end

function i2c_recv_pack(io::IO, recv::Tuple)
	for i in recv
		x = i[]
		if isa(x, I2cInRead)
			write(io, x.bACK)
			i2c_array_pack(io, x.bData)
		elseif isa(x, I2cInWrite)
			write(io, x.bACK)
		else
			@assert "Type unknown"
		end
	end
end

function i2c_array_unpack(io::IO, arr::Array{UInt8})
	for i in 1:length(arr)
		arr[i] = ltoh(read(io, T))
	end
end

function i2c_recv_unpack(io::IO, recv::Tuple)
	for i in recv
		x = i[]
		if isa(x, I2cInRead)
			x.bACK = read(io, typeof(x.bACK))
			i2c_array_unpack(io, x.bData)
		elseif isa(x, I2cInWrite)
			x.bACK = write(io, typeof(x.bACK))
		else
			@assert "Type unknown"
		end
		i[] = x
	end
end

function i2c_verify_send_recv(send::Tuple, recv::Tuple)
	# verify that the recv buffer do not have more than send packets
	@assert length(send) >= length(recv)

	#verify for Out there is correct In type
	# if the recv tuple is smaller, then zip will limit the i, j values
	for (i, j) in zip(send, recv)
		i = i[]; j = j[]

		if isa(i, I2cOutRead)
			@assert isa(j, I2cInRead)
			@assert i.bRead == sizeof(j.bData)
		elseif isa(i, I2cOutWrite)
			@assert isa(j, I2cInWrite)
		else
			error("Unknown type of query used in tuple")
		end
	end
end

#send: Tuple{Ref{$d}, Ref{$d} ...} where I2cOutWrite, I2cOutRead
#recv: Tuple{Ref{$d}, Ref{$d} ...} where I2cInWrite, I2cInRead
function start(mod::Ptr{I2c}, send::Tuple, recv::Tuple,
						actual_recv_len::Ref{Csize_t} = C_NULL(Csize_t))

	i2c_verify_send_recv(send, recv)

	# Send buffer
	s = IOBuffer()
	i2c_send_pack(s, send)

	# recv buffer
	r = IOBuffer()
	i2c_recv_pack(r, recv)

	# read data
	start(mod, Ptr{Void}(pointer(s.data)), Csize_t(length(s.data)),
				Ptr{Void}(pointer(r.data)), Csize_t(length(r.data)),
				actual_recv_len)

	# extract back data
	seek(r, 0)
	i2c_recv_unpack(r, recv)
end

function start(mod::Ptr{I2c}, send::Tuple)
	s = IOBuffer()
	i2c_send_pack(s, send)
	start(mod, Ptr{Void}(pointer(s.data)), length(s.data))
end

for (out, in) in [(I2cOutWrite, I2cInWrite), (I2cOutRead, I2cInRead)]
	@eval begin
		start(mod::Ptr{I2c}, send::Ref{$out}, recv::Ref{$in},
				actual_recv_len::Ref{Csize_t} = C_NULL(Csize_t)) =
			start(mod, (send, ), (recv, ), actual_recv_len)

		start(mod::Ptr{I2c}, send::Ref{$out}) = send(mod, (send, ))
	end
end

stop(mod::Ptr{I2c}) =
	act(ccall(("b0_i2c_stop", "libbox0"), ResultCode, (Ptr{I2c}, ), mod))

read(mod::Ptr{I2c}, bSlaveAddr::UInt8, bData::Ref{UInt8}, bRead::UInt8) =
	act(ccall(("b0_i2c_read", "libbox0"), ResultCode,
		(Ptr{I2c}, Ref{UInt8}, UInt8), mod, bSlaveAddr, bData, bRead))

read(mod::Ptr{I2c}, bSlaveAddr::UInt8, bData::Array{UInt8}) =
	act(ccall(("b0_i2c_read", "libbox0"), ResultCode,
		(Ptr{I2c}, Ref{UInt8}, UInt8),
		mod, bSlaveAddr, pointer(bData), UInt8(length(bData))))

write8_read(mod::Ptr{I2c}, bSlaveAddr::UInt8,
					bData_read::UInt8, bData_write::Ref{UInt8}, bWrite::UInt8) =
	act(ccall(("b0_i2c_write8_read", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, UInt8, Ref{UInt8}, UInt8),
		mod, bSlaveAddr, bData_write, bData_read, bRead))

write8_read(mod::Ptr{I2c}, bSlaveAddr::UInt8, bData_write::UInt8, bData_read::Array{UInt8}) =
	write8_read(mod, bSlaveAddr, bData_read, pointer(bData_write), UInt8(length(bData_read)))

write(mod::Ptr{I2c}, bSlaveAddr::UInt8, bData::Ref{UInt8}, bWrite::UInt8) =
	act(ccall(("b0_i2c_write", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, Ref{UInt8}, UInt8), mod, bSlaveAddr, bData, bWrite))

write(mod::Ptr{I2c}, bSlaveAddr::UInt8, data::Array{UInt8}) =
	write(mod, bSlaveAddr, pointer(data), UInt8(length(data)))

slave_id(mod::Ptr{I2c}, bSlaveAddr::UInt8,
		manuf::Ref{UInt16}, part::Ref{UInt16}, rev::Ref{UInt8}) =
	act(ccall(("b0_i2c_slave_detect", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, Ref{UInt16}, Ref{UInt8}, Ref{UInt8}),
		mod, bSlaveAddr, manuf, part, rev))

slave_id(mod::Ptr{I2c}, bSlaveAddr::UInt8) = (
	manuf = Ref{UInt16}(0);
	part = Ref{UInt16}(0);
	rev = Ref{UInt8}(0);
	slave_id(mod, bSlaveAddr, manuf, part, rev);
	return manuf, part, rev
)

slave_detect(mod::Ptr{I2c}, bSlaveAddr::UInt8, detected::Ref{Cbool}) =
	act(ccall(("b0_i2c_slave_detect", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, Ptr{Cbool}), mod, bSlaveAddr, detected))

slave_detect(mod::Ptr{I2c}, bSlaveAddr::UInt8) = (
	val = Ref{Cbool}(0);
	slave_detect(mod, bSlaveAddr, val);
	return Bool(val[])
)
