//
//  BuildCommand.swift
//  MadMachineCli
//
//  Created by Tibor Bodecs on 2020. 10. 02..
//

import Foundation
import ConsoleKit
import PathKit
import MadMachine

final class BuildCommand: Command {
    
    static let name = "build"

    /*
     swift run MadMachineCli build \
     --name SwiftIO \
     --input ../SwiftIO \
     --output ./SwiftIO \
     --import-headers ../SwiftIO/Sources/CHal/include/SwiftHalWrapper.h\
     --import-search-paths ./,../ \
     --verbose
     */
    struct Signature: CommandSignature {
        
        @Option(name: "name", short: "n", help: "Name of the build product")
        var name: String?
        
        @Option(name: "input", short: "i", help: "Location of the project to build")
        var input: String?
        
        @Option(name: "output", short: "o", help: "Path to the MadMachine Toolchain")
        var output: String?
        
        @Option(name: "toolchain", short: "t", help: "Path to the MadMachine Toolchain")
        var toolchain: String?
        
        @Option(name: "library", short: "l", help: "Path to the MadMachine System Library")
        var library: String?
        
        @Option(name: "import-headers", short: "h", help: "Headers to import (use a coma separated list)")
        var importHeaders: String?
        
        @Option(name: "import-search-paths", short: "p", help: "Paths to import (use a coma separated list)")
        var importSearchPaths: String?
        
        @Flag(name: "verbose", short: "v", help: "Verbose output")
        var verbose: Bool
    }
        
    let help = "MadMachine project executable and library builder"

    private func resolve(path: String) -> String {
        path.hasPrefix("/") ? path : Path.current.child(path).location
    }

    func run(using context: CommandContext, signature: Signature) throws {
        let n = signature.name ?? Path.current.basename

        var i = Path.current.location
        if let customInput = signature.input {
            i = resolve(path: customInput)
        }
        var o = Path.current.location
        if let customOutput = signature.output {
            o = resolve(path: customOutput)
        }
        var t = MadMachine.Paths.toolchain.location
        if let customToolchain = signature.toolchain {
            t = resolve(path: customToolchain)
        }
        var l = MadMachine.Paths.toolchain.location
        if let customLibrary = signature.library {
            l = resolve(path: customLibrary)
        }
        var h: [String] = []
        if let customImportHeaders = signature.importHeaders {
            h = customImportHeaders.split(separator: ",").map(String.init).map { resolve(path: $0)}
        }
        var p: [String] = []
        if let customImportSearchPaths = signature.importSearchPaths {
            p = customImportSearchPaths.split(separator: ",").map(String.init).map { resolve(path: $0)}
        }
                
        let mm = MadMachine(toolchainLocation: t, libLocation: l)

        if signature.verbose {
            let info = """
            MadMachine:
                Toolchain: `\(t)`
                Library: `\(l)`
            
            Project:
                Name: `\(n)`
                Input: `\(i)`
                Output: `\(o)`
                Import Headers:
                    \(h.map({ "`\($0)`" }).joined(separator: "\n            "))
                Import Search Paths:
                    \(p.map({ "`\($0)`" }).joined(separator: "\n            "))
            """
            context.console.info(info)
        }
        
        let progressBar = context.console.progressBar(title: "Building `\(n)` library")
        progressBar.start()

        var logs: [String] = []
        do {
            try mm.buildLibrary(name: n, input: i, output: o, importHeaders: h, importSearchPaths: p) { progress, log in
                progressBar.activity.currentProgress = progress
                logs.append(log)
            }
            progressBar.succeed()
        }
        catch {
            progressBar.fail()
            context.console.error(error.localizedDescription)
        }
        if signature.verbose {
            context.console.info(logs.joined(separator: "\n\n"))
        }
    }
}
