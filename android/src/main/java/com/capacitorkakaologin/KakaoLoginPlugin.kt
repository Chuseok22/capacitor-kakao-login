package com.capacitorkakaologin

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.kakao.sdk.auth.model.OAuthToken
import com.kakao.sdk.common.KakaoSdk
import com.kakao.sdk.user.UserApiClient

// name 값은 TypeScript registerPlugin('KakaoLogin', ...) 과 반드시 일치해야 한다
@CapacitorPlugin(name = "KakaoLogin")
class KakaoLoginPlugin : Plugin() {

    /**
     * 플러그인 로드 시 KakaoSDK를 자동 초기화한다.
     * capacitor.config.ts의 plugins.KakaoLogin.appKey 값을 읽는다.
     * Application 서브클래스를 별도로 만들 필요가 없다.
     */
    override fun load() {
        val appKey = config.getString("appKey")
        if (appKey.isNullOrBlank()) {
            println("[KakaoLoginPlugin] ⚠️ appKey가 capacitor.config.ts에 설정되지 않았습니다.")
            println("[KakaoLoginPlugin]   plugins: { KakaoLogin: { appKey: 'YOUR_NATIVE_APP_KEY' } }")
            return
        }

        // Application context 사용 — KakaoSdk.init은 앱 수명 동안 유지되어야 하므로
        KakaoSdk.init(context, appKey)
    }

    @PluginMethod
    fun login(call: PluginCall) {
        val activity = activity ?: run {
            call.reject("Activity를 사용할 수 없습니다")
            return
        }

        // OAuthToken 콜백 — 앱/계정 로그인 공통 처리
        val callback: (OAuthToken?, Throwable?) -> Unit = callback@{ _, error ->
            if (error != null) {
                call.reject("카카오 로그인 실패: ${error.message}")
                return@callback
            }

            UserApiClient.instance.me { user, meError ->
                if (meError != null) {
                    call.reject("사용자 정보 조회 실패: ${meError.message}")
                    return@me
                }

                val userId = user?.id
                if (userId == null) {
                    call.reject("카카오 사용자 ID를 가져올 수 없습니다")
                    return@me
                }

                val result = JSObject()
                result.put("socialId", userId.toString())
                call.resolve(result)
            }
        }

        if (UserApiClient.instance.isKakaoTalkLoginAvailable(activity)) {
            // 카카오톡 앱 설치 시 앱 로그인 우선 시도
            UserApiClient.instance.loginWithKakaoTalk(activity, callback = callback)
        } else {
            // 카카오톡 미설치 시 카카오 계정 웹뷰 로그인으로 폴백
            UserApiClient.instance.loginWithKakaoAccount(activity, callback = callback)
        }
    }
}
