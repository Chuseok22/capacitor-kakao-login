import Foundation
import Capacitor
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

/// Capacitor 플러그인 — 카카오 소셜 로그인
///
/// capacitor.config.ts에 appKey를 설정하면 load() 시점에 KakaoSDK를 자동 초기화하고,
/// ApplicationDelegateProxy에 등록해 URL 처리도 자동으로 수행한다.
/// AppDelegate를 수정할 필요가 없다.
@objc(KakaoLoginPlugin)
public class KakaoLoginPlugin: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "KakaoLoginPlugin"
    public let jsName = "KakaoLogin"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "login", returnType: CAPPluginReturnPromise)
    ]

    /// 플러그인 로드 시 KakaoSDK를 자동 초기화한다.
    /// capacitor.config.ts의 plugins.KakaoLogin.appKey 값을 읽는다.
    public override func load() {
        guard let appKey = getConfigValue("appKey") as? String, !appKey.isEmpty else {
            print("[KakaoLoginPlugin] ⚠️ appKey가 capacitor.config.ts에 설정되지 않았습니다.")
            print("[KakaoLoginPlugin]   plugins: { KakaoLogin: { appKey: 'YOUR_NATIVE_APP_KEY' } }")
            return
        }

        KakaoSDK.initSDK(appKey: appKey)

        // Capacitor AppDelegate는 이미 ApplicationDelegateProxy.shared를 통해 URL을 라우팅한다.
        // 여기에 self를 등록해두면 AppDelegate 수정 없이 URL 콜백을 처리할 수 있다.
        ApplicationDelegateProxy.shared.add(self)
    }

    /// ApplicationDelegateProxy가 호출하는 URL 핸들러.
    /// 카카오톡 앱 로그인 후 앱으로 돌아오는 URL을 처리한다.
    @objc public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        return false
    }

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
