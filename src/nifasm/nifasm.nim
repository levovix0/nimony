import std / [parseopt, strutils, os, assertions]
include .. / lib / nifprelude

import ./ [clioptions, pipeline, pipeline_a]


const
  Version = "0.1"
  Usage = "Nifasm Compiler. Version " & Version & """

Usage:
  nifasm [options] [command] [arguments]
Command:
  n file.nif [file2.nif]    compile NifAsm files to Nasm

Options:
  --executable              mark the file as executable
  --bits:N                  `(i -1)` has N bits; possible values: 64, 32, 16
  --nimcache:PATH           set the path used for generated files
  --version                 show the version
  --help                    show this help
"""



proc writeHelp() = quit(Usage, QuitSuccess)
proc writeVersion() = quit(Version & "\n", QuitSuccess)


proc handleCmdLine() =
  var config = Config(bits: sizeof(int)*8)
  
  config.cacheDir = "nimcache"

  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      case key.normalize:
      of "n":
        config.action = atNasm

      else:
        case config.action:
        of atNasm:
          config.files.add (key, "")
          
        of atNone:
          quit "invalid command: " & key
    
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "bits":
        case val
        of "64": config.bits = 64
        of "32": config.bits = 32
        of "16": config.bits = 16
        else: quit "invalid value for --bits, expected 64|32|16"
      
      of "help", "h": writeHelp()
      of "version", "v": writeVersion()
      of "executable": config.executable = true
      
      of "nimcache":
        config.cacheDir = val
      
      of "out", "o":
        if config.files.len == 0:
          quit "input file must be specified before output file"
        else:
          config.files[^1].outf = val
      
      else: writeHelp()
    
    of cmdEnd: assert false, "cannot happen"

  createDir(config.cacheDir)

  for (inpFile, outFile) in config.files.mitems:
    if outFile == "":
      outFile = config.cacheDir / inpFile.splitFile.name.splitFile.name & ".asm"

  if config.files.len != 0:
    for (inpFile, outFile) in config.files:
      case config.action
      of atNasm:
        nifasmPipeline(inpFile, outFile, config)
      
      of atNone:
        quit "target are not specified"
  
  else:
    writeHelp()



when isMainModule:
  handleCmdLine()
