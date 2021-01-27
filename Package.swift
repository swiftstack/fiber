// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "Fiber",
    products: [
        .library(
            name: "Fiber",
            targets: ["Fiber"])
    ],
    dependencies: [
        .package(name: "Platform"),
        .package(name: "Structures"),
        .package(name: "Time"),
        .package(name: "Log"),
        .package(name: "Test")
    ],
    targets: [
        .target(
            name: "CCoro"),
        .target(
            name: "Event",
            dependencies: [
                "Platform",
                "Time"
            ]),
        .target(
            name: "Fiber",
            dependencies: [
                "CCoro",
                "Platform",
                "Event",
                .product(name: "LinkedList", package: "Structures"),
                "Time",
                "Log"
            ]),
        .testTarget(
            name: "FiberTests",
            dependencies: ["Fiber", "Test"]),
    ]
)

#if os(Linux)
package.targets.append(.systemLibrary(name: "CEpoll", path: "./Headers/CEpoll"))
package.targets[1].dependencies.append("CEpoll")
#endif

// MARK: - custom package source

#if canImport(ObjectiveC)
import Darwin.C
#else
import Glibc
#endif

extension Package.Dependency {
    enum Source: String {
        case local, remote, github

        static var `default`: Self { .local }

        var baseUrl: String {
            switch self {
            case .local: return "../"
            case .remote: return "https://swiftstack.io/"
            case .github: return "https://github.com/swift-stack/"
            }
        }

        func url(for name: String) -> String {
            return self == .local
                ? baseUrl + name.lowercased()
                : baseUrl + name.lowercased() + ".git"
        }
    }

    static func package(name: String) -> Package.Dependency {
        guard let pointer = getenv("SWIFTSTACK") else {
            return .package(name: name, source: .default)
        }
        guard let source = Source(rawValue: String(cString: pointer)) else {
            fatalError("Invalid source. Use local, remote or github")
        }
        return .package(name: name, source: source)
    }

    static func package(name: String, source: Source) -> Package.Dependency {
        return source == .local
            ? .package(name: name, path: source.url(for: name))
            : .package(name: name, url: source.url(for: name), .branch("fiber"))
    }
}
