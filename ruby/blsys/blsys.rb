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

require "uri"
require "net/http"

ROOT = ENV.fetch("__root_project__").freeze
BASE_URL = "https://cdn.jsdelivr.net/gh/SenzdettaCore/blsys@main/scripts".freeze
FILES = %w[install.sh uninstall.sh].freeze

if ! Dir.exist?(ROOT) then
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mRoot: \x1b[0;32m%s \x1b[0mnot found!\n",
        ROOT,
    )
    exit(1)
end

downloaded = {}

FILES.each do |name|
    url = "#{BASE_URL}/#{name}"
    begin
        response = Net::HTTP.get_response(URI(url))
    rescue StandardError => e
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mDownload: \x1b[0;32m%s \x1b[0mfailed \x1b[1;90m(\x1b[0;36m%s\x1b[1;90m)\x1b[0m\n",
            url, e.message,
        )
        exit(1)
    end

    if ! response.is_a?(Net::HTTPSuccess) then
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mDownload: \x1b[0;32m%s \x1b[0mHTTP \x1b[0;36m%s\x1b[0m\n",
            url, response.code,
        )
        exit(1)
    end

    body = response.body.to_s

    if body.strip.empty? then
        printf(
            $stderr,
            "\x1b[1;31m[!] \x1b[0mDownload: \x1b[0;32m%s \x1b[0mempty response!\n",
            url,
        )
        exit(1)
    end

    downloaded[name] = body
end

downloaded.each do |name, body|
    output = File.join(ROOT, name)
    File.binwrite(output, body)
    printf(
        "\x1b[0;32m[+] \x1b[0mDownloaded: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s\x1b[0m\n",
        "#{BASE_URL}/#{name}", output,
    )
end

# Copyright (c) 2026 Senzdetta