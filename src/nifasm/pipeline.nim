include .. / lib / nifprelude

import std / [os, streams]
import ./ [clioptions, context, pipeline_fwd]



proc nifasmTransform*(ctx: var NfaContext, n: var Cursor) =
  transformStmts(ctx, n)



proc nifasmPipeline*(inpFile, outFile: string; conf: Config) =
  createDir(outFile.absolutePath.parentDir)
  
  var ctx = NfaContext(
    dest: newFileStream(outFile, fmWrite),
    config: conf,
  )
  
  when defined(nifasm_debug):
    echo "nifasm: parsing file ", inpFile
    echo "nifasm: writing to   ", outFile

  var inStream = nifstreams.open(inpFile)
  discard processDirectives(inStream.r)  # skip (.nif24)
  var inBuf = inStream.fromStream
  var tt = inBuf.beginRead


  when defined(nifasm_debug):
    echo tt

    echo "nifasm: start ----------"


  nifasmTransform(ctx, tt)
  

  when defined(nifasm_debug):
    echo "nifasm: done. ----------"

