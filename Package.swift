// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Miso",
    products: [
        .library(name: "Miso", targets: ["Miso"])
    ],
    targets: [
        .target(name: "Miso",  dependencies: [], path: "Miso"),
//        .target(name: "Miso-MacOS", dependencies: [], path: "Miso-MacOS")
    ]
)
