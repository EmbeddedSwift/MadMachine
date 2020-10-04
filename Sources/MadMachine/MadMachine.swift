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
        public static let binaryName = "swiftio.bin"
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
    
    public enum BoardError: LocalizedError {
        case unavailable

        public var errorDescription: String? {
            switch self {
            case .unavailable:
                return "MadMachine board is unavailable."
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
                libLocation: String = MadMachine.Paths.lib.location) throws
    {
        let toolchainPath = Path(toolchainLocation)
        if !toolchainPath.exists || !toolchainPath.isDirectory {
            fatalError("Can not find toolchain path at `\(toolchainLocation)`")
        }
        let libPath = Path(libLocation)
        if !libPath.exists {
            try libPath.create()
        } else if !libPath.isDirectory {
            fatalError("Expected lib path to be a directory at `\(libLocation)`")
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

    private func run(commands: [(() -> String)], statusReport: ((Double, String) -> Void)? = nil) throws {
        var progress: Double = 0.0
        let increment: Double = (100.0 / Double(commands.count)) / 100.0

        for (i, cmd) in commands.enumerated() {
            let cmdStr = cmd()
            let output = try Shell().run(cmdStr)
            let log = """
            #\(i+1) - Command:
            `\(cmdStr)`

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
        
        let chdir = "cd \(buildPath.location) && "
        var commands: [(() -> String)] = [
            { chdir + swiftc.build(target: .module) },
            { chdir + swiftc.build(target: .object) },
            { chdir + ar.build() },
            
            { chdir + "rm \(buildPath.location)/*.o" },
            { chdir + "mkdir -p \(output)" } ,
            { chdir + "mv \(buildPath.location)/* \(output)" },
        ]
        
        commands.insert({ "mkdir -p \(buildPath.location)" }, at: 0)

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

        let chdir = "cd \(buildPath.location) && "
        var commands: [(() -> String)] = [
            { chdir + swiftc.build(target: .executable) },
            { chdir + ar.build() } ,
            { chdir + gpp.build(phase: .first) },
            { chdir + objcopy.buildIsr() },
            { chdir + isr.build() },
            { chdir + gcc.build() },
            { chdir + gpp.build(phase: .second) },
            { chdir + objcopy.buildBinary() },

            { chdir + "mkdir -p \(output)" },
            { chdir + "mv \(buildPath.location)/\(name).bin \(output)/\(MadMachine.Files.binaryName)" },
            { chdir + "rm \(buildPath.location)/*.o" },
        ]

        commands.insert({ "mkdir -p \(buildPath.location)" }, at: 0)

        try run(commands: commands, statusReport: statusReport)

        /// crc to bin, really basic solution
        let data = try Data(contentsOf: Path("\(output)/\(MadMachine.Files.binaryName)").url)
        let checksum = CRC32.checksum(bytes: data)

        let mask: UInt32 = (1 << 8) - 1
        var newData = data.bytes
        for k in stride(from: 0, to: 32, by: 8) {
            let x = UInt32(k)
            let value: UInt32 = checksum >> x & mask
            let y = UInt8(value)
            newData.append(y)
        }

        try newData.data.write(to: Path("\(output)/\(MadMachine.Files.binaryName)").url)
        try buildPath.delete()
        
    }

    /// this method will find the volume of the board if it is in download mode
    public func findBoardDownloadVolume() throws -> String {
        struct Volume: Decodable {
            let mount_point: String
        }

        struct MediaItem: Decodable {
            let volumes: [Volume]
        }

        struct USBItem: Decodable {
            let Media: [MediaItem]?
            let serial_num: String?
            let vendor_id: String?
            let product_id: String?
        }

        struct USBBus: Decodable {
            let _name: String
            let _items: [USBItem]?
        }

        struct SPUSBDataType: Decodable {
            let SPUSBDataType: [USBBus]
        }
        
        let output = try Shell().run("/usr/sbin/system_profiler -json SPUSBDataType")

        guard let data = output.data(using: .utf8) else {
            throw BoardError.unavailable
        }

        let bus = try JSONDecoder().decode(SPUSBDataType.self, from: data)
        let mountPoint = bus.SPUSBDataType.reduce([]) { (res: [USBItem], item: USBBus) in
              var newResult: [USBItem] = res
              newResult.append(contentsOf: item._items ?? [])
              return newResult
        }
        .first(where: { $0.serial_num == "0123456789ABCDEF" && $0.product_id == "0x0093"})?
        .Media?.first?
        .volumes.first?
        .mount_point
        .components(separatedBy: .newlines)
        .last

        guard let volume = mountPoint, volume.hasPrefix("/") else {
            throw BoardError.unavailable
        }
        return volume
    }
    
    public func deployBinary(at location: String) throws {
        let volume = try findBoardDownloadVolume()
        try Shell().run("cp \(location.quoted) \(volume.quoted)/\(MadMachine.Files.binaryName)")
    }

    public func eject() throws  {
        let volume = try findBoardDownloadVolume()
        try Shell().run("/usr/sbin/diskutil eject \(volume.quoted)")
    }
    
    public func reset() throws  {
        let volume = try findBoardDownloadVolume()
        try Shell().run("rm \(volume.quoted)/\(MadMachine.Files.binaryName)")
    }

}




