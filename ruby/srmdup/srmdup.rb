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
CONFIG = File.join(ROOT, ".action", "config", "srmdup.yaml").freeze
TYPES = %w[file folder].freeze
FLAGS = %w[sort remove_comment remove_duplicat remove_empty_line].freeze

def fail_with(fmt, *args)
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0m#{fmt}\n",
        *args,
    )
    exit(1)
end

def clean(path, opts)
    raw = File.binread(path)

    trailing = raw.end_with?("\n")
    lines = raw.each_line(chomp: true).to_a
    before = lines.length

    lines.reject! {
        |l| l.lstrip.start_with?("#")
    } if opts["remove_comment"]

    lines.reject! {
        |l| l.strip.empty?
    } if opts["remove_empty_line"]

    lines.uniq! if opts["remove_duplicat"]
    lines.sort! if opts["sort"]

    result = lines.join("\n")
    result << "\n" if trailing && !lines.empty?

    return nil if result == raw

    File.binwrite(path, result)
    before - lines.length
end

if ! File.exist?(CONFIG) then
    fail_with(
        "Config: \x1b[0;32m%s \x1b[0mnot found!",
        CONFIG,
    )
end

targets = YAML.safe_load_file(CONFIG)

if ! targets.is_a?(Array) || targets.empty? then
    fail_with(
        "Config: \x1b[0;32m%s \x1b[0mmust be a non-empty list!",
        CONFIG,
    )
end

targets = targets.flat_map do |t|
    t.is_a?(Hash) && t["Target"].is_a?(Array) ?
        t["Target"].map {
            |x| t.merge("Target" => x)
        } :
        [t]
end

root_real = File.realpath(ROOT)

targets.each do |t|
    if ! t.is_a?(Hash) then
        fail_with(
            "Config: \x1b[0;32mtarget \x1b[0mmust be a map",
        )
    end

    %w[Target type].each do |key|
        if t[key].to_s.strip.empty? then
            fail_with(
                "Config: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s \x1b[0mis empty field!",
                t["Target"], key,
            )
        end
    end

    if ! TYPES.include?(t["type"]) then
        fail_with(
            "Config: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32mtype \x1b[0mmust be file or folder!",
            t["Target"],
        )
    end

    path = File.expand_path(t["Target"], root_real)

    if ! path.start_with?(root_real + File::SEPARATOR) then
        fail_with(
            "Target: \x1b[0;32m%s \x1b[0mis outside project root!",
            t["Target"],
        )
    end

    files =
        if t["type"] == "file" then
            if ! File.file?(path) then
                fail_with(
                    "File: \x1b[0;32m%s \x1b[0mnot found!",
                    path,
                )
            end
            [path]
        else
            if ! File.directory?(path) then
                fail_with(
                    "Folder: \x1b[0;32m%s \x1b[0mnot found!",
                    path,
                )
            end

            patterns = Array(t["only"]).map(&:to_s).reject {
                |p| p.strip.empty?
            }

            if patterns.empty? then
                fail_with(
                    "Config: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32monly \x1b[0mis required for folder!",
                    t["Target"],
                )
            end

            glob = t["recursive"] ?
                "**/*" :
                "*"

            Dir.glob(File.join(path, glob)).select do |f|
                File.file?(f) && patterns.any? {
                    |p| File.fnmatch?(p, File.basename(f))
                }
            end.sort
        end

    opts = FLAGS.to_h {
        |k| [k, t[k] == true]
    }

    files.each do |f|
        removed = clean(f, opts)

        if removed.nil? then
            printf(
                "\x1b[0;34m[*] \x1b[0mUnchanged: \x1b[0;32m%s\x1b[0m\n",
                f,
            )
        else
            printf(
                "\x1b[0;32m[+] \x1b[0mCleaned: \x1b[0;32m%s \x1b[1;90m(\x1b[0;36m-%d \x1b[0;37mlines\x1b[1;90m)\x1b[0m\n",
                f, removed,
            )
        end
    end
end

# Copyright (c) 2026 Senzdetta