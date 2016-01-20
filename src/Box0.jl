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

#why baremodule? because we need to define a type "Module"
baremodule Box0

import Base
import Base: include, println, one, print, bytestring, call, convert, join
import Base: eval, @eval, assert, @assert
import Base: start, done, next, length, showerror, error, sizeof
import Base: write, read, htol, ltoh, seek, colon
import Base: Csize_t, Cint, IO, Ptr, Ref, Cdouble, Cfloat, Cuintmax_t, Cstring
import Base: unsafe_load, unsafe_store!, pointer_from_objref, pointer
import Base: setindex!, getindex
import Base: zero, one, ceil, zip
import Base: >, <, <=, >=, !, +, ==, *, !=, |, &, /, <:
import Base: Exception, VersionNumber, Type, IOBuffer

#Constuct C_NULL of different types
C_NULL{T}(::Type{T} = Type{Void}) = Ptr{T}(0)

eval(e::Expr) = eval(Box0, e)

# like Cint, Csize_t and other...
typealias Cbool Cint

convert(::Type{Bool}, x::Cbool) = (x != 0)

abstract Bitsize
abstract Buffer
abstract Capabilities
abstract ChannelConfiguration
abstract ChannelSequence
abstract Label
abstract Reference
abstract Speed
abstract Stream
abstract Repeat
abstract I2cVersion

abstract StreamValue

include("first_include.jl")
include("basic.jl")
include("result_exception.jl")
include("device.jl")

include("backend/usb.jl")

include("property/property.jl")
include("property/count.jl")
include("property/last_include.jl")

include("module/module.jl")
include("module/ain.jl")
include("module/aout.jl")
include("module/dio.jl")
include("module/pwm.jl")
include("module/spi.jl")
include("module/i2c.jl")
include("module/last_include.jl")

end
