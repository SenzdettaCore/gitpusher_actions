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

ROOT = ENV.fetch("__root_project__").freeze
CONFIG = File.join(ROOT, ".action", "config", "vergen.yaml").freeze
TARGET_KEYS = %w[File replace new].freeze

NEW_VERSION = "v0.1.#{Time.now.strftime("%Y%m%d")}".freeze

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

targets = YAML.safe_load_file(CONFIG)

if ! targets.is_a?(Array) || targets.empty? then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[0mmust be a non-empty list!\n",
        CONFIG.delete_prefix("#{ROOT}/"),
    )
    exit(1)
end

status = IO.popen(
    [
        "git", "-C", ROOT,
        "status", "--porcelain",
        "--", ".", ":(exclude).action",
    ],
    err: File::NULL, &:read
).to_s

if status.strip.empty? then
    printf(
        "\x1b[1;34m[*] \x1b[0mClean repo, skip update version.\n",
    )
    exit(0)
end

targets.each do |target|
    if ! target.is_a?(Hash) then
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32mtarget \x1b[0mmust be a map \x1b[1;90m(\x1b[0;32mkey: \x1b[0;36mvalue\x1b[1;90m)\x1b[0m\n",
        )
        exit(1)
    end

    TARGET_KEYS.each do |key|
        if target[key].to_s.strip.empty? then
            printf(
                $stderr,
                "\x1b[1;31m[!] \x1b[0mConfig: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mis empty field!\n",
                target["File"], key,
            )
            exit(1)
        end
    end

    path = File.join(ROOT, target["File"])
    keyword = target["replace"].to_s
    value = target["new"].to_s.gsub("{newstr}", NEW_VERSION)

    if ! File.file?(path) then
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mFile: \x1b[0;32m%s \x1b[0mnot found!\n",
            path.delete_prefix("#{ROOT}/"),
        )
        exit(1)
    end

    content = File.read(path, encoding: "UTF-8")
    pattern = /^([ \t]*)#{Regexp.escape(keyword)}[ \t]*.*$/
    count = 0

    updated = content.gsub(pattern) do
        count += 1
        "#{$1}#{keyword}#{value}"
    end

    if count.zero? then
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mKeyword: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mnot found!\n",
            path.delete_prefix("#{ROOT}/"), keyword,
        )
        exit(1)
    end

    File.write(path, updated, encoding: "UTF-8")

    printf(
        "\x1b[0;32m[+] \x1b[0mUpdating version: \x1b[0;32m%s \x1b[1;90m(\x1b[0;36m%s%s\x1b[1;90m)\x1b[0m\n",
        path.delete_prefix("#{ROOT}/"), keyword, value,
    )
end

# Copyright (c) 2026 Senzdetta