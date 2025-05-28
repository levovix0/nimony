{.used.}
include .. / lib / nifprelude

import std / [tables]
import ".." / nimony / [nimony_model]
import ./ [context, transutils, pipeline_fwd]


{.push, nimcall, exportc: "machina_$1".}


proc visitVarsStmts*(ctx: var MaContext, n: var Cursor) =
  case n.kind
  of ParLe:
    case n.stmtKind
    of StmtsS:
      inc n
      ctx.loop n:
        visitVarsStmt(ctx, n)
    
    else: ctx.error "expected 'stmts', but got", n
  
  else: error ctx, "expected '(', but got", n



proc visitVarsType(ctx: var MaContext, n: var Cursor): TypeDesc =
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



proc visitVarsVar*(ctx: var MaContext, n: var Cursor) =
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
  desc.typ = visitVarsType(ctx, n)


  # - init -
  ctx.skipTree n


  ctx.skipParRi n


  let stackframe = ctx.currentStackframe
  
  desc.offset = block:
    var r = 0
    for v in stackframe.vars.values:
      r = max(r, v.offset + v.typ.size)
    r

  if desc.offset mod desc.typ.align != 0:
    desc.offset += desc.typ.align - (desc.offset mod desc.typ.align)

  stackframe.vars[name] = desc



proc visitVarsStmt*(ctx: var MaContext, n: var Cursor) =
  case n.kind
  of DotToken:
    inc n

  of ParLe:
    case n.stmtKind
    of StmtsS:
      visitVarsStmts(ctx, n)
    
    of VarS:
      visitVarsVar(ctx, n)
    
    else:
      ctx.skipTree n
  
  else: ctx.error("unexpected kind", n)


{.pop.}
