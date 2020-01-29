// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Motion",
    platforms: [.iOS(.v11), .tvOS(.v11)],
    products: [
        .library(name: "Motion", targets: ["Motion"])
    ],
    targets: [
        .target(
            name: "Motion",
            path: "Sources"
        )
    ]
)
