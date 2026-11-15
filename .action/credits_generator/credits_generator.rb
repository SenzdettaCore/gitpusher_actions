#!/usr/bin/env ruby
# https://github.com/SenzdettaCore/gitpusher_actions

require "yaml"
require "fileutils"
require_relative "module/color"

ROOT = ENV.fetch("__root_project__").freeze
CONFIG = File.join(ROOT, ".action", "config", "credits_generator.yaml").freeze
OUTPUT = File.join(ROOT, ".docs", "credits.md").freeze
LINK_PREFIX = "../".freeze

SOURCE_KEYS = %w[name url avatar items].freeze
ITEM_KEYS = %w[module type path license license_file readme_file modified_info].freeze

if ! File.exist?(CONFIG) then
    printf(
        "%s[!] %sConfig: %s%s %snot found!\n",
        Color.R, Color.N, Color.GG, CONFIG, Color.N,
    )
    exit(1)
end

cfg = YAML.safe_load_file(CONFIG)

if ! cfg.is_a?(Hash) then
    printf(
        "%s[!] %sConfig: %s%s %sempty or invalid format!\n",
        Color.R, Color.N, Color.GG, CONFIG, Color.N,
    )
    exit(1)
end

heading = cfg["title"] || "CREDITS"
sources = cfg["sources"]

if ! sources.is_a?(Array) || sources.empty? then
    printf(
        "%s[!] %sConfig key: %ssources %smust be a list!\n",
        Color.R, Color.N, Color.GG, Color.N,
    )
    exit(1)
end

blocks = []

sources.each do |source|
    if ! source.is_a?(Hash) then
        printf(
            "%s[!] %sConfig key: %ssource %smust be a map %s(%skey: %svalue%s)%s\n",
            Color.R, Color.N, Color.GG, Color.N, Color.DG,
            Color.N, Color.GG, Color.DG, Color.N,
        )
        exit(1)
    end

    SOURCE_KEYS.each do |key|
        if source[key].to_s.strip.empty? then
            printf(
                "%s[!] %sConfig: %s%s %s-> %s%s %sis empty field!\n",
                Color.R, Color.N, Color.GG, source["name"], Color.DG,
                Color.GG, key, Color.N,
            )
            exit(1)
        end
    end

    if ! source["items"].is_a?(Array) then
        printf(
            "%s[!] %sConfig: %s%s %s-> %sitems %smust be a list!\n",
            Color.R, Color.N, Color.GG, source["name"], Color.DG,
            Color.GG, Color.N,
        )
        exit(1)
    end

    rendered = []

    source["items"].each do |item|
        if ! item.is_a?(Hash) then
            printf(
                "%s[!] %sConfig: %s%s %s-> %sitem %smust be a map %s(%skey: %svalue%s)%s\n",
                Color.R, Color.N, Color.GG, source["name"], Color.DG,
                Color.GG, Color.N, Color.DG, Color.N, Color.GG, Color.DG, Color.N,
            )
            exit(1)
        end

        ITEM_KEYS.each do |key|
            if item[key].to_s.strip.empty? then
                printf(
                    "%s[!] %sConfig: %s%s %s/ %s%s %s-> %s%s %sis empty field!\n",
                    Color.R, Color.N, Color.GG, source["name"], Color.DG,
                    Color.GG, item["module"], Color.DG, Color.GG, key, Color.N,
                )
                exit(1)
            end
        end

        if ! File.exist?(File.join(ROOT, item["license_file"])) then
            printf(
                "%s[!] %sFile: %s%s %s/ %s%s %s-> %s%s %snot found!\n",
                Color.R, Color.N, Color.GG, source["name"], Color.DG,
                Color.GG, item["module"], Color.DG, Color.GG, item["license_file"], Color.N,
            )
            exit(1)
        end

        if ! File.exist?(File.join(ROOT, item["readme_file"])) then
            printf(
                "%s[!] %sFile: %s%s %s/ %s%s %s-> %s%s %snot found!\n",
                Color.R, Color.N, Color.GG, source["name"], Color.DG,
                Color.GG, item["module"], Color.DG, Color.GG, item["readme_file"], Color.N,
            )
            exit(1)
        end

        if ! File.exist?(File.join(ROOT, item["modified_info"])) then
            printf(
                "%s[!] %sFile: %s%s %s/ %s%s %s-> %s%s %snot found!\n",
                Color.R, Color.N, Color.GG, source["name"], Color.DG,
                Color.GG, item["module"], Color.DG, Color.GG, item["modified_info"], Color.N,
            )
            exit(1)
        end

        rendered.push(<<~HTML.chomp.gsub(/^/, "      "))
            <b>#{item["module"]}</b> · #{item["type"]}</br>
            <code>#{item["path"]}</code></br>
            <a href="#{LINK_PREFIX}#{item["license_file"]}">#{item["license"]}</a> · <a href="#{LINK_PREFIX}#{item["readme_file"]}">README</a> · <a href="#{LINK_PREFIX}#{item["modified_info"]}">Modified</a>
        HTML
    end

    body = rendered.join("</br></br>\n")

    blocks.push(<<~HTML)
        <table>
          <tr>
            <td width="90" align="center" valign="middle"><img src="#{source["avatar"]}" width="70" /></td>
            <td valign="top">
              <b><a href="#{source["url"]}">#{source["name"]}</a></b></br></br>
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
    "%s[+] %sGenerated: %s%s %s(%s%d %ssources%s)%s\n",
    Color.GG, Color.N, Color.GG, OUTPUT, Color.DG,
    Color.GG, sources.length, Color.N, Color.DG, Color.N,
)

# Copyright (c) 2026 Senzdetta