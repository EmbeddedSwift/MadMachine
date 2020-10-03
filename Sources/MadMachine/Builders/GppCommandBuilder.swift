//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 03..
//

import Foundation

struct GppCommandBuilder {
    
    enum Phase {
        case first
        case second
    }
    
    let machine: MadMachine
    let name: String
    let location: String
    let searchPaths: [String]
    
    var bin: String { machine.toolchainLocation + "/gcc/bin/arm-none-eabi-g++" }
    
    init(machine: MadMachine,
         name: String,
         location: String,
         searchPaths: [String])
    {
        self.machine = machine
        self.name = name
        self.location = location
        self.searchPaths = searchPaths
    }
    
    func args(for phase: Phase) -> [String] {
        var args = [
            "-mcpu=cortex-m7",
            "-mthumb",
            "-mfpu=fpv5-d16",
            "-mfloat-abi=soft",
            "-mabi=aapcs",
            "-nostdlib",
            "-static",
            "-no-pie",
            "-Wl,-u,_OffsetAbsSyms",
            "-Wl,-u,_ConfigAbsSyms",
            "-Wl,-X",
            "-Wl,-N",
            "-Wl,--gc-sections",
            "-Wl,--build-id=none",
            "-Wl,--sort-common=descending",
            "-Wl,--sort-section=alignment",
            "-Wl,--no-enum-size-warning",
        ]

        switch phase {
        case .first:
            let linkScript = machine.toolchainLocation + "/hal/HalSwiftIOBoard/generated/linker.cmd"
            let emptyFileObj = machine.toolchainLocation + "/hal/HalSwiftIOBoard/generated/empty_file.c.obj"
            args += [
                "-Wl,-T \(linkScript.quoted)",
                emptyFileObj.quoted
            ]
        case .second:
            let mapTarget = location + "/\(name)" + ".map"
            let linkScript = machine.toolchainLocation + "/hal/HalSwiftIOBoard/generated/linker_pass_final.cmd"
            let isrTables = location + "/isr_tables.c.obj"
            args += [
                "-Wl,-Map=\(mapTarget.quoted)",
                "-Wl,--print-memory-usage",
                "-Wl,-T \(linkScript.quoted)",
                isrTables.quoted,
            ]
        }
        
        let v7e = machine.toolchainLocation + "/gcc/arm-none-eabi/lib/thumb/v7e-m"
        let v7eLib = machine.toolchainLocation + "/gcc/lib/gcc/arm-none-eabi/7.3.1/thumb/v7e-m"
        let swiftrt = machine.toolchainLocation + "/swift/lib/swift/zephyr/thumbv7em/swiftrt.o"
        let a = location + "/lib" + name + ".a"
        args += [
            "-L\(v7e.quoted)",
            "-L\(v7eLib.quoted)",
            "-Wl,--whole-archive",
            swiftrt.quoted,
            a.quoted,
        ]
        
        let librarFiles = machine.toolchainLocation + "/hal/HalSwiftIOBoard/generated/whole"
        args += FileManager.default.findFiles(at: librarFiles, "a").map(\.path).map(\.quoted).sorted()
        args += [
            "-Wl,--no-whole-archive",
            "-Wl,--start-group"
        ]
        
        let paths = searchPaths + [machine.toolchainLocation + "/hal/HalSwiftIOBoard/generated/no_whole"]        
        for path in paths.reversed() {
            args += FileManager.default.findFiles(at: path, "a").map(\.path).map(\.quoted)
        }
        
        let elf = location + "/\(name)" + (phase == .first ? "_prebuilt" : "") + ".elf"
        args += [
            "-lgcc",
            "-lstdc++",
            "-lm",
            "-lc",
            "-Wl,--end-group",
            "-o",
            elf,
        ]

        return args
    }
    
    func build(phase: Phase) -> String {
        ([bin] + args(for: phase)).joined(separator: " \\\n")
    }
}

