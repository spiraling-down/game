stylua --check mods
for f in mods/*; do luacheck "$f" --config "$f/.luacheckrc"; done
