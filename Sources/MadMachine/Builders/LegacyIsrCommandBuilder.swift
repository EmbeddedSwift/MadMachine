//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 01..
//

import Foundation
import PathKit
import ShellKit

struct LegacyIsrCommandBuilder {

    let machine: MadMachine
    let name: String
    let location: String
    
    var bin: String { MadMachine.Paths.work.location + "/legacy/gen_isr_tables" }
    
    init(machine: MadMachine,
         name: String,
         location: String)
    {
        self.machine = machine
        self.name = name
        self.location = location
    }

    var args: [String] {
        [
            "--output-source",
            "isr_tables.c",
            "--kernel " + "\(location)/\(name)_prebuilt.elf".quoted,
            "--intlist",
            "isrList.bin",
            "--sw-isr-table",
            "--vector-table"
        ]
    }

    func build() -> String {
        ([bin] + args).joined(separator: " \\\n")
    }
}
