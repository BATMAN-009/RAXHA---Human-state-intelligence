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
        // Replay harness + VV-101/VV-110 rigs, as a LIBRARY so the verifier itself is testable
        // (AUDIT-002: the gate must not live where no test can reach it).
        .target(
            name: "RaxhaHarnessKit",
            dependencies: ["RaxhaCore"],
            path: "harness/Sources"
        ),
        // The CLI is a thin shell over RaxhaHarnessKit — argument parsing + file I/O only.
        .executableTarget(
            name: "raxha-harness",
            dependencies: ["RaxhaCore", "RaxhaHarnessKit"],
            path: "harness/CLI"
        ),
        .testTarget(
            name: "RaxhaCoreTests",
            dependencies: ["RaxhaCore"],
            path: "tests/RaxhaCoreTests"
        ),
        // Adversarial tests that CHALLENGE the rigs: they assert the gate REJECTS bad input
        // (vacuous corpus, tampered baseline, corrupted objects), not merely that it passes.
        .testTarget(
            name: "HarnessTests",
            dependencies: ["RaxhaCore", "RaxhaHarnessKit"],
            path: "tests/HarnessTests"
        ),
    ]
)
