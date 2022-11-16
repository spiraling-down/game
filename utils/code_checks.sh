#!/usr/bin/bash
stylua --check mods
for f in mods/*; do if [ -f "$f/.luacheckrc" ]; then luacheck "$f" --config "$f/.luacheckrc"; fi done
