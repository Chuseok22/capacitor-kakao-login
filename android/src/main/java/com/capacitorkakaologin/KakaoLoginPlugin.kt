package com.capacitorkakaologin

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.kakao.sdk.auth.model.OAuthToken
import com.kakao.sdk.user.UserApiClient

// name 값은 TypeScript registerPlugin('KakaoLogin', ...) 과 반드시 일치해야 한다
@CapacitorPlugin(name = "KakaoLogin")
class KakaoLoginPlugin : Plugin() {

    @PluginMethod
    fun login(call: PluginCall) {
        val context = context

        // OAuthToken 콜백 — 앱/계정 로그인 공통 처리
        // token 파라미터는 의도적으로 미사용 (_) — socialId만 반환하므로 token 불필요
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

        if (UserApiClient.instance.isKakaoTalkLoginAvailable(context)) {
            // 카카오톡 앱 설치 시 앱 로그인 우선 시도
            UserApiClient.instance.loginWithKakaoTalk(context, callback = callback)
        } else {
            // 카카오톡 미설치 시 카카오 계정 웹뷰 로그인으로 폴백
            UserApiClient.instance.loginWithKakaoAccount(context, callback = callback)
        }
    }
}
