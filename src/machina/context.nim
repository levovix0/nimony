include .. / lib / nifprelude

import std / [tables]
import ./ [clioptions]


type
  TypeDesc* {.shallow.} = object
    size*: int
    align*: int
    fields*: Table[string, FieldDesc]


  FieldDesc* = object
    offset*: int
    typ*: TypeDesc


  VarDesc* = object
    offset*: int
    typ*: TypeDesc


  StackFrame* = object
    vars*: Table[string, VarDesc]


  MaContext* = object
    dest*: TokenBuf
    config*: Config

    destData*: TokenBuf
      ## the .data section

    procsAllowed*: bool = true

    stackframe*: StackFrame
    types*: Table[string, TypeDesc]


template with*(ctx: var MaContext, param: untyped, val: untyped, body: untyped) =
  let old_val = ctx.param
  ctx.param = val
  body
  ctx.param = old_val

