// swift-tools-version:5.10
// raxha-platform — Phase 0 (pure core + replay harness + CI), per Roadmap 14 Part A/B.
// Layout follows implementation/README exactly: core/ harness/ shared/ (mobile/ backend/ arrive
// in their own phases). Tools-version 5.10 keeps language mode 5 while building under Swift 6.x.
import PackageDescription

let package = Package(
    name: "raxha-platform",
    targets: [
        // RaxhaCore — PURE (zero platform imports; ADR-011). Foundation only for value types
        // (UUID storage, Codable); time, randomness, and ID generation enter through ports.
        .target(
            name: "RaxhaCore",
            path: "core"
        ),
        // Replay harness + VV-101/VV-110 rigs (Phase 0's exit gate lives here).
        .executableTarget(
            name: "raxha-harness",
            dependencies: ["RaxhaCore"],
            path: "harness/Sources"
        ),
        .testTarget(
            name: "RaxhaCoreTests",
            dependencies: ["RaxhaCore"],
            path: "tests/RaxhaCoreTests"
        ),
    ]
)
