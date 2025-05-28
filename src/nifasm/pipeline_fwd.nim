include .. / lib / nifprelude

import ./ [context]


{.push, nimcall, importc: "nifasm_$1".}

proc transformStmts*(ctx: var NfaContext, n: var Cursor)

proc transformStmt*(ctx: var NfaContext, n: var Cursor)

{.pop.}


