#!/usr/bin/env fish

if test $argv[1] = r
  nasm -f elf64 -o nimcache/$argv[2].o nimcache/$argv[2].asm
  gcc -o nimcache/$argv[2] nimcache/$argv[2].o
  nimcache/$argv[2]
else
  nasm -f elf64 -o nimcache/$argv[2].o nimcache/$argv[2].asm
  gcc -o nimcache/$argv[1] nimcache/$argv[1].o
end

