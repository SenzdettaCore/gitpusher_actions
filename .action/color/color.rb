# https://github.com/SenzdettaCore/gitpusher_actions

module Color
    def N = "\x1b[0m".freeze

    def R = "\x1b[1;31m".freeze
    def G = "\x1b[1;32m".freeze
    def Y = "\x1b[1;33m".freeze
    def B = "\x1b[1;34m".freeze
    def P = "\x1b[1;35m".freeze
    def C = "\x1b[1;36m".freeze
    def W = "\x1b[1;37m".freeze
    def DG = "\x1b[1;90m".freeze

    def RR = "\x1b[0;31m".freeze
    def GG = "\x1b[0;32m".freeze
    def YY = "\x1b[0;33m".freeze
    def BB = "\x1b[0;34m".freeze
    def PP = "\x1b[0;35m".freeze
    def CC = "\x1b[0;36m".freeze
    def WW = "\x1b[0;37m".freeze
    def DGG = "\x1b[0;90m".freeze

    module_function(
        :N,
        :R, :G, :Y, :B, :P, :C, :W, :DG,
        :RR, :GG, :YY, :BB, :PP, :CC, :WW, :DGG,
    )
end

# Copyright (c) 2026 Senzdetta