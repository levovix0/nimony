include .. / lib / nifprelude

import ./ [context]


{.push, nimcall, importc: "machina_$1".}

proc lookupSym*(ctx: var MaContext, n: var Cursor): ptr VarDesc

{.pop.}


{.push, nimcall, importc: "machina_$1".}

proc transformStmts*(ctx: var MaContext, n: var Cursor)

proc transformSimpleRvalue*(ctx: var MaContext, n: var Cursor)
proc transformSimpleLvalue*(ctx: var MaContext, n: var Cursor)

proc transformVar*(ctx: var MaContext, n: var Cursor)
proc transformAsgn*(ctx: var MaContext, n: var Cursor)

proc transformRet*(ctx: var MaContext, n: var Cursor)
proc transformProc*(ctx: var MaContext, n: var Cursor)

proc transformStmt*(ctx: var MaContext, n: var Cursor)

{.pop.}


{.push, nimcall, importc: "machina_$1".}

proc visitVarsStmts*(ctx: var MaContext, n: var Cursor)

proc visitVarsType*(ctx: var MaContext, n: var Cursor): TypeDesc

proc visitVarsVar*(ctx: var MaContext, n: var Cursor)

proc visitVarsStmt*(ctx: var MaContext, n: var Cursor)

{.pop.}


