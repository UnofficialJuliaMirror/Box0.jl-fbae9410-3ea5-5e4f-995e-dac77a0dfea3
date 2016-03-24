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

module Box0


#Constuct C_NULL of different types
C_NULL{T}(::Type{T} = Type{Void}) = Ptr{T}(0)

# like Cint, Csize_t and other...
typealias Cbool Cint

Base.convert(::Type{Bool}, x::Cbool) = (x != 0)

export deref #others can use
deref{T}(v::Ptr{T}) = unsafe_load(v, 1)

include("first_include.jl")
include("basic.jl")
include("result_exception.jl")
include("device.jl")

include("backend/usb.jl")

include("property/property.jl")
include("property/count.jl")
include("property/buffer.jl")
include("property/capab.jl")
include("property/chan_config.jl")
include("property/ref.jl")
include("property/stream.jl")
include("property/repeat.jl")
include("property/i2c_version.jl")
include("property/label.jl")
include("property/bitsize.jl")
include("property/chan_seq.jl")
include("property/speed.jl")
include("property/last_include.jl")

include("module/module.jl")
include("module/ain.jl")
include("module/aout.jl")
include("module/dio.jl")
include("module/pwm.jl")
include("module/spi.jl")
include("module/i2c.jl")
include("module/last_include.jl")

export Usb

end
