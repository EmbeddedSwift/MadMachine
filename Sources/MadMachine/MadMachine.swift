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
    var globalSearchPaths: [String] { (libraryPaths + [zephyrPath]).map(\.location) }

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
    
    // https://stackoverflow.com/questions/53077475/how-to-calculate-checksum-in-swift
    private func calculateCheckSum(crc: UInt8, byteValue: UInt8) -> UInt8 {
        let generator: UInt8 = 0x1D

        // a new variable has to be declared inside this function
        var newCrc = crc ^ byteValue

        for _ in 1...8 {
            if newCrc & 0x80 != 0 {
                newCrc = (newCrc << 1) ^ generator
            }
            else {
                newCrc <<= 1
            }
        }
        return newCrc
    }

    private func run(commands: [String], statusReport: ((Double, String) -> Void)? = nil) throws {
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

        let ar = ArCommandBuilder(machine: self, name: name, location: buildPath.location)
        
        var commands = [
            swiftc.build(target: .module),
            swiftc.build(target: .object),
            ar.build(),
            
            "rm \(buildPath.location)/*.o",
            "mkdir -p \(output)",
            "mv \(buildPath.location)/* \(output)",
        ].map { "cd \(buildPath.location) && " + $0 }
        
        commands.insert("mkdir -p \(buildPath.location)", at: 0)

        try run(commands: commands, statusReport: statusReport)

    }

    public func buildExecutable(name: String,
                                input: String,
                                output: String,
                                importHeaders: [String] = [],
                                importSearchPaths: [String] = [],
                                statusReport: ((Double, String) -> Void)? = nil) throws {
        
        let buildPath = Path(input).child(MadMachine.Directories.build)

        let searchPaths = importSearchPaths + globalSearchPaths
        
        let swiftc = SwiftcCommandBuilder(machine: self,
                                          name: name,
                                          location: input,
                                          importHeaders: importHeaders,
                                          importSearchPaths: searchPaths)

        let ar = ArCommandBuilder(machine: self, name: name, location: buildPath.location)

        
        let gpp = GppCommandBuilder(machine: self,
                                    name: name,
                                    location: buildPath.location,
                                    searchPaths: searchPaths)
        
        let objcopy = ObjcopyCommandBuilder(machine: self, name: name, location: buildPath.location)
        
        let gcc = GccCommandBuilder(machine: self, name: name, location: buildPath.location)
        
        let isr = LegacyIsrCommandBuilder(machine: self, name: name, location: buildPath.location)

        var commands = [
            swiftc.build(target: .executable),
            ar.build(),
            gpp.build(phase: .first),
            objcopy.buildIsr(),
            isr.build(),
            gcc.build(),
            gpp.build(phase: .second),
            objcopy.buildBinary(),

            "mkdir -p \(output)",
            "mv \(buildPath.location)/\(name).bin \(output)/swiftio.bin",
            "rm \(buildPath.location)/*.o",
        ].map { "cd \(buildPath.location) && " + $0 }
        
        commands.insert("mkdir -p \(buildPath.location)", at: 0)
        
        try run(commands: commands, statusReport: statusReport)

        /// crc to bin really
        let data = try Data(contentsOf: Path("\(output)/swiftio.bin").url)
        let checksum = CRC32.checksum(bytes: data)
        let mask: UInt32 = (1 << 8) - 1
        var newData = data.bytes
        for k in stride(from: 0, to: 32, by: 8) {
            let x = UInt32(k)
            let value: UInt32 = checksum >> x & mask
            let y = UInt8(value)
            newData.append(y)
        }
        try newData.data.write(to: Path("\(output)/swiftio.bin").url)
        try buildPath.delete()
        
    }
   
}




