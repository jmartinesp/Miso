// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Miso",
    products: [
        .library(name: "Miso", targets: ["Miso"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.1")
    ],
    targets: [
        .target(name: "Miso",  dependencies: ["AsyncHTTPClient"], path: "Miso"),
        .testTarget(name: "MisoTests", dependencies: ["Miso"], path: "MisoTests"),
//        .target(name: "Miso-MacOS", dependencies: [], path: "Miso-MacOS")
    ]
)
