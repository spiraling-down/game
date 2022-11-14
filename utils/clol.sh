#!/usr/bin/bash
# Count lines of Lua, excluding libs
find . -name "*.lua" -not -path "**/*lib/**" | xargs wc -l
