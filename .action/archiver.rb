#!/usr/bin/env ruby
# https://github.com/SenzdettaCore/gitpusher_actions

# frozen_string_literal: true

require "digest"

ROOT = File.expand_path("..", __dir__)
LST = File.join(ROOT, ".action", "config", "archiver.txt")
META = File.join(ROOT, "index.meta")

GH_USER = "SenzdettaCore"
GH_REPO = "gitpusher_actions"
GH_BRANCH = "main"

USE_CDN = ENV.fetch("CDN", "1") == "1"
VERSION = "v0.1." + Time.now.strftime("%Y%m%d")

BLOCK = /action:\s*"([^"]+)"\s*\{(.*?)\}/m
FIELD = /(\w+):\s*"([^"]*)"/

def build_url(path)
    if USE_CDN
        "cdn.jsdelivr.net/gh/#{GH_USER}/#{GH_REPO}@#{GH_BRANCH}/#{path}"
    else
        "raw.githubusercontent.com/#{GH_USER}/#{GH_REPO}/#{GH_BRANCH}/#{path}"
    end
end

def hash_dir(dir)
    h = Digest::SHA256.new
    rels = Dir.glob(
        "**/*",
        File::FNM_DOTMATCH, base: dir,
    ).reject {
        |r| r == "." || r.end_with?("/.")
    }.sort_by {
        |r| r.split("/")
    }

    rels.each do |rel|
        full = File.join(dir, rel)
        if File.symlink?(full)
            h.update("L:#{rel}:#{File.readlink(full)}\0")
        elsif File.file?(full)
            h.update("F:#{rel}:#{File.stat(full).mode & 0o111}\0")
            File.open(full, "rb") do |f|
                while (chunk = f.read(1 << 20))
                    h.update(chunk)
                end
            end
        elsif File.directory?(full)
            h.update("D:#{rel}\0")
        end
    end
    h.hexdigest
end

def load_meta
    return {} unless File.file?(META)
    File.read(
        META,
        encoding: "utf-8",
    ).scan(BLOCK).to_h do |name, body|
        [name, body.scan(FIELD).to_h]
    end
end

def save_meta(entries)
    out = entries.map do |name, f|
        block = +"action: \"#{name}\" {\n" \
            "    url: \"#{f["url"]}\"\n" \
            "    version: \"#{f["version"]}\"\n"

        block << "    hash: \"#{f["hash"]}\"\n" if f["hash"] && !f["hash"].empty?
        block << "}\n"
    end

    File.write(
        META,
        out.join("\n") + "\n",
        encoding: "utf-8",
    )
end

unless File.file?(LST)
    printf(
        $stderr,
        "\x1b[1;31m[!] \x1b[0mFile: \x1b[0m%s \x1b[0mnot found!\n",
        LST,
    )
    exit 1
end

entries = load_meta
ok = skipped = same = added = updated = 0

File.read(LST, encoding: "utf-8").each_line do |raw|
    line = raw.strip.sub(%r{/+\z}, "")
    next if line.empty? || line.start_with?("#")

    dir = File.join(ROOT, line)
    unless File.directory?(dir)
        printf(
            "\x1b[0;33m[!] \x1b[0mSkipping: \x1b[0;32m%s \x1b[0mfile not found!\n",
            line,
        )
        skipped += 1
        next
    end

    parent = File.dirname(line)
    base = File.basename(line)
    archive = File.join(ROOT, "#{line}.tar.xz")
    digest = hash_dir(dir)
    url = build_url("#{line}.tar.xz")
    old = entries[line]

    if old &&
        old["hash"] == digest &&
        old["url"] == url &&
        File.file?(archive)
            printf(
                "\x1b[1;34m[*] \x1b[0mUnchanged: \x1b[0;32m%s\x1b[0m\n",
                line,
            )
            same += 1
            next
    end

    if old && old["hash"] == digest && File.file?(archive)
        printf(
            "\x1b[1;34m[*] \x1b[0mMeta: \x1b[0;32m%s \x1b[0mupdate URL \x1b[1;90m(\x1b[0marchive unchanges\x1b[1;90m)\x1b[0m\n",
            line,
        )
        entries[line] = old.merge("url" => url)
        updated += 1
        next
    end

    if File.file?(archive)
        printf(
            "\x1b[1;34m[*] \x1b[0mRemoving: \x1b[0;32m%s.tar.xz \x1b[0mcontent changes\n",
            line,
        )
        File.delete(archive)
    end

    printf(
        "\x1b[1;34m[+] \x1b[0mArchiving: \x1b[0;32m%s \x1b[1;90m-> \x1b[0;32m%s.tar.xz\x1b[0m\n",
        line, line,
    )

    system(
        {
            "XZ_OPT" => "-9e -T0",
        },
        "tar", "-C", File.join(
            ROOT, parent,
        ), "-cJf", archive, base,
        exception: true
    )
    ok += 1

    if old
        printf(
            "\x1b[0;32m[+] \x1b[0mMeta: \x1b[0;32m%s \x1b[0mupdated\n",
            line,
        )
        updated += 1
    else
        printf(
            "\x1b[0;32m[+] \x1b[0mMeta: \x1b[0;32m%s \x1b[0madded\n",
            line,
        )
        added += 1
    end

    entries[line] = {
        "url" => url,
        "version" => VERSION,
        "hash" => digest,
    }
end

save_meta(entries)

printf("\n")
printf(
    "\x1b[1;34m[*] \x1b[0mDone:\n",
)

printf(
    "\x1b[1;90m* \x1b[0mArchived: \x1b[0;32m%d\x1b[0m\n",
    ok,
)

printf(
    "\x1b[1;90m* \x1b[0mUnchanged: \x1b[0;32m%d\x1b[0m\n",
    same,
)

printf(
    "\x1b[1;90m* \x1b[0mSkipped: \x1b[0;32m%d\x1b[0m\n",
    skipped,
)

printf("\n")
printf(
    "\x1b[1;34m[*] \x1b[0mMeta:\n"
)

printf(
    "\x1b[1;90m* \x1b[0mAdded: \x1b[0;32m%d\x1b[0m\n",
    added,
)

printf(
    "\x1b[1;90m* \x1b[0mUpdated: \x1b[0;32m%d\x1b[0m\n",
    updated,
)

# Copyright (c) 2026 Senzdetta