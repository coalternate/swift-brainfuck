# Swift Brainfuck

*Under heavy development. Things likely to change at a moment's notice, up until 1.0 release.*

### Usage

```swift
import Brainfuck

let program = "+[-->-[>>+>-----<<]<--<---]>-.>>>+.>>..+++[.>]<<<<.+++.------.<<-.>>>>+."

let interpreter = BFInterpreter()
try interpreter.run(program) // Prints "Hello, World!"
```

```swift
// from brainfuck.org
let bubbleSort = """
>>,[>>,]<<[
[<<]>>>>[
<<[>+<<+>-]
>>[>+<<<<[->]>[<]>>-]
<<<[[-]>>[>+<-]>>[<<<+>>>-]]
>>[[<+>-]>>]<
]<<[>>+<<-]<<
]>>>>[.>>]
"""

let input = "Alphabetize me, nerd!"

try interpreter.run(bubbleSort, with: input) // Prints "  !,Aabdeeeehilmnprtz"
```

Currently the library can only print its output to the console. This is much less than ideal, and is currently being changed. Check back soon for an update.

This package also comes bundled with a command-line tool, `bf`, available from the Releases page.

```zsh
Usage :: bf run <program> <input>
```

This is also being heavily worked on. Information about its usage will become available ~~at some indeterminate point in the future~~ **soon™**.

### About

It's in the name, 'innit? Seriously though, the scope of this is kinda huge. It'll run *any* brainfuck program. Period. `BFInterpreter()` has a whole slew of customizeable initialization settings, which tweak everything from cell width to boundary behaviour to input/output formatting. Documentation about how to use these settings will show up here as soon as the settings themselves are stable. Still pondering if there's a better way to pass them to the interpreter… In the meantime you can either read the code itself, or try `bf help run` to get a better understanding of what settings exist, and how to use them.
