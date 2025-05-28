{.used.}
include .. / lib / nifprelude

import std / [tables]
import ".." / nimony / [nimony_model]
import ./ [context, transutils, pipeline_fwd]


{.push, nimcall, exportc: "nifasm_$1".}


proc transformStmts*(ctx: var NfaContext, n: var Cursor) =
  ## todo


proc transformStmt*(ctx: var NfaContext, n: var Cursor) =
  ## todo


{.pop.}
