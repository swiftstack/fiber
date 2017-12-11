// swift-tools-version:4.0
/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import PackageDescription

let package = Package(
    name: "Fiber",
    products: [
        .library(name: "Fiber", targets: ["Fiber"]),
        .library(name: "AsyncFiber", targets: ["AsyncFiber"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/tris-foundation/platform.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/linked-list.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/async.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/log.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/test.git",
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
