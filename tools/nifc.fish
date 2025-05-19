#!/usr/bin/env fish

if test $argv[1] = n
  nim c -r -d:enableAsm -o:bin/nifc src/nifc/nifc $argv
else
  nim c -r -o:bin/nifc src/nifc/nifc $argv
end

