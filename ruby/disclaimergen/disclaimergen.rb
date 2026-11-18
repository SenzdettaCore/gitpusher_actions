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
CONFIG = File.join(ROOT, ".action", "config", "disclaimergen.md").freeze
OUTPUT = File.join(ROOT, ".docs", "disclaimer.md").freeze

if ! Dir.exist?(ROOT) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mRoot: \x1b[0;32m%s \x1b[0mnot found!\n",
        ROOT,
    )
    exit(1)
end

CONTENT = <<~'EOS'.chomp
    # DISCLAIMER

    ## **Version 0.1 (Experimental Status)**
    This tool is currently in its early **v0.1** stage and is considered **unstable**. <br>
    You may encounter bugs, system errors, or unexpected behavior. <br>
    Additionally, core structures, commands, and language configurations are highly subject to change in future updates.
EOS

extra = File.exist?(CONFIG) ?
    File.read(CONFIG).rstrip :
    ""

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.write(
    OUTPUT,
    extra.empty? ?
        CONTENT :
        "#{CONTENT}\n\n#{extra}",
)

printf(
    "\x1b[0;32m[+] \x1b[0mGenerated: \x1b[0;32m%s\x1b[0m\n",
    OUTPUT.delete_prefix("#{ROOT}/"),
)

# Copyright (c) 2026 Senzdetta