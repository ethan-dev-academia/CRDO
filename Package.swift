// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CRDO",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CRDO",
            targets: ["CRDO"]),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "CRDO",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ]),
        .testTarget(
            name: "CRDOTests",
            dependencies: ["CRDO"]),
    ]
) 