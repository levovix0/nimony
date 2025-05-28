
type
  Action* = enum
    atNone, atNasm

  Config* = object
    action*: Action
    cacheDir*: string
    files*: seq[tuple[inpf, outf: string]]
    
    executable*: bool
    bits*: int

