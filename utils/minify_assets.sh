#!/usr/bin/bash
shopt -s globstar # make ** match recursively
optipng -o7 ./**/*.png
