// <->>--=[:: * THE BRAINFUCK INTERPRETER * ::]=--<<-> //

// under construction ::
// :: variable, property, and method names likely to change without warning

enum BFIError: Error {
    case unmatchedBracket
    
    // these errors can be ignored by the interpreter if chosen
    case pointerOutOfBounds
    case cellLimitReached
}

public struct BFInterpreter {
    public enum BoundaryType { case unbounded, halfBounded, bounded(Int), boundless(Int) }
    public enum CellWidth    { case eight, sixteen, thirtytwo, sixtyfour }
    public enum EOFHandling  { case zero, minusOne, unchanged } // maybe mode for "wait until more input"
    
    // tape settings
    let boundaryType:    BoundaryType
    let cellWidth:       CellWidth
    let cellWrapping:    Bool
    let useSignedCells:  Bool

    // IO settings
    let eofHandling: EOFHandling
    let useAsciiIO:  Bool

    // dev settings
    let useDebugCommand:    Bool
    let debugBreaksProgram: Bool
    
    // interpreter settings
    let useInputSplitter: Bool
    let filterSplitInput: Bool
    let preloadJumps:     Bool
    let ignoreErrors:     Bool

    public init(boundaryType:    BoundaryType = .halfBounded,
                cellWidth:       CellWidth    = .eight,
                cellWrapping:    Bool = true,
                useSignedCells:  Bool = false,
                
                eofHandling:  EOFHandling = .unchanged,
                useAsciiIO:   Bool = true,
                
                useDebugCommand:    Bool = false,
                debugBreaksProgram: Bool = false,
                
                useInputSplitter: Bool = false,
                filterSplitInput: Bool = false,
                preloadJumps:     Bool = true,
                ignoreErrors:     Bool = false) {

        self.boundaryType    = boundaryType
        self.cellWrapping    = cellWrapping
        self.cellWidth       = cellWidth
        self.useSignedCells  = useSignedCells

        self.eofHandling = eofHandling
        self.useAsciiIO  = useAsciiIO

        self.useDebugCommand    = useDebugCommand
        self.debugBreaksProgram = debugBreaksProgram
        
        self.useInputSplitter = useInputSplitter
        self.filterSplitInput = filterSplitInput
        self.preloadJumps     = preloadJumps
        self.ignoreErrors     = ignoreErrors
    }

    public func read<T: FixedWidthInteger>(_ initialString: String, with initialInput: [T]) throws {
        var input   = initialInput
        var program = initialString.compactMap { BFCommand(rawValue: $0) }
        
        if self.useInputSplitter {
            let string = initialString
            let array  = string.split(maxSplits: 1, whereSeparator: { $0 == "!" })
            
            if array.count > 1 {
                var _input = array[1]
                
                if self.filterSplitInput { _input = _input.filter { BFCommand(rawValue: $0) != nil } }
                
                // StreamTypeConverter comes from Toolkit, and is very handy for this package
                input = StreamTypeConverter.convert(_input.compactMap { $0.asciiValue }, toType: 0 as T)
            }
            
            program = array[0].compactMap { BFCommand(rawValue: $0) }
        }
        
        if !self.useDebugCommand { program = program.filter { $0 != .debug } }
        
        // pretty print commands; for magic logger
        // print(program.map { String($0.rawValue) }.reduce("", +))

        let tapeLength: Int

        switch self.boundaryType {
        case .unbounded, .halfBounded:                     tapeLength = 1
        case .bounded(let length), .boundless(let length): tapeLength = length
        }
        
        let tape = Array(repeating: 0 as UInt8, count: tapeLength)

        var maps: ([Int: Int], [Int: Int]) = ([:], [:])
        
        if self.preloadJumps {
            var stack: [Int] = []

            var map:  [Int: Int] = [:]
            var bmap: [Int: Int] = [:]

            for (location, command) in program.enumerated() {
                if command == .jump {
                    stack.append(location)
                } else if command == .bjump {
                    if let match = stack.popLast() {
                        map[match]     = location
                        bmap[location] = match
                    } else {
                        throw BFIError.unmatchedBracket
                    }
                }

                BFILogger.nextScan()
            }

            guard stack.isEmpty else {
                throw BFIError.unmatchedBracket
            }

            maps = (map, bmap)
        }

        if self.useSignedCells {
            switch self.cellWidth {
            case .eight:     try self.run(program,
                                          onTape:    StreamTypeConverter.convert(tape,  toType: 0 as Int8),
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as Int8),
                                          using:     maps)
            case .sixteen:   try self.run(program,
                                          onTape:    StreamTypeConverter.convert(tape,  toType: 0 as Int16),
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as Int16),
                                          using:     maps)
            case .thirtytwo: try self.run(program,
                                          onTape:    StreamTypeConverter.convert(tape,  toType: 0 as Int32),
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as Int32),
                                          using:     maps)
            case .sixtyfour: try self.run(program,
                                          onTape:    StreamTypeConverter.convert(tape,  toType: 0 as Int64),
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as Int64),
                                          using:     maps)
            }
        } else {
            switch self.cellWidth {
            case .eight:     try self.run(program,
                                          onTape:    tape,
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as UInt8),
                                          using:     maps)
            case .sixteen:   try self.run(program,
                                          onTape:    StreamTypeConverter.convert(tape,  toType: 0 as UInt16),
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as UInt16),
                                          using:     maps)
            case .thirtytwo: try self.run(program,
                                          onTape:    StreamTypeConverter.convert(tape,  toType: 0 as UInt32),
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as UInt32),
                                          using:     maps)
            case .sixtyfour: try self.run(program,
                                          onTape:    StreamTypeConverter.convert(tape,  toType: 0 as UInt64),
                                          withInput: StreamTypeConverter.convert(input, toType: 0 as UInt64),
                                          using:     maps)
            }
        }
    }

    private func run<T: FixedWidthInteger>(_ program:    [BFCommand],
                                      onTape initialTape:        [T],
                                   withInput initialInput:       [T],
                                       using maps:  ([Int: Int], [Int: Int])) throws {

        var  flipped = false
        var  tape    = initialTape
        var _tape    = initialTape

        var stack: [Int] = []
        let (map, bmap)  = maps

        var index: Int
        var  pointer = 0 // tape pointer
        var _pointer = 0 // command pointer

        var input  = initialInput
        var output = initialInput.cleared() // function comes from Toolkit, creates empty array of same type.
        
        var asciiInput  = StreamTypeConverter.convert(initialInput, toType: 0 as UInt8)
        var asciiOutput = [UInt8]()
        
    program: while _pointer < program.endIndex {
            index = flipped ? abs(pointer) - 1 : pointer

            switch program[_pointer] {
            case .left:
                pointer -= 1

                if flipped && abs(pointer) > tape.count { tape.append(0) }

                if !flipped && pointer < 0 {
                    switch self.boundaryType {
                    case .unbounded:
                        let t    =  tape
                            tape = _tape
                           _tape =  t

                        flipped = true
                    case .halfBounded, .bounded:
                        if self.ignoreErrors { pointer = 0 } else { throw BFIError.pointerOutOfBounds }
                    case .boundless:
                        pointer = tape.endIndex - 1
                    }
                }
            case .right:
                pointer += 1

                if flipped && pointer == 0 {
                    let t    =  tape
                        tape = _tape
                       _tape =  t

                    flipped = false
                }

                if pointer == tape.endIndex {
                    switch self.boundaryType {
                    case .unbounded, .halfBounded:
                        tape.append(0)
                    case .bounded:
                        if self.ignoreErrors { pointer = tape.endIndex - 1 } else { throw BFIError.pointerOutOfBounds }
                    case .boundless:
                        pointer = 0
                    }
                }
            case .plus:
                tape[index] &+= 1
                
                if !self.cellWrapping && tape[index] == .min {
                    tape[index] &-= 1

                    if !self.ignoreErrors { throw BFIError.cellLimitReached }
                }
            case .minus:
                tape[index] &-= 1
                
                if !self.cellWrapping && tape[index] == .max {
                    tape[index] &+= 1

                    if !self.ignoreErrors { throw BFIError.cellLimitReached }
                }
            case .jump:
                if self.preloadJumps {
                    if tape[index] == 0 { _pointer = map[_pointer]! }
                } else {
                    stack.append(_pointer)
                    if tape[index] == 0 {
                        stack.removeLast()
                        var depth = 1

                        while depth != 0 {
                            BFILogger.nextScan()

                            _pointer += 1
                            if _pointer == program.endIndex { throw BFIError.unmatchedBracket }
                            if program[_pointer] == .jump { depth += 1 } else if program[_pointer] == .bjump { depth -= 1 }
                        }
                    }
                }
            case .bjump:
                if self.preloadJumps {
                    if tape[index] != 0 { _pointer = bmap[_pointer]! }
                } else {
                    if let location = stack.popLast() {
                        if tape[index] != 0 {
                            stack.append(location)
                            _pointer = location
                        }
                    } else {
                        throw BFIError.unmatchedBracket
                    }
                }
            case .read:
                if self.useAsciiIO && asciiInput.first != nil {
                    tape[index] = StreamTypeConverter.convert([asciiInput.removeFirst()], toType: 0 as T).first!
                } else if !self.useAsciiIO && input.first != nil {
                    tape[index] = input.removeFirst()
                } else {
                    switch self.eofHandling {
                    case .zero:      tape[index] = 0
                    case .minusOne:  tape[index] = 0 &- 1
                    case .unchanged: break // maybe wait until more input is available?
                    }
                }
            case .write: // potential async
                if self.useAsciiIO {
                    asciiOutput.append(contentsOf: StreamTypeConverter.convert([tape[index]], toType: 0 as UInt8))
                } else {
                    output.append(tape[index])
                }
            case .debug: // potential async. maybe file handler? have to wait until packaged/command line tool
                // Under development, likely to change
                print("Pointer @ Cell \(pointer) -> \(tape[index]) :: \(tape) ::")
                
                // probably my favorite line. the semantics are just *chef's kiss*
                if self.debugBreaksProgram { print("Breaking program..."); break program } // print is temporary
            }

            _pointer += 1

            BFILogger.nextCycle()
        }
        
        // temporary output display. will probably change.
        if self.useAsciiIO {
            print(asciiOutput.map { String(Character(UnicodeScalar($0))) }.joined())
            print("\nOutput :: \(asciiOutput) :: \(type(of: output))")
        } else {
            print("Output :: \(output) :: \(type(of: output))")
        }
    }
}
