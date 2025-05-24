#!/usr/bin/env fish

nim c -d:machina_debug -r -o:bin/machina src/machina/machina $argv

