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
CONFIG = File.join(ROOT, ".action", "config", "iugen.ini").freeze
DOCS = File.join(ROOT, ".docs").freeze

SECTIONS = ["Init", "Section: Installation", "Section: Uninstallation"].freeze

def fail_with(fmt, *args)
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0m" + fmt + "\n",
        *args,
    )
    exit(1)
end

def parse_ini(path)
    data = {}
    current = nil

    File.readlines(path, chomp: true).each_with_index do |raw, idx|
        line = raw.strip
        num = idx + 1

        next if line.empty? || line.start_with?(";", "#")

        if (m = line.match(/\A\[(.+)\]\z/)) then
            current = m[1].strip

            if ! SECTIONS.include?(current) then
                fail_with(
                    "Config: \x1b[0;32m%s\x1b[1;90m:\x1b[0;32m%d \x1b[0munknown section \x1b[1;90m[\x1b[0;32m%s\x1b[1;90m]\x1b[0m",
                    path, num, current,
                )
            end

            data[current] ||= {}
            next
        end

        if current.nil? then
            fail_with(
                "Config: \x1b[0;32m%s\x1b[1;90m:\x1b[0;32m%d \x1b[0mkey outside of a section!",
                path, num,
            )
        end

        m = line.match(
            /\A(?:"([^"]+)"|([^=\s"][^=]*?))\s*=\s*(?:"(.+)"|([^"].*))\z/,
        )

        if m.nil? then
            fail_with(
                "Config: \x1b[0;32m%s\x1b[1;90m:\x1b[0;32m%d \x1b[0minvalid line, expected \x1b[0;37m\"\x1b[0;32mkey\x1b[0;37m\" \x1b[1;90m= \x1b[0;37m\"\x1b[0;32mvalue\x1b[0;37m\"\x1b[0m",
                path, num,
            )
        end

        key = (m[1] || m[2]).strip
        value = (m[3] || m[4]).strip

        if data[current].key?(key) then
            fail_with(
                "Config: \x1b[0;32m%s\x1b[1;90m:\x1b[0;32m%d \x1b[0mduplicate key \x1b[0;32m%s\x1b[0m",
                path, num, key,
            )
        end

        data[current][key] = value
    end

    data
end

def render(title, usage, options)
    parts = [
        "# #{title}",
        "Usage:\n```bash\n#{usage}\n```",
    ]

    if ! options.empty? then
        list = options.map {
            |key, desc| "* #{key}\n└── #{desc}"
        }.join("\n\n")
        parts.push(
            "Optional options (can be used together):\n```text\n#{list}\n```",
        )
    end

    parts.join("\n\n")
end

if ! File.exist?(CONFIG) then
    fail_with(
        "Config: \x1b[0;32m%s \x1b[0mnot found!",
        CONFIG,
    )
end

cfg = parse_ini(CONFIG)
project = cfg.dig(
    "Init",
    "project",
).to_s.strip

if project.empty? then
    fail_with(
        "Config key: \x1b[1;90m[\x1b[0;32mInit\x1b[1;90m] \x1b[0;32mproject \x1b[0mis required!",
    )
end

repo = File.basename(project)
command = repo.downcase

install_usage = "git clone https://#{project}\nbash #{repo}/install.sh # <options...>"
uninstall_usage = "#{command} --selfuninstall # <options...>"

install_opts = cfg.fetch("Section: Installation", {})
uninstall_opts = cfg.fetch("Section: Uninstallation", {})

FileUtils.mkdir_p(DOCS)

{
    "install.md"=> render(
        "INSTALL",
        install_usage, install_opts,
    ),
    "uninstall.md" => render(
        "UNINSTALL",
        uninstall_usage, uninstall_opts,
    ),
}.each do |name, content|
    output = File.join(DOCS, name)
    File.write(output, content)
    printf(
        "\x1b[0;32m[+] \x1b[0mGenerated: \x1b[0;32m%s\x1b[0m\n",
        output,
    )
end

# Copyright (c) 2026 Senzdetta