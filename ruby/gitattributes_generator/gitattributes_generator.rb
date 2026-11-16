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
OUTPUT = File.join(ROOT, ".gitattributes").freeze

CONTENT = <<~EOS.chomp
    .action/** linguist-vendored
    .artifact/** linguist-vendored
    .blsys/** linguist-vendored
    .vscode/** linguist-vendored

    vendor/** linguist-vendored

    install.sh linguist-vendored
    uninstall.sh linguist-vendored
    manifest.meta linguist-vendored
    go.mod linguist-vendored
    go.sum linguist-vendored
    requirements.txt linguist-vendored
    dub.json linguist-vendored
    pubspec.yaml linguist-vendored
EOS

if ! Dir.exist?(ROOT) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mRoot: \x1b[0;32m%s \x1b[0mnot found!\n",
        ROOT,
    )
    exit(1)
end

File.write(OUTPUT, CONTENT.rstrip)

printf(
    "\x1b[0;32m[+] \x1b[0mGenerated: \x1b[0;32m%s\x1b[0m\n",
    OUTPUT,
)

# Copyright (c) 2026 Senzdetta