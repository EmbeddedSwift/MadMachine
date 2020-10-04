//
//  main.swift
//  MadMachineCli
//
//  Created by Tibor Bodecs on 2020. 10. 01..
//

import Foundation
import ConsoleKit

let console: Console = Terminal()
var input = CommandInput(arguments: CommandLine.arguments)
var context = CommandContext(console: console, input: input)

var commands = Commands(enableAutocomplete: true)
commands.use(ToolchainCommand(), as: ToolchainCommand.name, isDefault: false)
commands.use(LibraryCommand(), as: LibraryCommand.name, isDefault: false)
commands.use(BuildCommand(), as: BuildCommand.name, isDefault: false)
commands.use(BoardCommand(), as: BoardCommand.name, isDefault: false)

do {
    let group = commands.group(help: "MadMachine command line utility")
    try console.run(group, input: input)
}
catch {
    console.error(error.localizedDescription)
    exit(1)
}
