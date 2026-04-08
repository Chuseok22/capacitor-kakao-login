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
        // Capacitor 8: CAPPlugin에 handleOpenUrl 오버라이드 불가 — NotificationCenter로 URL 수신
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenURL(_:)),
            name: .capacitorOpenURL,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Capacitor 8 URL 라우팅: AppDelegate → ApplicationDelegateProxy → capacitorOpenURL 알림
    // notification.object = ["url": URL, "options": [UIApplication.OpenURLOptionsKey: Any]]
    @objc private func handleOpenURL(_ notification: Notification) {
        guard let object = notification.object as? [String: Any],
              let url = object["url"] as? URL else { return }
        guard AuthApi.isKakaoTalkLoginUrl(url) else { return }
        // capacitorOpenURL은 메인 스레드에서 발송 — MainActor.assumeIsolated 안전
        MainActor.assumeIsolated {
            _ = AuthController.handleOpenUrl(url: url)
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
