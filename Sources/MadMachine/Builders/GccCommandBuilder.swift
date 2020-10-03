//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 03..
//

import Foundation

struct GccCommandBuilder {
    
    let machine: MadMachine
    let name: String
    let location: String
    
    var bin: String { machine.toolchainLocation + "/gcc/bin/arm-none-eabi-gcc" }
    
    init(machine: MadMachine,
         name: String,
         location: String)
    {
        self.machine = machine
        self.name = name
        self.location = location
    }
    
    var args: [String] {
        var args = [
            "-DBOARD_FLASH_SIZE=CONFIG_FLASH_SIZE",
            "-DBUILD_VERSION=zephyr-v2.2.0",
            "-DCPU_MIMXRT1052DVL6B",
            "-DKERNEL",
            "-D_FORTIFY_SOURCE=2",
            "-D__LINUX_ERRNO_EXTENSIONS__",
            "-D__PROGRAM_START",
            "-D__ZEPHYR__=1",
            "-Os",
            "-ffreestanding",
            "-fno-common",
            "-g",
            "-mthumb",
            "-mcpu=cortex-m7",
            "-mfpu=fpv5-d16",
            "-mfloat-abi=soft",
            "-Wall",
            "-Wformat",
            "-Wformat-security",
            "-Wno-format-zero-length",
            "-Wno-main",
            "-Wno-pointer-sign",
            "-Wpointer-arith",
            "-Wno-unused-but-set-variable",
            "-Werror=implicit-int",
            "-fno-asynchronous-unwind-tables",
            "-fno-pie",
            "-fno-pic",
            "-fno-strict-overflow",
            "-fno-short-enums",
            "-fno-reorder-functions",
            "-fno-defer-pop",
            "-ffunction-sections",
            "-fdata-sections",
            "-mabi=aapcs",
            "-std=c99"
        ]

        let includePaths = [
            "/hal/HalSwiftIOBoard/zephyr/include",
            "/hal/HalSwiftIOBoard/zephyr/soc/arm/nxp_imx/rt",
            "/hal/HalSwiftIOBoard/zephyr/lib/libc/newlib/include",
            "/hal/HalSwiftIOBoard/zephyr/ext/hal/cmsis/Core/Include",
            "/hal/HalSwiftIOBoard/modules/hal/nxp/mcux/devices/MIMXRT1052",
            "/hal/HalSwiftIOBoard/modules/hal/nxp/mcux/drivers/imx",
            "/hal/HalSwiftIOBoard/generated"
        ]

        args += includePaths.map { machine.toolchainLocation + $0 }.map(\.quoted).map { "-I \($0)" }
        
        let toolchain = machine.toolchainLocation + "/gcc/arm-none-eabi/include"
        let macros = machine.toolchainLocation + "/hal/HalSwiftIOBoard/generated/autoconf.h"
        let isrObj = location + "/isr_tables.c.obj"
        let isr = location + "/isr_tables.c"
        args += [
            "-isystem \(toolchain.quoted)",
            "-imacros \(macros.quoted)",
            "-o \(isrObj.quoted)",
            "-c \(isr.quoted)",
        ]
        return args
    }
    
    func build() -> String {
        ([bin] + args).joined(separator: " \\\n")
    }
}

