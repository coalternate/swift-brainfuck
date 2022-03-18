import ArgumentParser
import Brainfuck

struct Brainfuck: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "bf",
        abstract: "A neat utility for running brainfuck programs.",
        version: "0.0.1",
    
        subcommands: [Run.self],
        defaultSubcommand: Run.self)
}

Brainfuck.main()
