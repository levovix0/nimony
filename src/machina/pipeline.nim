include .. / lib / nifprelude

import std / [os]
import ./ [clioptions, context, transutils, pipeline_fwd]



proc machinaTransform*(ctx: var MaContext, n: var Cursor) =
  ctx.makeTree "section", n.info:
    ctx.dest.addStrLit "text"
  
  transformStmts(ctx, n)


proc writeStmts(c: var MaContext, b: var Builder) =
  var n = beginRead(c.dest)

  var stack: seq[PackedLineInfo] = @[]
  
  if n.info.isValid:
    stack.add n.info
    let rawInfo = unpack(pool.man, n.info)
    b.addLineInfo(rawInfo.col, rawInfo.line, pool.files[rawInfo.file])
  
  b.addTree "stmts"
  
  # for h in c.headers:
  #   b.withTree "incl":
  #     b.addStrLit pool.strings[h]

  var ownerStack = @[(SymId(0), -1)]

  var nested = 0
  var nextIsOwner = -1
  for nb in 0 ..< c.dest.len:
    let info = n.info
    if info.isValid:
      let rawInfo = unpack(pool.man, info)
      let file = rawInfo.file
      var line = rawInfo.line
      var col = rawInfo.col
      if file.isValid:
        var fileAsStr = ""
        if stack.len > 0:
          let pRawInfo = unpack(pool.man, stack[^1])
          if file != pRawInfo.file: fileAsStr = pool.files[file]
          if fileAsStr.len == 0:
            line = line - pRawInfo.line
            col = col - pRawInfo.col
        else:
          fileAsStr = pool.files[file]
        b.addLineInfo(col, line, fileAsStr)

    case n.kind
    of DotToken:
      b.addEmpty()
    
    of Ident:
      b.addIdent(pool.strings[n.litId])
    
    of Symbol:
      let s = pool.syms[n.symId]
      b.addSymbol(s)
      
      # let val = c.maybeMangle(n.symId)
      # if val.len > 0:
      #   b.addSymbol(val)
      # else:
      #   let s = pool.syms[n.symId]
      #   if isInstantiation(s):
      #     # ensure instantiations have the same name across modules:
      #     b.addSymbol(removeModule(s))
      #   else:
      #     b.addSymbol(s)
    
    of SymbolDef:
      let s = pool.syms[n.symId]
      b.addSymbolDef(s)
      
      # let val = c.maybeMangle(n.symId)
      # if val.len > 0:
      #   b.addSymbolDef(val)
      # else:
      #   let s = pool.syms[n.symId]
      #   if isInstantiation(s):
      #     # ensure instantiations have the same name across modules:
      #     b.addSymbolDef(removeModule(s))
      #   else:
      #     b.addSymbolDef(s)
      # if nextIsOwner >= 0:
      #   ownerStack.add (n.symId, nextIsOwner)
      #   nextIsOwner = -1
    
    of IntLit:
      b.addIntLit(pool.integers[n.intId])
    
    of UIntLit:
      b.addUIntLit(pool.uintegers[n.uintId])
    
    of FloatLit:
      b.addFloatLit(pool.floats[n.floatId])
    
    of CharLit:
      b.addCharLit char(n.uoperand)
    
    of StringLit:
      b.addStrLit(pool.strings[n.litId])
    
    of UnknownToken:
      b.addIdent "<unknown token>"
    
    of EofToken:
      b.addIntLit n.soperand
    
    of ParRi:
      if stack.len > 0:
        discard stack.pop()
      b.endTree()
      if nested > 0: dec nested
      if ownerStack[^1][1] == nested:
        discard ownerStack.pop()
    
    of ParLe:
      let tag = pool.tags[n.tagId]
      if tag == "proc" or tag == "type":
        nextIsOwner = nested
      b.addTree(tag)
      stack.add info
      inc nested
    
    inc n

  b.endTree()



proc machinaPipeline*(inpFile, outFile: string; conf: Config) =
  createDir(outFile.absolutePath.parentDir)
  
  var ctx = MaContext(
    dest: createTokenBuf(),
    config: conf,
  )
  
  when defined(machina_debug):
    echo "machina: parsing file ", inpFile
    echo "machina: writing to   ", outFile

  var inStream = nifstreams.open(inpFile)
  discard processDirectives(inStream.r)  # skip (.nif24)
  var inBuf = inStream.fromStream
  var tt = inBuf.beginRead

  when defined(machina_debug):
    echo tt

    echo "machina: start. ----------"

  try:
    machinaTransform(ctx, tt)
  except:
    when defined(machina_debug):
      var b = nifbuilder.open(outFile)
      b.addHeader("machina", "nifasm")

      try:
        writeStmts(ctx, b)
      except AssertionDefect:
        var n = beginRead(ctx.dest)
        while n.kind != EofToken:
          echo n
          while n.kind != ParRi:
            inc n
          inc n

        raise
      
      b.close()

    raise

  var b = nifbuilder.open(outFile)
  b.addHeader("machina", "nifasm")

  try:
    writeStmts(ctx, b)
  except AssertionDefect:
    when defined(machina_debug):
      var n = beginRead(ctx.dest)
      while n.kind != EofToken:
        echo n
        while n.kind != ParRi:
          inc n
        inc n

    raise
  
  b.endTree()
  b.close()

  
  when defined(machina_debug):
    echo "machina: done. ----------"


