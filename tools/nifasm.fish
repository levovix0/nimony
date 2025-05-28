#!/usr/bin/env fish

nim c -d:nifasm_debug -r -o:bin/nifasm src/nifasm/nifasm $argv

