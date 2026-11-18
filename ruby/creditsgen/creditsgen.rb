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
CONFIG = File.join(ROOT, ".action", "config", "creditsgen.yaml").freeze
OUTPUT = File.join(ROOT, ".docs", "credits.md").freeze
LINK_PREFIX = "../".freeze

SOURCE_KEYS = %w[name url avatar items].freeze
ITEM_KEYS = %w[module type path license license_file readme_file modified_info].freeze

if ! Dir.exist?(ROOT) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mRoot: \x1b[0;32m%s \x1b[0mnot found!\n",
        ROOT,
    )
    exit(1)
end

if ! File.exist?(CONFIG) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[0mnot found!\n",
        CONFIG.delete_prefix("#{ROOT}/"),
    )
    exit(1)
end

cfg = YAML.safe_load_file(CONFIG)

if ! cfg.is_a?(Hash) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[0mempty or invalid format!\n",
        CONFIG.delete_prefix("#{ROOT}/"),
    )
    exit(1)
end

heading = cfg["title"] || "CREDITS"
sources = cfg["sources"]

if ! sources.is_a?(Array) || sources.empty? then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mConfig key: \x1b[0;32msources \x1b[0mmust be a list!\n",
    )
    exit(1)
end

blocks = []

sources.each do |source|
    if ! source.is_a?(Hash) then
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mConfig key: \x1b[0;32msource \x1b[0mmust be a map \x1b[1;90m(\x1b[0;32mkey: \x1b[0;36mvalue\x1b[1;90m)\x1b[0m\n",
        )
        exit(1)
    end

    SOURCE_KEYS.each do |key|
        if source[key].to_s.strip.empty? then
            printf(
                $stderr,
                "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mis empty field!\n",
                source["name"], key,
            )
            exit(1)
        end
    end

    if ! source["items"].is_a?(Array) then
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32mitems \x1b[0mmust be a list!\n",
            source["name"],
        )
        exit(1)
    end

    rendered = []

    source["items"].each do |item|
        if ! item.is_a?(Hash) then
            printf(
                $stderr,
                "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32mitem \x1b[0mmust be a map \x1b[1;90m(\x1b[0;32mkey: \x1b[0;36mvalue\x1b[1;90m)\x1b[0m\n",
                source["name"],
            )
            exit(1)
        end

        ITEM_KEYS.each do |key|
            if item[key].to_s.strip.empty? then
                printf(
                    $stderr,
                    "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[1;90m/ \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mis empty field!\n",
                    source["name"], item["module"], key,
                )
                exit(1)
            end
        end

        if ! File.exist?(File.join(ROOT, item["license_file"])) then
            printf(
                $stderr,
                "\x1b[1;31m[!] \x1b[0mFile: \x1b[0;32m%s \x1b[1;90m/ \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mnot found!\n",
                source["name"], item["module"], item["license_file"],
            )
            exit(1)
        end

        if ! File.exist?(File.join(ROOT, item["readme_file"])) then
            printf(
                $stderr,
                "\x1b[1;31m[!] \x1b[0mFile: \x1b[0;32m%s \x1b[1;90m/ \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mnot found!\n",
                source["name"], item["module"], item["readme_file"],
            )
            exit(1)
        end

        if ! File.exist?(File.join(ROOT, item["modified_info"])) then
            printf(
                $stderr,
                "\x1b[1;31m[!] \x1b[0mFile: \x1b[0;32m%s \x1b[1;90m/ \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mnot found!\n",
                source["name"], item["module"], item["modified_info"],
            )
            exit(1)
        end

        rendered.push(<<~HTML.chomp.gsub(/^/, "      "))
            <b>#{item["module"]}</b> · #{item["type"]}<br>
            <code>#{item["path"]}</code><br>
            <a href="#{LINK_PREFIX}#{item["license_file"]}">#{item["license"]}</a> · <a href="#{LINK_PREFIX}#{item["readme_file"]}">README</a> · <a href="#{LINK_PREFIX}#{item["modified_info"]}">Modified</a>
        HTML
    end

    body = rendered.join("<br><br>\n")

    blocks.push(<<~HTML)
        <table>
          <tr>
            <td width="90" align="center" valign="middle"><img src="#{source["avatar"]}" width="70" /></td>
            <td valign="top">
              <b><a href="#{source["url"]}">#{source["name"]}</a></b><br><br>
        #{body}
            </td>
          </tr>
        </table>
    HTML
end

html = blocks.join("\n")

FileUtils.mkdir_p(File.dirname(OUTPUT))
File.write(OUTPUT, "# #{heading}\n\n#{html.chomp}")

printf(
    "\x1b[0;32m[+] \x1b[0mGenerated: \x1b[0;32m%s \x1b[1;90m(\x1b[0;36m%d \x1b[0;37msources\x1b[1;90m)\x1b[0m\n",
    OUTPUT.delete_prefix("#{ROOT}/"), sources.length,
)

# Copyright (c) 2026 Senzdetta