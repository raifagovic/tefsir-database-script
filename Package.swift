// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TafsirDatabaseScript",
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1")
    ],
    targets: [
        .executableTarget(
            name: "TafsirDatabaseScript",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ]
        )
    ]
)
