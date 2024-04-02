// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "async-http-client-by-example-sample",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0")
    ],
    targets: [
        .executableTarget(
            name: "async-http-client-by-example-sample",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
    ]
)
