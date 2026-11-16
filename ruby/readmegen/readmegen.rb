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

require "yaml"
require "fileutils"

ROOT = ENV.fetch("__root_project__").freeze
CONFIG = File.join(ROOT, ".action", "config", "readmegen.yaml").freeze

HEADER_KEYS = %w[output project version language platform license description].freeze
SECTION_NAMES = %w[features disclaimer installation usage_example more].freeze

def fail_with(fmt, *args)
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0m" + fmt + "\n",
        *args,
    )
    exit(1)
end

def shield(text)
    text.to_s.gsub("-", "--").gsub("_", "__").gsub(" ", "_")
end

def badge(label, message, logo)
    "<img src=\"https://img.shields.io/badge/#{shield(label)}-#{shield(message)}-blue?style=square&logo=#{logo}&v=1\" />"
end

def docpath_of(body, name)
    path = body["docpath"].to_s.strip

    if path.empty? then
        fail_with(
            "Config: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32mdocpath \x1b[0mis required!",
            name,
        )
    end

    path
end

def items_of(body, name)
    items = body["items"]

    if ! items.is_a?(Array) || items.empty? then
        fail_with(
            "Config: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32mitems \x1b[0mmust be a list!",
            name,
        )
    end

    items.map(&:to_s)
end

def link_for(path)
    "[#{File.basename(path, ".md").gsub(/\A_+|_+\z/, "")}](#{path})"
end

if ! File.exist?(CONFIG) then
    fail_with(
        "Config: \x1b[0;32m%s \x1b[0mnot found!",
        CONFIG,
    )
end

cfg = YAML.safe_load_file(CONFIG)

if ! cfg.is_a?(Hash) then
    fail_with(
        "Config: \x1b[0;32m%s \x1b[0mempty or invalid format!",
        CONFIG,
    )
end

HEADER_KEYS.each do |key|
    if cfg[key].to_s.strip.empty? then
        fail_with(
            "Config: \x1b[0;32m%s \x1b[0mis empty field!",
            key,
        )
    end
end

sections = cfg["sections"]

if ! sections.is_a?(Array) || sections.empty? then
    fail_with(
        "Config key: \x1b[0;32msections \x1b[0mmust be a list!",
    )
end

project = cfg["project"].to_s
command = project.downcase

blocks = []

blocks.push(<<~HTML.chomp)
    <div align="center">
        #{badge(project, cfg["version"], cfg["language"])}
        #{badge("Platform", cfg["platform"].to_s.capitalize, cfg["platform"])}
        <a href="LICENSE">
            #{badge("License", cfg["license"], "github")}
        </a>
    </div>
HTML

blocks.push("# #{project}\n#{cfg["description"]}")

sections.each do |entry|
    if ! entry.is_a?(Hash) || entry.length != 1 then
        fail_with(
            "Config key: \x1b[0;32msections \x1b[0mitem must have exactly one key!",
        )
    end

    name = entry.keys.first.to_s
    body = entry.values.first

    if ! SECTION_NAMES.include?(name) then
        fail_with(
            "Config: \x1b[0;32m%s \x1b[0munknown section!",
            name,
        )
    end

    if ! body.is_a?(Hash) then
        fail_with(
            "Config: \x1b[0;32m%s \x1b[0mmust be a map \x1b[1;90m(\x1b[0;32mkey: \x1b[0;36mvalue\x1b[1;90m)\x1b[0m",
            name,
        )
    end

    title = name.split("_").map(&:capitalize).join(" ")

    case name
    when "features"
        list = items_of(body, name).map { |i| "- #{i}" }
        blocks.push(
            "## #{title}\n#{(list + ["- And more features."]).join("\n")}",
        )
    when "disclaimer"
        path = docpath_of(body, name)
        blocks.push(
            "## #{title}\n" \
            "Please read #{link_for(path)} before using this tool. </br>\n" \
            "Use this software at your own risk. </br>\n" \
            "The author is not responsible for any damage, data loss, or issues that may result from its use."
        )
    when "installation"
        path = docpath_of(body, name)
        file = File.join(ROOT, path)

        if ! File.exist?(file) then
            fail_with(
                "File: \x1b[0;32m%s \x1b[0mnot found!",
                file,
            )
        end

        code = File.read(file)[/```bash\n(.*?)\n```/m, 1]

        if code.nil? then
            fail_with(
                "File: \x1b[0;32m%s \x1b[0mhas no bash usage block!",
                file,
            )
        end

        code = code.lines.map {
            |l| l.chomp.sub(
                /\s+#\s*<options\.\.\.>\s*\z/,
                "",
            )
        }.join("\n")

        blocks.push(
            "## #{title}\nQuick install:\n```bash\n#{code}\n```\n" \
            "For more detailed installation instructions, see #{link_for(path)}."
        )
    when "usage_example"
        list = items_of(body, name).map {
            |i| "#{command} #{i}"
        }
        blocks.push(
            "## #{title}\n```bash\n#{list.join("\n")}\n```\nAnd more commands.",
        )
    when "more"
        path = docpath_of(body, name)
        blocks.push(
            "## #{title}\nFor further information, visit: #{link_for(path)}",
        )
    end
end

blocks.push("<code>Made with ❤ ~love.</code>")

output = File.join(ROOT, cfg["output"].to_s.strip)

FileUtils.mkdir_p(File.dirname(output))
File.write(output, blocks.join("\n\n"))

printf(
    "\x1b[0;32m[+] \x1b[0mGenerated: \x1b[0;32m%s \x1b[1;90m(\x1b[0;36m%d \x1b[0;37msections\x1b[1;90m)\x1b[0m\n",
    output, sections.length,
)

# Copyright (c) 2026 Senzdetta