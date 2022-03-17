import Brainfuck

// bubble sort, from brainfuck.org
let program = """
>>,[>>,]<<[[<<]>>>>[<<[>+<<+>-]>>[>+<<<<[->]>[<]>>-]<<<[[-]>>[>+<-]>>[<<<+>>>-]]>>[[<+>-]>>]<]<<[>>+<<-]<<]>>>>[.>>]
"""

let input = "Alphabetize me, nerd! >.<".map { $0.asciiValue! }

let bfi = BFInterpreter()

try bfi.read(program, with: input) // prints "   !,.<>Aabdeeeehilmnprtz"
print("Cycles: \(BFILogger.cycles) (+\(BFILogger.scans))")
