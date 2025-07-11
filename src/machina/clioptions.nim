
type
  Backend* = enum
    nifasmDefault

  Action* = enum
    atNone, atC

  Config* = object
    backend*: Backend
    action*: Action
    cacheDir*: string
    files*: seq[tuple[inpf, outf: string]]
    
    isMain*: bool
    bits*: int

