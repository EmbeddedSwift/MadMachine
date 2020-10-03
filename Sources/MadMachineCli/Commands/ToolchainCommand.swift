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

final class ToolchainCommand: Command {
    
    static let name = "toolchain"

    struct Signature: CommandSignature {
        
        @Flag(name: "version", short: "v", help: "Get the system toolchain version")
        var version: Bool
        
        @Flag(name: "upgrade", short: "u", help: "Upgrade the system toolchain to the latest version")
        var upgrade: Bool
        
        @Option(name: "set", short: "s", help: "Set the system toolchain to the given version")
        var set: String?
        
        @Flag(name: "destroy", short: "d", help: "Destroy the system toolchain")
        var destroy: Bool
    }
        
    let help = "Toolchain management"

    func run(using context: CommandContext, signature: Signature) throws {
        
        if signature.upgrade {
            return try upgrade(using: context)
        }
        if let version = signature.set {
            return try set(version: version, using: context)
        }
        if signature.destroy {
            return try destroy(using: context)
        }
        return try version(using: context)
    }
    
    // MARK: - private functions
    
    private var operatingSystem: String {
        #if os(macOS)
            let os = "mac"
        #elseif os(Linux)
            let os = "linux"
        #elseif os(Windows)
            let os = "win"
        #else
            fatalError("Unsupported operating system")
        #endif

        return os
    }
    
    private func version(using context: CommandContext) throws {
        let filePath = MadMachine.Paths.toolchainVersion

        guard filePath.exists && filePath.isFile else {
            throw MadMachine.ToolchainError.missing
        }
        let version = try String(contentsOfFile: filePath.location, encoding: .utf8)
        context.console.print(version)
    }
    
    private func upgrade(using context: CommandContext) throws {
        try destroy(using: context)

        let info = GitHub(repo: MadMachine.toolchainRepo).latestVersion
        try install(version: info.version)
    }
    
    private func set(version: String, using context: CommandContext) throws {
        /// todo: check if version exists in the remote repository before destroying the toolchain
        try destroy(using: context)

        try install(version: version)
    }
    
    private func destroy(using context: CommandContext) throws {
        try MadMachine.Paths.toolchain.delete()
        try MadMachine.Paths.toolchainVersion.delete()
    }

    private func install(version: String) throws {
        let os = operatingSystem
        let zipFileName = "mm-toolchain-\(version)-\(os).tar.gz"
        let toolchainPath = MadMachine.Paths.toolchain
        let zipFilePath = toolchainPath.child(zipFileName)
        let link = "https://github.com/\(MadMachine.toolchainRepo)/releases/download/\(version)/\(zipFileName)"

        let progressBar = context.console.progressBar(title: "Downloading MadMachine Toolchain - v\(version) for \(os)")
        progressBar.start()

        /// create toolchain folder upfront
        try Shell().run("mkdir -p \(toolchainPath.location)")

        let downloader = Downloader(link: link) { progress in
            progressBar.activity.currentProgress = progress
        }
        let downloadUrl = downloader.download(to: zipFilePath.location)
        
        guard let _ = downloadUrl else {
            progressBar.fail()
            throw MadMachine.ToolchainError.download
        }
        progressBar.succeed()

        try Shell().run("cd \(toolchainPath.location) && tar -xf \(zipFilePath.location)")
        try zipFilePath.delete()

        try version.write(toFile: MadMachine.Paths.toolchainVersion.location, atomically: true, encoding: .utf8)
    }
}
