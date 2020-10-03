//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 02..
//

import Foundation

struct ArCommandBuilder {

    let machine: MadMachine
    let name: String
    let location: String
    
    var bin: String { machine.toolchainLocation + "/gcc/bin/arm-none-eabi-ar" }
    
    init(machine: MadMachine,
         name: String,
         location: String)
    {
        self.machine = machine
        self.name = name
        self.location = location
    }

    var args: [String] {
        ["-rcs", "lib\(name).a"] + FileManager.default.findFiles(at: location, "o").map(\.path).map(\.quoted)
    }

    func build() -> String {
        ([bin] + args).joined(separator: " \\\n")
    }
}

