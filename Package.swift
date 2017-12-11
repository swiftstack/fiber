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
            .branch("master")),
        .package(
            url: "https://github.com/swift-stack/linked-list.git",
            .branch("master")),
        .package(
            url: "https://github.com/swift-stack/async.git",
            .branch("master")),
        .package(
            url: "https://github.com/swift-stack/log.git",
            .branch("master")),
        .package(
            url: "https://github.com/swift-stack/test.git",
            .branch("master"))
    ],
    targets: [
        .target(name: "CCoro"),
        .target(
            name: "Fiber",
            dependencies: ["CCoro", "LinkedList", "Platform", "Async", "Log"]),
        .target(name: "AsyncFiber", dependencies: ["Fiber"]),
        .testTarget(name: "FiberTests", dependencies: ["Fiber", "Test"]),
        .testTarget(
            name: "AsyncFiberTests",
            dependencies: ["AsyncFiber", "Fiber", "Test"])
    ]
)

#if os(Linux)
package.targets.append(.target(name: "CEpoll"))
package.targets[1].dependencies.append("CEpoll")
#endif
