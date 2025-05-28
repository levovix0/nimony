include .. / lib / nifprelude

import std / [tables]
import ./ [clioptions]


type
  TypeDesc* {.shallow.} = object
    size*: int  # in bytes
    align*: int  # in bytes
    fields*: Table[string, FieldDesc]


  FieldDesc* = object
    offset*: int  # in bytes
    typ*: TypeDesc


  VarDesc* = object
    offset*: int  # in bytes
    typ*: TypeDesc


  StackFrame* = object
    vars*: Table[string, VarDesc]
    size*: int  # in bytes


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


template currentStackframe*(ctx: MaContext): ptr StackFrame =
  ctx.stackframe.addr
