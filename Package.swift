// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Fiber",
    products: [
        .library(name: "Fiber", targets: ["Fiber"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/tris-code/platform.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-code/linked-list.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-code/async.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-code/time.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-code/log.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-code/test.git",
            .branch("master"))
    ],
    targets: [
        .target(name: "CCoro"),
        .target(
            name: "Fiber",
            dependencies: [
                "CCoro",
                "LinkedList",
                "Platform",
                "Async",
                "Time",
                "Log"
            ]),
        .testTarget(name: "FiberTests", dependencies: ["Fiber", "Test"]),
    ]
)

#if os(Linux)
package.targets.append(.target(name: "CEpoll"))
package.targets[1].dependencies.append("CEpoll")
#endif
