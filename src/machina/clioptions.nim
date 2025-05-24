
type
  Backend* = enum
    mabX64LinuxNasm

  Action* = enum
    atNone, atC

  Config* = object
    backend*: Backend
    action*: Action
    cacheDir*: string
    files*: seq[tuple[inpf, outf: string]]
    
    isMain*: bool
    bits*: int

