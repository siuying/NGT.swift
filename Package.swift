// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NGT",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NGT",
            targets: ["NGT"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NGT",
            dependencies: ["CNGT"]
        ),
        .target(
            name: "CNGT",
            dependencies: [],
            cSettings: [
                .headerSearchPath("../../vendor/openmp/include"),
                .headerSearchPath("lib"),
                .headerSearchPath("extra_include"),
                .unsafeFlags(["-DNGT_QBG_DISABLED=1"]) // disable NGT with Quantization
            ],
            cxxSettings: [
                .headerSearchPath("../../vendor/openmp/include"),
                .headerSearchPath("lib"),
                .headerSearchPath("extra_include"),
                .unsafeFlags(["-DNGT_QBG_DISABLED=1"]) // disable NGT with Quantization
            ],
            linkerSettings: [
                .unsafeFlags(["-Lvendor/openmp/lib", "-lomp"], .when(platforms: [.macOS], configuration: .release)),
                .linkedFramework("Accelerate")
            ]
        ),
        .testTarget(
            name: "NGTTests",
            dependencies: ["NGT"]),
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx11
)
