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

export Property
export STREAM, CHAN_SEQ, REF, SPEED, BITSIZE, CAPAB, COUNT, LABEL, BUFFER
export REPEAT, CHAN_CONFIG, BIT_ORDER, ACTIVE_STATE, I2C_VERSION, I2C_PULLUP
export PWM_INITAL, PWM_SYMMERTRIC, SPI_MODE, SPI_VARIANT

typealias PropertyType Cint
const STREAM = PropertyType(-2)
const CHAN_SEQ = PropertyType(-1)
const REF = PropertyType(1)
const SPEED = PropertyType(2)
const BITSIZE = PropertyType(3)
const CAPAB = PropertyType(4)
const COUNT = PropertyType(5)
const LABEL = PropertyType(6)
const BUFFER = PropertyType(7)
const REPEAT = PropertyType(8)
const CHAN_CONFIG = PropertyType(9)
const BIT_ORDER = PropertyType(10)
const ACTIVE_STATE = PropertyType(11)
const I2C_VERSION = PropertyType(101)
const I2C_PULLUP = PropertyType(102)
const PWM_INITAL = PropertyType(101)
const PWM_SYMMERTRIC = PropertyType(102)
const SPI_MODE = PropertyType(101)
const SPI_VARIANT = PropertyType(102)

immutable Property
	type_::PropertyType

	module_::Ptr{Module}

	backend_data::Ptr{Void}
	frontend_data::Ptr{Void}
end
