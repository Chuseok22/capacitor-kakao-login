# capacitor-kakao-auth 개발 계획

Capacitor 앱에서 카카오 소셜 로그인을 npm 패키지 하나로 쉽게 쓸 수 있도록 만드는 플러그인.
이 문서는 실제 문제를 겪은 디버깅 경험을 기반으로 작성되었다.

---

## 왜 이 패키지가 필요한가

### 실제로 겪은 문제

Capacitor 앱에 카카오 로그인을 붙이면서 아래 에러가 발생했다.

```
Error: "KakaoAuth" plugin is not implemented on ios
```

Xcode에서 `KakaoAuthPlugin.swift`를 빌드 타겟에 추가하고, 클린 빌드까지 해도 에러가 사라지지 않았다.

### 진짜 원인

`npx cap sync` 실행 시 Capacitor CLI(`@capacitor/cli`)가 `ios/App/App/capacitor.config.json`의 `packageClassList`를 **완전히 교체**한다.

```javascript
// @capacitor/cli/dist/util/iosplugin.js:53
capJSON['packageClassList'] = classList;  // merge가 아닌 교체
```

Capacitor의 iOS 플러그인 로딩 흐름:

```
npx cap sync
  → node_modules의 npm 패키지 중 capacitor 플러그인만 스캔
  → Swift 파일에서 @objc(ClassName) 패턴 추출
  → packageClassList 배열 생성 후 capacitor.config.json에 덮어씀

앱 실행
  → Capacitor가 packageClassList를 읽음
  → NSClassFromString("ClassName")으로 클래스 로드
  → JS bridge 연결
```

**로컬 Swift 파일은 npm 패키지가 아니므로 스캔 대상에 포함되지 않는다.**
따라서 `packageClassList`에 올라가지 않고, JS에서 `login()` 호출 시 `UNIMPLEMENTED` 에러가 발생한다.

### npm 패키지로 만들면 해결되는 이유

Capacitor CLI는 `node_modules/`에 있는 패키지 중 `package.json`에 `capacitor.ios.src` 필드가 있는 것을 플러그인으로 인식한다.
인식된 패키지의 Swift 소스를 스캔해서 `@objc(ClassName)` 클래스를 자동으로 `packageClassList`에 추가한다.

즉, 올바른 구조의 npm 패키지를 `npm install`하면 `npx cap sync`만으로 모든 설정이 자동화된다.

---

## 패키지 구조

Capacitor 공식 플러그인 구조를 따른다.

```
capacitor-kakao-auth/
├── package.json
├── tsconfig.json
├── rollup.config.js         # 또는 vite.config.ts
├── src/
│   ├── index.ts             # registerPlugin + re-export
│   ├── definitions.ts       # TypeScript 인터페이스
│   └── web.ts               # Web fallback (선택, 보통 미지원)
├── ios/
│   └── Sources/
│       └── KakaoAuthPlugin/
│           └── KakaoAuthPlugin.swift
├── android/
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml
│           └── java/
│               └── com/
│                   └── kakaoauth/
│                       └── KakaoAuthPlugin.kt
└── dist/
    └── (빌드 산출물)
```

---

## package.json 핵심 설정

```json
{
  "name": "capacitor-kakao-auth",
  "version": "1.0.0",
  "description": "Capacitor plugin for Kakao social login (iOS & Android)",
  "main": "dist/plugin.cjs.js",
  "module": "dist/plugin.esm.js",
  "types": "dist/definitions.d.ts",
  "files": [
    "dist/",
    "ios/",
    "android/",
    "CapacitorKakaoAuth.podspec"
  ],
  "keywords": ["capacitor", "plugin", "kakao", "social-login", "ios", "android"],
  "capacitor": {
    "ios": {
      "src": "ios"
    },
    "android": {
      "src": "android"
    }
  },
  "peerDependencies": {
    "@capacitor/core": ">=5.0.0"
  }
}
```

`capacitor.ios.src` 필드가 있어야 Capacitor CLI가 이 패키지를 플러그인으로 인식한다.

---

## TypeScript 인터페이스 (`src/definitions.ts`)

```typescript
export interface KakaoAuthPlugin {
  /**
   * 카카오 로그인을 실행하고 사용자 고유 ID를 반환한다.
   * 카카오톡 앱이 설치된 경우 앱 로그인, 미설치 시 웹뷰 로그인을 시도한다.
   */
  login(): Promise<KakaoLoginResult>;
}

export interface KakaoLoginResult {
  /** 카카오 회원 고유 ID (서버에 전달할 socialId) */
  socialId: string;
}
```

## 플러그인 등록 (`src/index.ts`)

```typescript
import { registerPlugin } from '@capacitor/core';
import type { KakaoAuthPlugin } from './definitions';

const KakaoAuth = registerPlugin<KakaoAuthPlugin>('KakaoAuth', {
  web: () => import('./web').then(m => new m.KakaoAuthWeb()),
});

export * from './definitions';
export { KakaoAuth };
```

---

## iOS 구현 (`ios/Sources/KakaoAuthPlugin/KakaoAuthPlugin.swift`)

기존 Waitee 앱의 구현을 그대로 이식한다.

```swift
import Foundation
import Capacitor
import KakaoSDKAuth
import KakaoSDKUser

@objc(KakaoAuthPlugin)
public class KakaoAuthPlugin: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "KakaoAuthPlugin"
    public let jsName = "KakaoAuth"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "login", returnType: CAPPluginReturnPromise)
    ]

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

    private func handleLoginResult(call: CAPPluginCall, oauthToken: OAuthToken?, error: Error?) {
        if let error = error {
            call.reject("카카오 로그인 실패", nil, error)
            return
        }

        UserApi.shared.me { user, error in
            DispatchQueue.main.async {
                if let error = error {
                    call.reject("카카오 사용자 정보 조회 실패", nil, error)
                    return
                }

                guard let userId = user?.id else {
                    call.reject("카카오 사용자 ID가 없습니다")
                    return
                }

                call.resolve(["socialId": String(userId)])
            }
        }
    }
}
```

### iOS KakaoSDK 의존성 처리

npm 패키지는 CocoaPods 또는 Swift Package Manager 방식으로 KakaoSDK 의존성을 선언할 수 있다.

**방법 1: Package.swift (SPM)** — Capacitor 8 이상 권장

```swift
// ios/Package.swift
let package = Package(
    name: "KakaoAuthPlugin",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "KakaoAuthPlugin",
            targets: ["KakaoAuthPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "KakaoAuthPlugin",
            dependencies: [
                .product(name: "KakaoSDKAuth", package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKUser", package: "kakao-ios-sdk"),
            ],
            path: "Sources/KakaoAuthPlugin"
        )
    ]
)
```

**방법 2: Podspec** — 하위 호환 필요 시

```ruby
# CapacitorKakaoAuth.podspec
Pod::Spec.new do |s|
  s.name         = 'CapacitorKakaoAuth'
  s.version      = '1.0.0'
  s.summary      = 'Capacitor plugin for Kakao social login'
  s.homepage     = 'https://github.com/your-repo/capacitor-kakao-auth'
  s.license      = 'MIT'
  s.author       = { 'Author' => 'email@example.com' }
  s.source       = { :git => 'https://github.com/your-repo/capacitor-kakao-auth.git', :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.swift'
  s.ios.deployment_target = '13.0'
  s.dependency 'KakaoSDKAuth', '~> 2.0'
  s.dependency 'KakaoSDKUser', '~> 2.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
end
```

### 앱 측에서 해야 하는 iOS 설정

플러그인 사용자는 아래 설정을 직접 해야 한다 (README에 명시 필요).

1. `AppDelegate.swift`에 Kakao SDK 초기화 추가:
   ```swift
   import KakaoSDKCommon

   KakaoSDK.initSDK(appKey: "YOUR_NATIVE_APP_KEY")
   ```

2. `AppDelegate`에 URL 핸들러 추가:
   ```swift
   import KakaoSDKAuth

   func application(_ app: UIApplication, open url: URL, options: ...) -> Bool {
       if AuthApi.isKakaoTalkLoginUrl(url) {
           return AuthController.handleOpenUrl(url: url)
       }
       return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
   }
   ```

3. `Info.plist`에 카카오톡 URL Scheme 추가:
   ```xml
   <key>LSApplicationQueriesSchemes</key>
   <array>
     <string>kakaokompassauth</string>
     <string>storykompassauth</string>
     <string>kakaolink</string>
   </array>
   ```

4. `Info.plist`에 앱 URL Scheme 등록:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>kakao{NATIVE_APP_KEY}</string>
       </array>
     </dict>
   </array>
   ```

---

## Android 구현 (`android/src/main/java/com/kakaoauth/KakaoAuthPlugin.kt`)

```kotlin
package com.kakaoauth

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.kakao.sdk.auth.model.OAuthToken
import com.kakao.sdk.user.UserApiClient

@CapacitorPlugin(name = "KakaoAuth")
class KakaoAuthPlugin : Plugin() {

    @PluginMethod
    fun login(call: PluginCall) {
        val context = context

        val callback: (OAuthToken?, Throwable?) -> Unit = { token, error ->
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
                    call.reject("카카오 사용자 ID가 없습니다")
                    return@me
                }

                val result = JSObject()
                result.put("socialId", userId.toString())
                call.resolve(result)
            }
        }

        if (UserApiClient.instance.isKakaoTalkLoginAvailable(context)) {
            UserApiClient.instance.loginWithKakaoTalk(context, callback = callback)
        } else {
            UserApiClient.instance.loginWithKakaoAccount(context, callback = callback)
        }
    }
}
```

### 앱 측에서 해야 하는 Android 설정

1. `Application` 클래스에 Kakao SDK 초기화:
   ```kotlin
   import com.kakao.sdk.common.KakaoSdk

   KakaoSdk.init(this, "YOUR_NATIVE_APP_KEY")
   ```

2. `AndroidManifest.xml`에 KakaoLoginActivity 추가:
   ```xml
   <activity android:name="com.kakao.sdk.auth.AuthCodeHandlerActivity"
       android:exported="true">
     <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:host="oauth"
             android:scheme="kakao{NATIVE_APP_KEY}" />
     </intent-filter>
   </activity>
   ```

---

## 플러그인 사용 방법 (최종 사용자 경험)

패키지 완성 후 사용자는 아래 단계만 수행하면 된다.

```bash
npm install capacitor-kakao-auth
npx cap sync
```

```typescript
import { KakaoAuth } from 'capacitor-kakao-auth';

const { socialId } = await KakaoAuth.login();
```

---

## 개발 로드맵

### Phase 1: 기본 구조
- [ ] `@capacitor/create-plugin` 또는 수동으로 플러그인 보일러플레이트 생성
- [ ] TypeScript 정의 작성 (`definitions.ts`, `index.ts`)
- [ ] iOS Swift 구현 이식 (`KakaoAuthPlugin.swift`)
- [ ] Android Kotlin 구현 (`KakaoAuthPlugin.kt`)
- [ ] 로컬 앱에서 `npm install file:../capacitor-kakao-auth`로 동작 검증

### Phase 2: iOS KakaoSDK 의존성
- [ ] `Package.swift` 작성 (SPM 방식)
- [ ] `Podspec` 작성 (CocoaPods 방식)
- [ ] Capacitor 8 프로젝트에서 SPM 방식 통합 테스트

### Phase 3: Android KakaoSDK 의존성
- [ ] `build.gradle`에 Kakao Android SDK 의존성 추가
- [ ] Android 통합 테스트

### Phase 4: 배포
- [ ] `npm publish` (또는 GitHub Packages)
- [ ] README 작성: 설치법, iOS/Android 앱 설정, 사용 예시
- [ ] `capacitor-community` 기여 검토

---

## 참고 자료

- Capacitor 공식 플러그인 생성 가이드: https://capacitorjs.com/docs/plugins/creating-plugins
- Kakao iOS SDK SPM: https://github.com/kakao/kakao-ios-sdk
- Kakao Android SDK: https://developers.kakao.com/docs/latest/ko/getting-started/sdk-android
- Capacitor CLI `iosplugin.js` 소스: `node_modules/@capacitor/cli/dist/util/iosplugin.js`
  - 53번째 줄: `capJSON['packageClassList'] = classList` → 완전 교체 (merge 아님)
  - `findPluginClasses`: `@objc(ClassName)` 패턴으로 Swift 파일 스캔
  - `getPluginFiles`: npm 패키지 타입 Core(`PluginType.Core`)만 스캔 대상

---

## 디버깅 과정에서 얻은 핵심 인사이트

1. **`packageClassList`는 merge가 아닌 완전 교체** — `capacitor.config.ts`에 직접 써도 sync 시 사라짐
2. **로컬 Swift 플러그인은 자동 탐색 불가** — npm 패키지 구조를 따라야만 CLI가 인식
3. **`@objc(ClassName)` 어노테이션이 탐색 키** — CLI가 이 패턴으로 클래스명 추출
4. **`CAPBridgedPlugin` 프로토콜 구현 필수** — `identifier`, `jsName`, `pluginMethods` 모두 필요
5. **임시 해결책**: `CAPBridgeViewController` 서브클래스에서 `bridge?.registerPluginInstance(KakaoAuthPlugin())` 호출
