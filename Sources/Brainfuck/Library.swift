// a space for stuff not specific to the interpreter or logger, though this might get merged with one of them in a future point

enum BFCommand: Character {
    case left  = "<"
    case right = ">"
    case plus  = "+"
    case minus = "-"
    case jump  = "["
    case bjump = "]"
    case read  = ","
    case write = "."

    // extension
    case debug = "#"
}
