// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Fiber",
    products: [
        .library(name: "Fiber", targets: ["Fiber"]),
        .library(name: "AsyncFiber", targets: ["AsyncFiber"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-stack/platform.git",
            from: "0.4.0"
        ),
        .package(
            url: "https://github.com/swift-stack/async.git",
            from: "0.4.0"
        ),
        .package(
            url: "https://github.com/swift-stack/log.git",
            from: "0.4.0"
        ),
        .package(
            url: "https://github.com/swift-stack/test.git",
            from: "0.4.0"
        )
    ],
    targets: [
        .target(name: "CCoro"),
        .target(name: "Fiber", dependencies: ["CCoro", "Async", "Log"]),
        .target(name: "AsyncFiber", dependencies: ["Fiber"]),
        .testTarget(name: "FiberTests", dependencies: ["Fiber", "Test"]),
        .testTarget(
            name: "AsyncFiberTests",
            dependencies: ["AsyncFiber", "Fiber", "Test"]
        )
    ]
)

#if os(Linux)
package.targets.append(.target(name: "CEpoll"))
package.targets[1].dependencies.append("CEpoll")
#endif
