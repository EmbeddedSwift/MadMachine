//
//  File.swift
//  
//
//  Created by Tibor Bodecs on 2020. 10. 01..
//

import Foundation
import PathKit
import ShellKit

struct CommandBuilder {

    let toolchainLocation: String

    enum Phase {
        case first
        case second
    }
    
    func gpp(name: String, buildPath: String, phase: Phase, searchPaths: [String] = []) -> String {

        var args = [
            toolchainLocation + "/gcc/bin/arm-none-eabi-g++",
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
            let linkScript = toolchainLocation + "/../../hal/HalSwiftIOBoard/generated/linker.cmd"
            let emptyFileObj = toolchainLocation + "/../../hal/HalSwiftIOBoard/generated/empty_file.c.obj"
            args += [
                "-Wl,-T \(linkScript.quoted)",
                emptyFileObj.quoted
            ]
        case .second:
            let mapTarget = buildPath + "/\(name)" + ".map"
            let linkScript = toolchainLocation + "/../../hal/HalSwiftIOBoard/generated/linker_pass_final.cmd"
            let isrTables = buildPath + "/isr_tables.c.obj"
            args += [
                "-Wl,-Map=\(mapTarget.quoted)",
                "-Wl,--print-memory-usage",
                "-Wl,-T \(linkScript.quoted)",
                isrTables.quoted,
            ]
        }
        
        let v7e = toolchainLocation + "/gcc/arm-none-eabi/lib/thumb/v7e-m"
        let v7eLib = toolchainLocation + "/gcc/lib/gcc/arm-none-eabi/7.3.1/thumb/v7e-m"
        let swiftrt = toolchainLocation + "/swift/lib/swift/zephyr/thumbv7em/swiftrt.o"
        let a = buildPath + "/lib" + name + ".a"
        args += [
            "-L \(v7e.quoted)",
            "-L \(v7eLib.quoted)",
            "-Wl,--whole-archive",
            swiftrt.quoted,
            a.quoted,
        ]
        
        let librarFiles = toolchainLocation + "/hal/HalSwiftIOBoard/generated/whole"
        args += FileManager.default.findFiles(at: librarFiles, "a").map(\.path).map(\.quoted).sorted()
        args += [
            "-Wl,--no-whole-archive",
            "-Wl,--start-group"
        ]
        
        var searchPaths = searchPaths
        if phase == .first {
            searchPaths += [toolchainLocation + "/hal/HalSwiftIOBoard/generated/no_whole"]
        }
        for path in searchPaths.reversed() {
            args += FileManager.default.findFiles(at: path, "a").map(\.path).map(\.quoted)
        }
        
        let elf = buildPath + "/\(name)" + (phase == .first ? "_prebuilt" : "") + ".elf"
        args += [
            "-lgcc",
            "-lstdc++",
            "-lm",
            "-lc",
            "-Wl,--end-group",
            "-o",
            elf,
        ]

        let cmd = args.joined(separator: " \\\n")
        
        return cmd
    }
    
    func genisr(name: String, buildPath: String) -> String {
        let elf = buildPath + "/\(name)" + "_prebuilt.elf"

        let args = [
            toolchainLocation + "/gcc/bin/arm-none-eabi-objcopy",
            "-I elf32-littlearm",
            "-O binary",
            "--only-section=.intList",
            elf.quoted,
            "isrList.bin"
        ]
        let cmd = args.joined(separator: " \\\n")

        return cmd
    }
    
    func isrtable(name: String, buildPath: String) -> String {
        let elf = buildPath + "/\(name)" + "_prebuilt.elf"
        let args = [
            toolchainLocation + "/gen_isr_tables",
            "--output-source",
            "isr_tables.c",
            "--kernel " + elf.quoted,
            "--intlist",
            "isrList.bin",
            "--sw-isr-table",
            "--vector-table"
        ]

        let cmd = args.joined(separator: " \\\n")

        return cmd
    }
    
    func compisr(name: String, buildPath: String) -> String {
        
        var args = [
            toolchainLocation + "/gcc/bin/arm-none-eabi-gcc",
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
        
        args += includePaths.map { toolchainLocation + $0 }.map(\.quoted).map { "-I \($0)" }

        let toolchain = toolchainLocation + "/gcc/arm-none-eabi/include"
        let macros = toolchainLocation + "/hal/HalSwiftIOBoard/generated/autoconf.h"
        let isrObj = buildPath + "/isr_tables.c.obj"
        let isr = buildPath + "/isr_tables.c"
        args += [
            "-isystem \(toolchain.quoted)",
            "-imacros \(macros.quoted)",
            "-o \(isrObj.quoted)",
            "-c \(isr.quoted)",
        ]

        let cmd = args.joined(separator: " \\\n")

        return cmd
    }
    

    func genBin(name: String, buildPath: String) -> String {
        let elf = buildPath + "/\(name)" + ".elf"
        let bin = buildPath + "/\(name)" + ".bin"
        
        let args = [
            toolchainLocation + "/gcc/bin/arm-none-eabi-objcopy",
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
            elf.quoted,
            bin.quoted,
        ]

        let cmd = args.joined(separator: " \\\n")

        return cmd
    }
    
    // https://stackoverflow.com/questions/53077475/how-to-calculate-checksum-in-swift
    func calculateCheckSum(crc: UInt8, byteValue: UInt8) -> UInt8 {
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
    
    
    func buildExecutable() {
//        let buildDir = ".build"
//        let projectName = "Blink"
//        let projectPath = Path("~/Documents/MadMachine/Examples/GettingStarted/Blink").location //Path.current.location
//        let buildPath = projectPath + "/" + buildDir
//        
//        let libz = Path(libLocation).children().filter(\.isDirectory).map(\.location)//.map { $0 + "/" + buildDir}
//        let searchPaths = libz + [toolchainLocation + "/swift/lib/swift/zephyr/thumbv7em"]
//        
////        let cmd1 = swiftc(workDir: projectPath, name: projectName, target: .executable, searchPaths: searchPaths)
////        let cmd2 = ar(name: projectName, buildPath: buildPath)
//        let cmd3 = gpp(name: projectName, buildPath: buildPath, phase: .first)
//        let cmd4 = genisr(name: projectName, buildPath: buildPath)
//        let cmd5 = isrtable(name: projectName, buildPath: buildPath)
//        let cmd6 = compisr(name: projectName, buildPath: buildPath)
//        let cmd7 = gpp(name: projectName, buildPath: buildPath, phase: .second)
//        let cmd8 = genBin(name: projectName, buildPath: buildPath)
        //let cmd9 = crctobin
        
//        let commands = [cmd1, cmd2, cmd3, cmd4, cmd5, cmd6, cmd7, cmd8]
//
//        let shell = Shell()
//        let semaphore = DispatchSemaphore(value: 0)
//        for (index, cmd) in commands.enumerated() {
//            shell.run(cmd) { result, error in
//                print("\(index) --> CMD", cmd)
//                print("\(index) --> result", result ?? "nil", "error", error?.localizedDescription ?? "nil")
//                semaphore.signal()
//            }
//            semaphore.wait()
//        }
    }
    
}
