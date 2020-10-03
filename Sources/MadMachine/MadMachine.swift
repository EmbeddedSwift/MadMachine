//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 02..
//

import Foundation
import PathKit
import ShellKit

public struct MadMachine {

    public struct Files {
        public static let toolchainVersion = "toolchain-version"
    }

    public struct Directories {
        public static let work = ".MadMachine"
        public static let toolchain = "toolchain"
        public static let lib = "lib"
        public static let build = ".build"
    }

    public struct Paths {
        public static let work = Path.home.child(MadMachine.Directories.work)
        public static let toolchain = MadMachine.Paths.work.child(MadMachine.Directories.toolchain)
        public static let toolchainVersion = MadMachine.Paths.work.child(MadMachine.Files.toolchainVersion)
        public static let lib = MadMachine.Paths.work.child(MadMachine.Directories.lib)
    }

    public enum ToolchainError: LocalizedError {
        case missing
        case download

        public var errorDescription: String? {
            switch self {
            case .missing:
                return "Missing toolchain."
            case .download:
                return "Could not download toolchain."
            }
        }
    }
    
    public enum LibraryError: LocalizedError {
        case invalid

        public var errorDescription: String? {
            switch self {
            case .invalid:
                return "Invalid library contents."
            }
        }
    }
    
    public static let toolchainRepo = "EmbeddedSwift/MadMachineToolchain"

    let toolchainLocation: String
    let libLocation: String
    
    var zephyrPath: Path { Path(toolchainLocation + "/swift/lib/swift/zephyr/thumbv7em") }
    var libraryPaths: [Path] { Path(libLocation).children().filter(\.isVisible).filter(\.isDirectory) }
    var globalSearchPaths: [String] { ([zephyrPath] + libraryPaths).map(\.location) }

    /// note: this could be a throwing init...?
    public init(toolchainLocation: String = MadMachine.Paths.toolchain.location,
                libLocation: String = MadMachine.Paths.lib.location)
    {
        let toolchainPath = Path(toolchainLocation)
        if !toolchainPath.exists || !toolchainPath.isDirectory {
            fatalError("Can not find toolchain path at `\(toolchainLocation)`")
        }
        let libPath = Path(libLocation)
        if !libPath.exists || !libPath.isDirectory {
            fatalError("Can not find lib path at `\(libLocation)`")
        }
        self.toolchainLocation = toolchainLocation
        self.libLocation = libLocation
    }
    
    /**
        This method will build the library product files

            [<name>.modulemap, <name>.swiftdoc, .lib<name>.a]
     */
    public func buildLibrary(name: String,
                             input: String,
                             output: String,
                             importHeaders: [String] = [],
                             importSearchPaths: [String] = [],
                             statusReport: ((Double, String) -> Void)? = nil) throws {

        let buildPath = Path(input).child(MadMachine.Directories.build)

        let swiftc = SwiftcCommandBuilder(machine: self,
                                          name: name,
                                          location: input,
                                          importHeaders: importHeaders,
                                          importSearchPaths: importSearchPaths + globalSearchPaths)

        let moduleBuildCommand = swiftc.build(target: .module)
        let objectBuildCommand = swiftc.build(target: .object)

        let ar = ArCommandBuilder(machine: self, name: name, location: buildPath.location)
        
        var commands = [
            moduleBuildCommand,
            objectBuildCommand,
            ar.build(),
            "rm \(buildPath.location)/*.o",
            "mkdir -p \(output)",
            "mv \(buildPath.location)/* \(output)",
        ].map { "cd \(buildPath.location) && " + $0 }
        
        commands.insert("mkdir -p \(buildPath.location)", at: 0)

        var progress: Double = 0.0
        let increment: Double = (100.0 / Double(commands.count)) / 100.0

        for (i, cmd) in commands.enumerated() {
            let output = try Shell().run(cmd)
            let log = """
            #\(i+1) - Command:
            `\(cmd)`

            #\(i+1) - Output:
            `\(output)`

            """
            progress += increment
            statusReport?(progress, log)
        }
    }
   
}
