include .. / lib / nifprelude

import ./ context


type
  MachinaError* = object of CatchableError


proc error*(ctx: var MaContext; msg: string; c: Cursor) {.noreturn.} =
  raise newException(MachinaError, msg & " " & toString(c))


proc error*(ctx: var MaContext; msg: string) {.noreturn.} =
  raise newException(MachinaError, msg)



proc tagToken*(tag: string; info: PackedLineInfo): PackedToken {.inline.} =
  parLeToken(pool.tags.getOrIncl(tag), info)



proc takeParRi*(ctx: var MaContext; c: var Cursor) =
  if c.kind == ParRi:
    ctx.dest.add c
    inc c
  else:
    error ctx, "expected ')', but got", c


proc skipParRi*(ctx: var MaContext; c: var Cursor) =
  if c.kind == ParRi:
    inc c
  else:
    error ctx, "expected ')', but got", c


template loop*(ctx: var MaContext; c: var Cursor; body: untyped) =
  while true:
    case c.kind
    of ParRi:
      inc c
      break
    of EofToken:
      error ctx, "expected ')', but EOF reached"
    else: discard
    body


proc takeTree*(ctx: var MaContext; n: var Cursor) =
  takeTree ctx.dest, n


proc copyTree*(ctx: var MaContext, n: var Cursor): TokenBuf =
  result = createTokenBuf()
    
  if n.kind == ParLe:
    result.add n
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
      
      result.add n
      inc n
  
  else:
    result.add n
    inc n


template makeTree*(ctx: var MaContext, tag: string, info: PackedLineInfo, body: untyped) =
  ctx.dest.add tagToken(tag, info)
  body
  ctx.dest.addParRi

