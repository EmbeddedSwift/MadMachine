//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 03..
//

import Foundation

struct ObjcopyCommandBuilder {

    let machine: MadMachine
    let name: String
    let location: String
    
    var bin: String { machine.toolchainLocation + "/gcc/bin/arm-none-eabi-objcopy" }
    
    init(machine: MadMachine,
         name: String,
         location: String)
    {
        self.machine = machine
        self.name = name
        self.location = location
    }

    var isrArgs: [String] {
        [
            "-I elf32-littlearm",
            "-O binary",
            "--only-section=.intList",
            "\(location)/\(name)_prebuilt.elf".quoted,
            "isrList.bin"
        ]
    }

    func buildIsr() -> String {
        ([bin] + isrArgs).joined(separator: " \\\n")
    }


    var binArgs: [String] {
        [
            "-S",
            "-Obinary",
            "--gap-fill",
            "0xFF",
            "-R",
            ".comment",
            "-R",
            "COMMON",
            "-R",
            ".eh_frame",
            "\(location)/\(name).elf".quoted,
            "\(location)/\(name).bin".quoted,
        ]
    }

    func buildBinary() -> String {
        ([bin] + binArgs).joined(separator: " \\\n")
    }
}
