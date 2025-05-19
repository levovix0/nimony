
type
  int* {.magic: Int.}
  float* {.magic: Float.}
  char* {.magic: Char.}
  typedesc*[T] {.magic: TypeDesc.}

proc typeof*[T](x: T): typedesc[T] {.magic: TypeOf.}

# type
#   string* = typeof("")

proc `+`*(x, y: int): int {.magic: "AddI".}


proc main*: int {.exportc.} =
  69
