// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iamport-ios",
    platforms: [
            .macOS(.v10_12),
            .iOS(.v11),
        ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "iamport-ios",
            targets: ["iamport-ios"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.6.0")),
        .package(name: "RxBusForPort", url: "https://github.com/iamport/RxBus-Swift", .upToNextMinor(from: "1.3.0")),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.7.1")),
        .package(url: "https://github.com/devxoul/Then.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.50.4")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
            .target(name: "iamport-ios",
                    dependencies: ["RxSwift",
                                   "RxBusForPort",
                                   "Alamofire",
                                   "Then",
                                   .product(name: "RxCocoa",package: "RxSwift"),
                    ],
                    resources: [.process("Assets")],
                    swiftSettings: [
                        .define("IAMPORTSPM")
                    ]
            )
    ]
)
