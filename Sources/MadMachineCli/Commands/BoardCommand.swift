//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 04..
//

import Foundation
import ConsoleKit
import PathKit
import MadMachine

final class BoardCommand: Command {

    static let name = "board"

    struct Signature: CommandSignature {
        
        @Flag(name: "volume", short: "v", help: "Find the download volume of the connected (DL mode) board.")
        var volume: Bool
        
        @Flag(name: "eject", short: "e", help: "Eject the volume (restarts the board)")
        var eject: Bool
        
        @Flag(name: "clean", short: "c", help: "Eject the volume (restarts the board)")
        var clean: Bool

        @Option(name: "deploy", short: "d", help: "Deploys a binary file to the board")
        var deploy: String?

        @Option(name: "run", short: "r", help: "Run a binary (deploys it and restarts the board)")
        var run: String?
    }
        
    let help = "MadMachine board management utilities."

    func run(using context: CommandContext, signature: Signature) throws {
        if signature.eject {
            return try ejectVolume(using: context)
        }
        if signature.clean {
            return try cleanVolume(using: context)
        }
        if let location = signature.deploy {
            return try deployBinary(at: location.resolvedPath, using: context)
        }
        if let location = signature.run {
            return try runBinary(at: location.resolvedPath, using: context)
        }

        return try volume(using: context)
    }

    private func volume(using context: CommandContext) throws {
        let volume = try MadMachine().findBoardDownloadVolume()
        context.console.print(volume)
    }
    
    private func deployBinary(at location: String, using context: CommandContext) throws {
        try MadMachine().deployBinary(at: location)
    }
    
    private func ejectVolume(using context: CommandContext) throws {
        try MadMachine().eject()
    }
    
    private func cleanVolume(using context: CommandContext) throws {
        try MadMachine().reset()
    }

    private func runBinary(at location: String, using context: CommandContext) throws {
        try deployBinary(at: location, using: context)
        try ejectVolume(using: context)
    }
}
