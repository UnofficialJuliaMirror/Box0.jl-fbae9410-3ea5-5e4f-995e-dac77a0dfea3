#
# This file is part of Box0.jl.
# Copyright (C) 2015, 2016 Kuldeep Singh Dhaka <kuldeepdhaka9@gmail.com>
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

export I2c, I2cTask, I2cTaskFlags
export I2cTaskWrite, I2cTaskRead
export start, stop
export write8_read, write_read, read, write, slave_detect, slave_id
export I2C_TASK_LAST, I2C_TASK_WRITE, I2C_TASK_READ, I2C_TASK_DIR_MASK

typealias I2cTaskFlags Cint
I2C_TASK_LAST = I2cTaskFlags(1 << 0) # Last task to execute
I2C_TASK_WRITE = I2cTaskFlags(0 << 1) # Perform write
I2C_TASK_READ = I2cTaskFlags(1 << 1) # Perform read
I2C_TASK_DIR_MASK = I2cTaskFlags(1 << 1)

immutable I2cTask
	flags::I2cTaskFlags # Transfer flags
	addr::UInt8  # Slave address
	data::Ptr{Void} # Pointer to data
	count::Csize_t # Number of bytes to transfer
end

I2cTask{T}(flags::I2cTaskFlags, addr::UInt8, data::Array{T}) =
	I2cTask(flags, addr, Ptr{Void}(pointer(data)), Csize_t(sizeof(data)))

function I2cTaskRead{T}(addr::UInt8, data::Array{T}; last::Bool = false)
	flags::I2cTaskFlags = I2C_TASK_READ
	if last
		flags |= I2C_TASK_LAST
	end
	I2cTask(flags, addr, data)
end

function I2cTaskWrite{T}(addr::UInt8, data::Array{T}; last::Bool = false)
	flags::I2cTaskFlags = I2C_TASK_WRITE
	if last
		flags |= I2C_TASK_LAST
	end
	I2cTask(flags, addr, data)
end


immutable I2c
	header::Module_
	buffer::Ptr{Buffer}
	label::Ptr{Label}
	ref::Ptr{Ref_}
	version::Ptr{I2cVersion}
end

start(mod::Ptr{I2c}, tasks::Ref{I2cTask}, failed_task_index::Ref{Cint},
		failed_task_ack::Ref{Cint}) =
	act(ccall(("b0_i2c_start", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cTask}, Ptr{Cint}, Ptr{Cint}),
		mod, tasks, failed_task_index, failed_task_ack))

function start(mod::Ptr{I2c}, tasks::Ref{I2cTask})
	failed_task_index = Ref{Cint}(0)
	failed_task_ack = Ref{Cint}(0)
	start(mod, tasks, failed_task_index, failed_task_ack)
	return failed_task_index[], failed_task_ack[]
end

start(mod::Ptr{I2c}, tasks::Array{I2cTask}) = start(mod, pointer(tasks))
start(mod::Ptr{I2c}, task::I2cTask) = (
	(task.flags & I2C_TASK_LAST) != 0 || error("LAST flag missing on task");
	start(mod, Ref(task))
)

stop(mod::Ptr{I2c}) =
	act(ccall(("b0_i2c_stop", "libbox0"), ResultCode, (Ptr{I2c}, ), mod))

read(mod::Ptr{I2c}, addr::UInt8, data::Ref{Void}, count::Csize_t) =
	act(ccall(("b0_i2c_read", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{Void}, Csize_t), mod, addr, data, count))

read{T}(mod::Ptr{I2c}, addr::UInt8, data::Array{T}) =
	read(mod, addr, Ptr{Void}(pointer(data)), Csize_t(sizeof(data)))

write8_read(mod::Ptr{I2c}, addr::UInt8, write::UInt8,
		read_data::Ptr{Void}, read_count::Csize_t) =
	act(ccall(("b0_i2c_write8_read", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, UInt8, Ptr{Void}, Csize_t),
		mod, addr, write, read_data, read_count))

write8_read{T}(mod::Ptr{I2c}, addr::UInt8, write::UInt8, read::Array{T}) =
	write8_read(mod, addr, write, Ptr{Void}(pointer(read)), Csize_t(sizeof(read)))

write_read(mod::Ptr{I2c}, addr::UInt8, write_data::Ptr{Void},
		write_count::Csize_t, read_data::Ptr{Void}, read_count::Csize_t) =
	act(ccall(("b0_i2c_write_read", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, Ptr{Void}, Csize_t, Ptr{Void}, Csize_t),
		mod, addr, write, write_data, write_count, read_data, read_count))

write_read{T,U}(mod::Ptr{I2c}, addr::UInt8, write::Array{T}, read::Array{U}) =
	write_read(mod, addr, Ptr{Void}(pointer(write)), Csize_t(sizeof(read)),
		Ptr{Void}(pointer(read)), Csize_t(sizeof(read)))

write(mod::Ptr{I2c}, addr::UInt8, data::Ptr{Void}, count::Csize_t) =
	act(ccall(("b0_i2c_write", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, Ptr{Void}, Csize_t), mod, addr, data, count))

write{T}(mod::Ptr{I2c}, addr::UInt8, data::Array{T}) =
	write(mod, addr, Ptr{Void}(pointer(data)), Csize_t(sizeof(data)))

slave_id(mod::Ptr{I2c}, addr::UInt8,
		manuf::Ref{UInt16}, part::Ref{UInt16}, rev::Ref{UInt8}) =
	act(ccall(("b0_i2c_slave_detect", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, Ref{UInt16}, Ref{UInt8}, Ref{UInt8}),
		mod, addr, manuf, part, rev))

function slave_id(mod::Ptr{I2c}, bSlaveAddr::UInt8)
	manuf = Ref{UInt16}(0)
	part = Ref{UInt16}(0)
	rev = Ref{UInt8}(0)
	slave_id(mod, bSlaveAddr, manuf, part, rev)
	return manuf, part, rev
end

slave_detect(mod::Ptr{I2c}, addr::UInt8, detected::Ref{Cbool}) =
	act(ccall(("b0_i2c_slave_detect", "libbox0"), ResultCode,
		(Ptr{I2c}, UInt8, Ptr{Cbool}), mod, addr, detected))

function slave_detect(mod::Ptr{I2c}, addr::UInt8)
	val = Ref{Cbool}(0)
	slave_detect(mod, addr, val)
	return Bool(val[])
end
