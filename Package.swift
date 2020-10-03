// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "MadMachine",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "MadMachine", targets: ["MadMachine"]),
        .executable(name: "MadMachineCli", targets: ["MadMachineCli"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/console-kit", from: "4.2.0"),
        .package(url: "https://github.com/binarybirds/shell-kit", from: "1.0.0"),
        .package(url: "https://github.com/binarybirds/path-kit", from: "1.0.0"),
    ],
    targets: [
        .target(name: "MadMachine", dependencies: [
            .product(name: "PathKit", package: "path-kit"),
            .product(name: "ShellKit", package: "shell-kit"),
        ]),
        .target(name: "MadMachineCli", dependencies: [
            .product(name: "ConsoleKit", package: "console-kit"),
            .target(name: "MadMachine")
        ]),
        .testTarget(name: "MadMachineTests", dependencies: ["MadMachine"]),
    ]
)
