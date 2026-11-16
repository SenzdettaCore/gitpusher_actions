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

ROOT = ENV.fetch("__root_project__").freeze
DOCS = File.join(ROOT, ".docs").freeze
SELF = "__more__.md".freeze
OUTPUT = File.join(DOCS, SELF).freeze

if ! Dir.exist?(DOCS) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mFolder: \x1b[0;32m%s \x1b[0mnot found!\n",
        DOCS,
    )
    exit(1)
end

files = Dir.children(DOCS).select {
    |f| File.extname(f) == ".md" &&
        File.file?(File.join(DOCS, f))
}.reject {
    |f| f == SELF
}.sort

links = files.map {
    |f| "[#{File.basename(f, ".md")}](#{f})"
}

File.write(
    OUTPUT,
    [
        "# MORE",
        *(
            links.empty? ?
                [] :
                ["", *links]
        ),
    ].join("\n"),
)

printf(
    "\x1b[0;32m[+] \x1b[0mGenerated: \x1b[0;32m%s \x1b[1;90m(\x1b[0;36m%d \x1b[0;37mfiles\x1b[1;90m)\x1b[0m\n",
    OUTPUT, files.length,
)

# Copyright (c) 2026 Senzdetta