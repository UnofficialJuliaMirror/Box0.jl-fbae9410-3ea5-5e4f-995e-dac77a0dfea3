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

export info, cache_flush

for (t::Type, n::AbstractString) in [(Bitsize, "bitsize"), (Buffer, "buffer"),
		(Capab, "capab"), (Count, "count"),
		(ChanConfig, "chan_config"), (ChanSeq, "chan_seq"),
		(Label, "label"), (Ref_, "ref"), (Speed, "speed"),
		(Stream, "stream"), (Repeat, "repeat")]

	func_info = @eval "b0_"*$n*"_info"
	func_cache_flush = @eval "b0_"*$n*"_cache_flush"

	@eval begin
		info(prop::Ptr{$t}) = act(ccall(($func_info, "libbox0"),
			ResultCode, (Ptr{$t}, ), mod))

		cache_flush(prop::Ptr{$t}) = act(ccall(($func_cache_flush, "libbox0"),
			ResultCode, (Ptr{$t}, ), mod))
	end
end
