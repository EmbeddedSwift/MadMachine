//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 02..
//

import Foundation
import ConsoleKit
import MadMachine
import PathKit
import ShellKit

final class LibraryCommand: Command {
    
    static let name = "library"

    struct Signature: CommandSignature {

        @Flag(name: "list", short: "l", help: "List available system libraries")
        var list: Bool
        
        @Option(name: "install", short: "i", help: "Location of the library (local path or HTTP URL)")
        var install: String?
        
        @Option(name: "uninstall", short: "u", help: "Name of the installed library")
        var uninstall: String?
    }

    let help = "System library management command"
   
    func run(using context: CommandContext, signature: Signature) throws {
        if let location = signature.install {
            return try install(location: location, using: context)
        }
        if let name = signature.uninstall {
            return try uninstall(name: name, using: context)
        }
        return try list(using: context)
    }
    
    // MARK: - private functions
    
    private func list(using context: CommandContext) throws {
        let list = MadMachine.Paths.lib.children()
            .filter(\.isVisible)
            .filter(\.isDirectory)
            .map(\.name)
        
        if !list.isEmpty {
            context.console.print(list.joined(separator: "\n"))
        }
    }
    
    private func install(location: String, using context: CommandContext) throws {
        let absolutePath = location.hasPrefix("/") ? Path(location) : Path.current.child(location)
        
        let files = absolutePath.children()
            .filter(\.isVisible)
            .filter(\.isFile)
        
        

        guard
            files.contains(where: { $0.extension == "swiftmodule" }),
            files.contains(where: { $0.extension == "swiftdoc" }),
            files.contains(where: { $0.extension == "a" })
        else {
            throw MadMachine.LibraryError.invalid
        }

        try absolutePath.copy(to: MadMachine.Paths.lib.child(absolutePath.name))
    }
    
    private func uninstall(name: String, using context: CommandContext) throws {
        try MadMachine.Paths.lib.child(name).delete()
    }
}
