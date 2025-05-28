include .. / lib / nifprelude

import std / [streams]
import ./ [clioptions]


type
  NfaContext* = object
    dest*: streams.Stream
    config*: Config


template with*(ctx: var NfaContext, param: untyped, val: untyped, body: untyped) =
  let old_val = ctx.param
  ctx.param = val
  body
  ctx.param = old_val

