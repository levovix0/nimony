#!/usr/bin/env fish

# usage:
#   tools/testmachina.fish c t1.nim
# or
#   tools/testmachina.fish n t1.nim

if test $argv[1] = n
  tools/nimony.fish c --noSystem tests/machina/$argv[2]
  # tools/nifc.fish n tests/machina/$argv[2].nif
  # cat nimcache/$argv[2].S
  echo todo
else
  tools/nimony.fish c --noSystem tests/machina/$argv[2]
  tools/nifc.fish c tests/machina/$argv[2].nif
  cat nimcache/$argv[2].c
end

