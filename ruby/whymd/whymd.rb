#!/usr/bin/env ruby
# https://github.com/SenzdettaCore/gitpusher_actions

# Copyright (C) 2026 Senzdetta (https://github.com/Senzdetta)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

require "fileutils"

ROOT = ENV.fetch("__root_project__").freeze
OUTPUT = File.join(ROOT, ".docs", "why.md").freeze

CONTENT = <<~'EOS'.chomp
    # WHY

    ### A Small Personal Note
    If you’ve landed on this page, you’ve probably noticed that the **Issues** and **Pull Requests (PRs)** features on this repository are intentionally disabled. </br>
    This document isn’t meant to be unfriendly; it is simply here to provide full transparency regarding my personal boundaries, time, and energy.

    ## Real Life & Time Constraints
    Outside of the open-source world, I have a full-time job and a real life that demand most of my time and attention. </br>
    Whenever I do catch a break and get some free time, I like to spend it playing around with the CLI. </br>
    More often than not, while experimenting, I find gaps or missing functionalities that I need. </br>
    This tool was born solely to **fill MY own gaps and needs**, not to build a commercial-grade product designed for everyone.

    ## Keeping My Hobby Fun and Peaceful
    For me, coding in this repository is a hobby. </br>
    And the whole point of a hobby is to bring joy, peace, and stress relief after a long day of work. </br>
    I do not want this passion to turn into a "second job" with endless demands, which would inevitably lead to burnout. </br>
    I want to keep this small corner of the internet a peaceful playground for myself.

    ## Code That is "Good Enough," Not Perfect
    To be completely honest, I don't have the time to worry about clean code, refactoring code smells, or designing the perfect architecture. </br>
    In the limited free time I have, my principle is simple: **as long as the code works and is good enough—at least good enough for me.** </br>
    I am fully aware that this "just make it work" approach will inevitably leave bugs, flaws, and messy code, which naturally invites dozens of Issues and PRs. </br>
    However, because I don't have the bandwidth to review, discuss, or merge them, keeping those features enabled would be pointless. </br>
    If you find yourself frustrated by the code quality here, please read this point from the beginning.

    ## The Best Solution: Feel Free to Fork!
    The beauty of open-source lies in its freedom. </br>
    If you find this tool useful but feel it needs fixes or improvements:
    * **Please feel free to Fork this repository.**
    * You are entirely free to modify it, clean up the messy code, or add new features in your own repository.

    Thank you so much "if" you understand, respect my busy life, and honor my personal boundaries.

    <code>“Respect.”</code>
EOS

if ! Dir.exist?(ROOT) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mRoot: \x1b[0;32m%s \x1b[0mnot found!\n",
        ROOT,
    )
    exit(1)
end

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.write(OUTPUT, CONTENT.rstrip)

printf(
    "\x1b[0;32m[+] \x1b[0mGenerated: \x1b[0;32m%s\x1b[0m\n",
    OUTPUT,
)

# Copyright (c) 2026 Senzdetta