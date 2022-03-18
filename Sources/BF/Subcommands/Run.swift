// Making this into a subcommand doesn't make a whole lot of sense if its the only subcommand,
// but future versions will have different subcommands, so consider this "future-proofing"
import ArgumentParser
import Brainfuck

enum BoundaryType: EnumerableFlag {
    case unbounded, halfBounded, bounded, boundless
    
    public static func name(for value: Self) -> NameSpecification {
        switch value {
        case .boundless: return [.customShort("e"), .long]
        default: return .shortAndLong
        }
    }
    
    public static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .unbounded:   return "Extend the tape length at the left and right boundaries."
        case .halfBounded: return "Extend the tape length at the right boundary only."
        case .bounded:     return "Use a fixed tape length. Requires --length option."
        case .boundless:   return "Use a fixed tape length, wrapping to opposite boundary as needed. Requires --length option."
        }
    }
}

enum CellWidth: EnumerableFlag {
    case small, medium, large, extraLarge
    
    public static func name(for value: Self) -> NameSpecification {
        switch value {
        case .small:      return [.short, .customLong("small-cells")]
        case .medium:     return [.short, .customLong("medium-cells")]
        case .large:      return [.short, .customLong("large-cells")]
        case .extraLarge: return [.customShort("x"), .customLong("extra-large-cells")]
        }
    }
    
    public static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .small:      return "Set the cell width to 8 bits."
        case .medium:     return "Set the cell width to 16 bits."
        case .large:      return "Set the cell width to 32 bits."
        case .extraLarge: return "Set the cell width to 64 bits."
        }
    }
}

enum EOFHandling: EnumerableFlag {
    case unchanged, zero, minusOne
    
    public static func name(for value: Self) -> NameSpecification {
        switch value {
        case .unchanged: return [.customShort("c"), .long]
        case .zero: return .shortAndLong
        case .minusOne: return [.customShort("i"), .long]
        }
    }
    
    public static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .unchanged:      return "Leave the cell value unchanged when EOF is read."
        case .zero:     return "Set the cell value to 0 when EOF is read."
        case .minusOne:      return "Set the cell value to -1 (or unsigned equivalent) when EOF is read."
        }
    }
}

extension Brainfuck {
    struct Run: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Run a brainfuck program, printing the output.")
        
        @Flag(exclusivity: .exclusive)
        var _boundaryType: BoundaryType = .unbounded
        
        @Option(help: ArgumentHelp(
            "Set the tape length to <n> cells. Ignored if boundary type is -u or -h.",
            valueName: "n"))
        var length: Int?
        
        @Flag(exclusivity: .exclusive)
        var _cellWidth: CellWidth = .small
        
        @Flag(exclusivity: .exclusive)
        var _eofHandling: EOFHandling = .unchanged
        
        @Flag(name: [.customShort("d"), .customLong("debug-mode")],
              help: "Enable the use of the debug command '#' in <program>.")
        var useDebugCommand: Bool = false
        
        @Flag(name: [.customShort("k"), .customLong("break-program")],
              help: ArgumentHelp("Halts execution of <program> at debug command '#'.",
                                 discussion: "This flag does nothing if the debug command isn't first enabled with -d."))
        var debugBreaksProgram: Bool = false
        
        @Flag(name: .customLong("raw-negatives"),
              help: ArgumentHelp("Allow cells to store negative numbers.",
                                 discussion: "Makes no functional difference to how the program runs, but it does change what the output stream looks like."))
        var useSignedCells = false
        
        @Flag(name:      .customLong("wrap"),
              inversion: .prefixedNo,
              help:      ArgumentHelp("Wrap cell values when moving beyond cell limits.",
                                      discussion: "Uncommon setting. Most brainfuck programs require this to be enabled at all times."))
        var cellWrapping: Bool = true
        
        @Flag(name: .customLong("using-splitter"),
              help: ArgumentHelp("Enable the use of '!' command to split input from program.",
                                 discussion: "Useful for brainfuck self-interpreters and not much else."))
        var useInputSplitter: Bool = false
        
        @Flag(help: "Filter the input, keeping only valid brainfuck commands.")
        var filteringInput: Bool = false
        
        @Flag(name:      .customLong("ascii"),
              inversion: .prefixedNo,
              help:      "Enable/disable ASCII-safe input/output.")
        var useAsciiIO: Bool = true
        
        @Flag(name: .customLong("jump-mapping"),
              inversion: .prefixedEnableDisable,
              help: ArgumentHelp("Calculate all jump points before running <program>.",
                                 discussion: "If disabled, the jump points are dynamically calculated each time a jump is called."))
        var mappingJumps: Bool = true
        
        @Flag(help: "Avoids most errors by creating undefined behavior :P")
        var ignoringErrors: Bool = false
        
        @Argument(help: "The brainfuck program to run.")
        var program: String
        
        @Argument(help: "Input for the brainfuck program.")
        var input: String?
        
        mutating func validate() throws {
            if _boundaryType == .bounded || _boundaryType == .boundless {
                guard length != nil else {
                    throw ValidationError("Chosen boundary type requires a 'length' of at least 1.")
                }
                
                guard length! > 0 else {
                    throw ValidationError("Chosen boundary type requires a 'length' of at least 1.")
                }
            }
        }
        
        mutating func run() throws {
            let boundaryType: BFInterpreter.BoundaryType
            switch _boundaryType {
            case .unbounded:   boundaryType = .unbounded
            case .halfBounded: boundaryType = .halfBounded
            case .bounded:     boundaryType = .bounded(length!)
            case .boundless:   boundaryType = .boundless(length!)
            }
            
            let cellWidth: BFInterpreter.CellWidth
            switch _cellWidth {
            case .small:      cellWidth = .eight
            case .medium:     cellWidth = .sixteen
            case .large:      cellWidth = .thirtyTwo
            case .extraLarge: cellWidth = .sixtyFour
            }
            
            let eofHandling: BFInterpreter.EOFHandling
            switch _eofHandling {
            case .unchanged: eofHandling = .unchanged
            case .zero:      eofHandling = .zero
            case .minusOne:  eofHandling = .minusOne
            }
            
            let interpreter = BFInterpreter(boundaryType:   boundaryType,
                                            cellWidth:      cellWidth,
                                            cellWrapping:   cellWrapping,
                                            useSignedCells: useSignedCells,

                                            eofHandling:    eofHandling,
                                            filteringInput: filteringInput,
                                            useAsciiIO:     useAsciiIO,

                                            useDebugCommand:    useDebugCommand,
                                            debugBreaksProgram: debugBreaksProgram,

                                            useInputSplitter: useInputSplitter,
                                            mappingJumps:     mappingJumps,
                                            ignoringErrors:   ignoringErrors)
            
            var initialInput: String = ""
            if let _input = input { initialInput = _input }
            
            try interpreter.run(program, with: initialInput)
        }
    }
}
