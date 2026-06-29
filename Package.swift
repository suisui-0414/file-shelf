// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "file-shelf",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FileShelf",
            path: "FileShelf",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "FileShelf.entitlements"
            ]
        )
    ]
)
