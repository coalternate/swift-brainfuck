import ArgumentParser
import Brainfuck

struct Brainfuck: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "bf",
        abstract: "A neat utility for running brainfuck programs.",
        version: "1.0.0",
    
        subcommands: [Run.self],
        defaultSubcommand: Run.self)
}

Brainfuck.main()
