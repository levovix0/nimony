{.used.}
include .. / lib / nifprelude

import std / [tables]
import ".." / nimony / [nimony_model]
import ./ [context, transutils, pipeline_fwd]


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



proc transformType(ctx: var MaContext, n: var Cursor): TypeDesc =
  result = TypeDesc()

  case n.kind
  of ParLe:
    case n.typeKind
    of IT:
      inc n

      case n.kind
      of IntLit:
        var bits = pool.integers[n.intId]
        if bits == -1:
          bits = ctx.config.bits
        
        result.size = bits div 8
        result.align = bits div 8

        inc n
        ctx.skipParRi n
      
      else:
        ctx.error("expected integer literal, but got", n)

    else:
      ctx.error("expected i, but got", n)
  
  else:
    ctx.error("expected '(', but got", n)



proc lookupSym(ctx: var MaContext, n: var Cursor): ptr VarDesc =
  let stackframe = ctx.stackframe.addr

  # - dest -
  case n.kind
  of Symbol:
    result = stackframe.vars.mgetOrPut(pool.syms[n.symId], VarDesc(offset: -1)).addr
    if result.offset == -1:
      ctx.error("unknown variable", n)
    
  else: ctx.error("expected symbol, got", n)



proc transformSimpleRvalue(ctx: var MaContext, n: var Cursor) =
  let stackframe = ctx.stackframe.addr

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

    ctx.makeTree "-", n.info:
      ctx.dest.addIdent "pstack"
      ctx.dest.addIntLit desc.offset

    inc n

  else: ctx.error("expected int|symbol, got", n)



proc transformSimpleLvalue(ctx: var MaContext, n: var Cursor) =
  transformSimpleRvalue(ctx, n)



proc transformVar(ctx: var MaContext, n: var Cursor) =
  inc n

  var desc = VarDesc()
  var name = ""

  # - name -
  case n.kind
  of SymbolDef:
    name = pool.syms[n.symId]
    inc n

  else: ctx.error("expected ident, but got", n)


  # - pragmas -
  case n.kind
  of DotToken:
    inc n

  else: ctx.error("expected '.', but got", n)

  # - type -
  desc.typ = transformType(ctx, n)


  # - init -
  case n.kind
  of DotToken:
    inc n

  else: ctx.error("expected '.', but got", n)


  ctx.skipParRi n


  let stackframe = ctx.stackframe.addr
  
  let lastOffset = block:
    var r = 0
    for v in stackframe.vars.values:
      r = max(r, v.offset)
    r

  desc.offset = lastOffset + desc.typ.size
  if desc.offset mod desc.typ.align != 0:
    desc.offset += desc.typ.align - (desc.offset mod desc.typ.align)

  stackframe.vars[name] = desc



proc transformAsgn(ctx: var MaContext, n: var Cursor) =
  let linfo = n.info

  inc n

  # - dest -
  let destvar = lookupSym(ctx, n)

  if destvar.typ.size > 8:
    ctx.error("currently machina does not support more than 8 bytes assignmets", n)

  ctx.makeTree "asgn", linfo:
    ctx.dest.addIntLit destvar.typ.size * 8  # bits
    
    transformSimpleLvalue(ctx, n)
    transformSimpleRvalue(ctx, n)
  
  ctx.skipParRi n



proc transformRet(ctx: var MaContext, n: var Cursor) =
  let linfo = n.info
  
  inc n

  let desc = lookupSym(ctx, n)

  if desc.typ.size > 8:
    ctx.error("currently machina does not support more than 8 bytes return values", n)

  ctx.makeTree "asgn", linfo:
    ctx.dest.addIntLit desc.typ.size * 8  # bits
    
    ctx.dest.add tagToken("retreg", linfo)
    transformSimpleRvalue(ctx, n)
  
  ctx.makeTree "pop", n.info:
    ctx.dest.addIdent "pstack"

  ctx.dest.addIdent "ret"

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
  ctx.makeTree "push", n.info:
    ctx.dest.addIdent "pstack"

  ctx.with procsAllowed, false:
    transformStmts(ctx, n)

  if not hasReturnType:
    ctx.makeTree "pop", n.info:
      ctx.dest.addIdent "pstack"

    ctx.dest.addIdent "ret"
  

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

