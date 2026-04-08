import Foundation
import Capacitor
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

@objc(KakaoLoginPlugin)
public class KakaoLoginPlugin: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "KakaoLoginPlugin"
    public let jsName = "KakaoLogin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "login", returnType: CAPPluginReturnPromise)
    ]

    public override func load() {
        guard let appKey = getConfigValue("appKey") as? String, !appKey.isEmpty else {
            print("[KakaoLoginPlugin] ⚠️ appKey가 capacitor.config.ts에 설정되지 않았습니다.")
            print("[KakaoLoginPlugin]   plugins: { KakaoLogin: { appKey: 'YOUR_NATIVE_APP_KEY' } }")
            return
        }
        KakaoSDK.initSDK(appKey: appKey)
        // handleOpenUrl 오버라이드로 URL 처리 — ApplicationDelegateProxy.add() 불필요
    }

    // Capacitor가 AppDelegate.application(_:open:options:)를 플러그인으로 라우팅
    @objc public override func handleOpenUrl(_ url: URL, _ options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        guard AuthApi.isKakaoTalkLoginUrl(url) else { return false }
        // AuthController.handleOpenUrl은 @MainActor — URL 콜백은 메인 스레드 보장
        return MainActor.assumeIsolated {
            AuthController.handleOpenUrl(url: url)
        }
    }

    @objc func login(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { [weak self] oauthToken, error in
                    self?.handleLoginResult(call: call, oauthToken: oauthToken, error: error)
                }
            } else {
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
