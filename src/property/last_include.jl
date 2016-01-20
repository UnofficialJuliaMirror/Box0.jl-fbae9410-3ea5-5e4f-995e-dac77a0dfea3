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

for d in [(Bitsize, "bitsize"), (Buffer, "buffer"), (Capabilities, "capab"),
		(Count, "count"), (ChannelConfiguration, "chan_config"), (ChannelSequence, "chan_seq"),
		(Label, "label"), (Reference, "ref"), (Speed, "speed"), (Stream, "stream"),
		(Repeat, "repeat")]
	t::Type = d[1]
	n::AbstractString = d[2]

	func = @eval "b0_"*$n*"_info"
	@eval info(mod::Ptr{$t}) = act(ccall(($func, "libbox0"), ResultCode, (Ptr{$t}, ), mod))
	func = @eval "b0_"*$n*"_cache_flush"
	@eval cache_flush(mod::Ptr{$t}) = act(ccall(($func, "libbox0"), ResultCode, (Ptr{$t}, ), mod))
end
