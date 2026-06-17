// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "Fiber",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "Fiber",
            targets: ["Fiber"]),
    ],
    dependencies: [
        .package(name: "Platform"),
        .package(name: "Event"),
        .package(name: "Structures"),
    ],
    targets: [
        .target(
            name: "CCoro"),
        .target(
            name: "Fiber",
            dependencies: [
                "CCoro",
                .product(name: "Platform", package: "Platform"),
                .product(name: "Event", package: "Event"),
                .product(name: "LinkedList", package: "Structures"),
            ],
            swiftSettings: [
                .treatWarning("EmbeddedRestrictions", as: .error)
            ]),
        .testTarget(
            name: "FiberTests",
            dependencies: ["Fiber"]),
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

        static var `default`: Self { .github }

        var baseUrl: String {
            switch self {
            case .local: return "../"
            case .remote: return "https://swiftstack.io/"
            case .github: return "https://github.com/swiftstack/"
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
            : .package(url: source.url(for: name), branch: "dev")
    }
}
