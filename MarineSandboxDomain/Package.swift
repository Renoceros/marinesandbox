// swift-tools-version: 5.9
//
// Sidecar test package for the Marine Sandbox domain layer (DEC-022).
//
// `Sources/Domain` is a symlink to `../marinesandbox/Domain`, so the app target
// (via Xcode's file-system synchronized groups) and this package compile the
// exact same files. No `project.pbxproj` changes are required — that file is
// the most conflict-prone artifact in a 5-person sprint, and it stays untouched.

import PackageDescription

let package = Package(
    name: "MarineSandboxDomain",
    products: [
        .library(name: "MarineSandboxDomain", targets: ["Domain"])
    ],
    targets: [
        .target(
            name: "Domain",
            path: "Sources/Domain"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            path: "Tests/DomainTests"
        )
    ]
)
