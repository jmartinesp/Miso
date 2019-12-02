// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Miso",
    products: [
        .library(name: "Miso", targets: ["Miso"])
    ],
    dependencies: [
        .package(url: "https://github.com/envoy/Ambassador.git", from: "4.0.5"),
	.package(url: "https://github.com/envoy/Embassy.git", .revision("a163f1ef5609a960a90d73e4c3438f8a15a61eab")),
    ],
    targets: [
        .target(name: "Miso",  dependencies: [], path: "Miso"),
	.testTarget(name: "MisoTests", dependencies: ["Miso", "Ambassador", "Embassy"], path: "MisoTests"),
//        .target(name: "Miso-MacOS", dependencies: [], path: "Miso-MacOS")
    ]
)
