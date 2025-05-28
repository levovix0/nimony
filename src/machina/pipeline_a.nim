{.used.}
include .. / lib / nifprelude

import std / [tables]
import ".." / nimony / [nimony_model]
import ./ [context, transutils, pipeline_fwd]



proc querySize*(s: StackFrame): int =
  result = 0

  for v in s.vars.values:
    result = max(result, v.offset + v.typ.size)



{.push, nimcall, exportc: "machina_$1".}



proc transformStmts(ctx: var MaContext, n: var Cursor) =
  case n.kind
  of ParLe:
    case n.stmtKind
    of StmtsS:
      inc n
      ctx.loop n:
        transformStmt(ctx, n)
    
    else: ctx.error("expected 'stmts', but got", n)
  
  else: error ctx, "expected '(', but got", n

  #[ todo: autoexpect, with automatic error handling (e.g. "expected 'stmts'|'pragmas' at ...")
    case ae n.kind
    of ParLe:
      case ae n.stmtKind
      of StmtsS:
        inc n
        ctx.loop n:
          transformStmt(ctx, n)
  ]#



proc transformSimpleRvalue(ctx: var MaContext, n: var Cursor) =
  let stackframe = ctx.currentStackframe

  case n.kind
  of IntLit:
    let v = pool.integers[n.intId]

    ctx.dest.addIntLit v

    inc n
  
  of Symbol:
    let desc = stackframe.vars.mgetOrPut(pool.syms[n.symId], VarDesc(offset: -1)).addr
    if desc.offset == -1:
      ctx.error("unknown variable", n)

    if desc.typ.size > 8:
      ctx.error("too large for simple rvalue", n)

    if desc.typ.size == 0:
      ctx.error "expected non-zero size for simple rvalue", n
    
    ctx.makeTree "-", n.info:
      ctx.dest.addIdent "rbp"
      ctx.dest.addIntLit stackframe.size - desc.offset

    inc n

  else: ctx.error("expected int|symbol, got", n)



proc transformSimpleLvalue(ctx: var MaContext, n: var Cursor) =
  transformSimpleRvalue(ctx, n)



proc transformVar(ctx: var MaContext, n: var Cursor) =
  inc n

  let stackframe = ctx.currentStackframe


  var name = ""

  # - name -
  case n.kind
  of SymbolDef:
    name = pool.syms[n.symId]
    inc n

  else: ctx.error("expected ident, but got", n)
  
  let desc = stackframe.vars[name].addr


  # - pragmas -
  case n.kind
  of DotToken:
    inc n

  else: ctx.error("expected '.', but got", n)

  # - type -
  ctx.skipTree n


  # - init -
  case n.kind
  of DotToken:
    inc n

  else:
    # todo
    ctx.error("expected '.', but got", n)


  ctx.skipParRi n



proc transformAsgn(ctx: var MaContext, n: var Cursor) =
  let linfo = n.info

  inc n

  # - dest -
  let destvar = lookupSym(ctx, n)

  if destvar.typ.size > 8:
    ctx.error("currently machina does not support assignmets for more than 8 bytes", n)

  if destvar.typ.size != 0:
    ctx.makeTree "asgn", linfo:
      ctx.dest.addIntLit destvar.typ.size * 8  # bits
      
      transformSimpleLvalue(ctx, n)
      transformSimpleRvalue(ctx, n)
  
  ctx.skipParRi n



proc genRet(ctx: var MaContext, n: var Cursor) =
  ctx.makeTree "popStackframe", n.info:
    ctx.dest.addIntLit ctx.currentStackframe.size

  ctx.dest.addIdent "ret", n.info



proc transformRet(ctx: var MaContext, n: var Cursor) =
  let linfo = n.info
  
  inc n

  let desc = lookupSym(ctx, n)

  if desc.typ.size > 8:
    ctx.error("currently machina does not support return values for more than 8 bytes", n)

  ctx.makeTree "asgn", linfo:
    ctx.dest.addIntLit desc.typ.size * 8  # bits
    
    ctx.dest.addIdent "r1"
    transformSimpleRvalue(ctx, n)
  
  genRet(ctx, n)

  ctx.skipParRi n



proc transformProc(ctx: var MaContext, n: var Cursor) =
  inc n

  ctx.stackframe = StackFrame()
  var hasReturnType = false


  # - proc name -
  case n.kind
  of SymbolDef:
    ctx.makeTree "global", n.info:
      ctx.dest.add n
    inc n
  
  else: ctx.error("unexpected kind", n)


  # - params -
  case n.kind
  of ParLe:
    case n.typeKind
    of ParamsT:
      # skip for now
      discard ctx.copyTree n
    
    else: ctx.error("unexpected typeKind", n)
  
  else: ctx.error("unexpected kind", n)


  # - rettype -
  case n.kind
  of DotToken:
    inc n
  
  else:
    # let rettype = ctx.copyTree n
    discard ctx.copyTree n
    hasReturnType = true


  # - pragmas -
  case n.kind
  of ParLe:
    case n.stmtKind
    of PragmasS:
      # skip for now
      discard ctx.copyTree n

    else: ctx.error("unexpected stmtKind", n)

  else: ctx.error("unexpected kind", n)

  
  # - stmts -
  block visitVars:
    var n2 = n
    visitVarsStmts(ctx, n2)

    let stackframe = ctx.currentStackframe
    stackframe.size = querySize(stackframe[])

  ctx.makeTree "pushStackframe", n.info:
    ctx.dest.addIntLit ctx.currentStackframe.size

  ctx.with procsAllowed, false:
    transformStmts(ctx, n)

  if not hasReturnType:
    genRet(ctx, n)
  

  ctx.skipParRi n



proc transformStmt(ctx: var MaContext, n: var Cursor) =
  case n.kind
  of DotToken:
    ctx.dest.add n
    inc n

  of ParLe:
    case n.stmtKind
    of StmtsS:
      transformStmts(ctx, n)
    
    of ProcS:
      if ctx.procsAllowed:
        transformProc(ctx, n)
      else:
        ctx.error("procs only allowed at toplevel, got", n)
    
    of VarS:
      transformVar(ctx, n)
    
    of AsgnS:
      transformAsgn(ctx, n)
    
    of RetS:
      transformRet(ctx, n)
    
    else: ctx.error("unexpected stmtKind", n)
  
  else: ctx.error("unexpected kind", n)



{.pop.}

