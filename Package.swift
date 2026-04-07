// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KakaoLoginPlugin",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "KakaoLoginPlugin",
            targets: ["KakaoLoginPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.23.0"),
    ],
    targets: [
        .target(
            name: "KakaoLoginPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "KakaoSDKAuth", package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKUser", package: "kakao-ios-sdk"),
            ],
            // 루트 기준 상대 경로 — ios/ 디렉토리 내 소스 위치
            path: "ios/Sources/KakaoLoginPlugin"
        )
    ]
)
