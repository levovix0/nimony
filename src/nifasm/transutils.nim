include .. / lib / nifprelude

import ./ context


type
  NifasmError* = object of CatchableError



proc error*(ctx: var NfaContext; msg: string; c: Cursor) {.noreturn.} =
  raise newException(NifasmError, msg & " " & toString(c))


proc error*(ctx: var NfaContext; msg: string) {.noreturn.} =
  raise newException(NifasmError, msg)



proc skipParRi*(ctx: var NfaContext; c: var Cursor) =
  if c.kind == ParRi:
    inc c
  else:
    error ctx, "expected ')', but got", c



template loop*(ctx: var NfaContext; c: var Cursor; body: untyped) =
  while true:
    case c.kind
    of ParRi:
      inc c
      break
    of EofToken:
      error ctx, "expected ')', but EOF reached"
    else: discard
    body



proc skipTree*(ctx: var NfaContext, n: var Cursor) =
  if n.kind == ParLe:
    inc n

    var nested = 1
    while nested > 0:
      case n.kind
      of ParLe:
        inc nested
      of ParRi:
        dec nested
      of EofToken:
        error ctx, "expected ')', but EOF reached"
      else: discard
      
      inc n
  
  else:
    inc n

