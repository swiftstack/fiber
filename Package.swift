import PackageDescription

let package = Package(
    name: "Fiber",
    targets: [
        Target(name: "Fiber", dependencies: ["CCoro"]),
        Target(name: "AsyncFiber", dependencies: ["Fiber"])
    ],
    dependencies: [
        .Package(url: "https://github.com/swift-stack/platform.git", majorVersion: 0),
        .Package(url: "https://github.com/swift-stack/async.git", majorVersion: 0),
        .Package(url: "https://github.com/swift-stack/log.git", majorVersion: 0),
    ]
)

#if os(Linux)
package.targets[0].dependencies.append("CEpoll")
#endif
