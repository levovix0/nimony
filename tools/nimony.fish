#!/usr/bin/env fish

nim c -r -o:bin/nimony src/nimony/nimony $argv > /dev/null

if test $argv[1] = c
  cp nimcache/(cat nimcache/modname).c.nif $argv[-1].nif
end

