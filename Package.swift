// swift-tools-version: 5.9
import PackageDescription

// Capacitor CLI는 npm 패키지명(@chuseok22/capacitor-kakao-login)을 PascalCase로 변환해
// SPM product 이름을 자동 파생합니다: Chuseok22CapacitorKakaoLogin
// 이 package/product/target 이름은 Capacitor CLI 변환 규칙과 반드시 일치해야 합니다.
let package = Package(
    name: "Chuseok22CapacitorKakaoLogin",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Chuseok22CapacitorKakaoLogin",
            targets: ["Chuseok22CapacitorKakaoLogin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.23.0"),
    ],
    targets: [
        .target(
            name: "Chuseok22CapacitorKakaoLogin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "KakaoSDKAuth", package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKUser", package: "kakao-ios-sdk"),
            ],
            // 루트 기준 상대 경로
            path: "ios/Sources/Chuseok22CapacitorKakaoLogin"
        )
    ]
)
