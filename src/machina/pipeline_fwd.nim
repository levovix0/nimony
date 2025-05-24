include .. / lib / nifprelude

import ./ [context]


{.push, nimcall, importc: "machina_$1".}

proc transformStmts*(ctx: var MaContext, n: var Cursor)

proc transformType*(ctx: var MaContext, n: var Cursor): TypeDesc
proc lookupSym*(ctx: var MaContext, n: var Cursor): ptr VarDesc

proc transformSimpleRvalue*(ctx: var MaContext, n: var Cursor)
proc transformSimpleLvalue*(ctx: var MaContext, n: var Cursor)

proc transformVar*(ctx: var MaContext, n: var Cursor)
proc transformAsgn*(ctx: var MaContext, n: var Cursor)

proc transformRet*(ctx: var MaContext, n: var Cursor)
proc transformProc*(ctx: var MaContext, n: var Cursor)

proc transformStmt*(ctx: var MaContext, n: var Cursor)

{.pop.}


