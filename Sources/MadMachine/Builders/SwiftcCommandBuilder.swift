//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 02..
//

import Foundation

struct SwiftcCommandBuilder {

    enum Target {
        case module
        case object
        case executable
    }
    
    let machine: MadMachine
    let name: String
    let location: String
    let importHeaders: [String]
    let importSearchPaths: [String]

    var bin: String { machine.toolchainLocation + "/swift/bin/swiftc" }
    var src: String { location + "/Sources" }
    
    init(machine: MadMachine,
         name: String,
         location: String,
         importHeaders: [String] = [],
         importSearchPaths: [String] = [])
    {
        self.machine = machine
        self.name = name
        self.location = location
        self.importHeaders = importHeaders
        self.importSearchPaths = importSearchPaths
    }

    func args(for target: Target) -> [String] {
        var args = [
            "-module-name \(name.quoted)",
            "-target thumbv7em-none--eabi",
            "-target-cpu cortex-m7",
            "-target-fpu fpv5-dp-d16",
            "-float-abi soft",
            "-O",
            "-static-stdlib",
            "-function-sections",
            "-data-sections",
            "-Xcc -D__ZEPHYR__",
            "-Xfrontend -assume-single-threaded",
            "-no-link-objc-runtime",
            "-D MM_BUILD",
        ]

        switch target {
        case .module:
            args.insert("-emit-module", at: 0)
            args.insert("-parse-as-library", at: 0)
        case .object:
            args.insert("-c", at: 0)
            args.insert("-parse-as-library", at: 0)
        case .executable:
            args.insert("-c", at: 0)
        }

        args += importHeaders.map { "-import-objc-header \($0.quoted)" }
        args += importSearchPaths.map { "-I \($0.quoted)" }
        args += FileManager.default.findFiles(at: src, "swift").map(\.path).map(\.quoted).sorted()

        return args
    }

    func build(target: Target) -> String {
        ([bin] + args(for: target)).joined(separator: " \\\n")
    }
}

