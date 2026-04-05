import Foundation
import Capacitor
import KakaoSDKAuth
import KakaoSDKUser

/// Capacitor 플러그인 — 카카오 소셜 로그인
/// npx cap sync 시 @objc(KakaoLoginPlugin) 패턴으로 자동 탐색된다.
@objc(KakaoLoginPlugin)
public class KakaoLoginPlugin: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "KakaoLoginPlugin"
    public let jsName = "KakaoLogin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "login", returnType: CAPPluginReturnPromise)
    ]

    @objc func login(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if UserApi.isKakaoTalkLoginAvailable() {
                // 카카오톡 앱 로그인
                UserApi.shared.loginWithKakaoTalk { [weak self] oauthToken, error in
                    self?.handleLoginResult(call: call, oauthToken: oauthToken, error: error)
                }
            } else {
                // 카카오 계정 웹뷰 로그인 (카카오톡 미설치 환경)
                UserApi.shared.loginWithKakaoAccount { [weak self] oauthToken, error in
                    self?.handleLoginResult(call: call, oauthToken: oauthToken, error: error)
                }
            }
        }
    }

    private func handleLoginResult(call: CAPPluginCall, oauthToken _: OAuthToken?, error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                call.reject("카카오 로그인 실패", nil, error)
            }
            return
        }

        UserApi.shared.me { user, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("카카오 사용자 정보 조회 실패", nil, error)
                    return
                }

                guard let userId = user?.id else {
                    call.reject("카카오 사용자 ID를 가져올 수 없습니다")
                    return
                }

                call.resolve(["socialId": String(userId)])
            }
        }
    }
}
