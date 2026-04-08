# @chuseok22/capacitor-kakao-login

Capacitor 앱에서 카카오 소셜 로그인을 `npm install` + `npx cap sync` 만으로 사용할 수 있는 플러그인입니다.

- iOS / Android 모두 지원
- 카카오톡 앱 로그인 우선, 미설치 시 카카오 계정 웹뷰 로그인으로 자동 폴백
- Capacitor 6.x 이상 지원

---

## 목차

1. [사전 요구사항](#1-사전-요구사항)
2. [카카오 개발자 콘솔 설정](#2-카카오-개발자-콘솔-설정)
3. [설치](#3-설치)
4. [iOS 설정](#4-ios-설정)
5. [Android 설정](#5-android-설정)
6. [사용법](#6-사용법)
7. [API](#7-api)
8. [지원 플랫폼](#8-지원-플랫폼)
9. [트러블슈팅](#9-트러블슈팅)

---

## 1. 사전 요구사항

| 항목 | 최소 버전 |
|------|-----------|
| Capacitor | 6.x 이상 |
| iOS | 13.0 이상 |
| Android | API 22 (Android 5.1) 이상 |
| Node.js | 18.x 이상 |

---

## 2. 카카오 개발자 콘솔 설정

플러그인을 사용하기 전에 [카카오 개발자 콘솔](https://developers.kakao.com)에서 앱을 등록해야 합니다.

### 2-1. 앱 등록 및 네이티브 앱 키 발급

1. [카카오 개발자 콘솔](https://developers.kakao.com) → **내 애플리케이션** → **애플리케이션 추가하기**
2. 앱 이름, 회사명 입력 후 저장
3. 생성된 앱의 **앱 키** 탭에서 **네이티브 앱 키** 복사

### 2-2. 플랫폼 등록

**iOS 플랫폼 추가:**

1. 앱 설정 → **플랫폼** → **iOS 플랫폼 등록**
2. **번들 ID** 입력 (예: `com.example.myapp`) — Xcode 프로젝트의 Bundle Identifier와 동일해야 합니다

**Android 플랫폼 추가:**

1. 앱 설정 → **플랫폼** → **Android 플랫폼 등록**
2. **패키지명** 입력 (예: `com.example.myapp`) — `AndroidManifest.xml`의 패키지명과 동일해야 합니다
3. **키 해시** 등록 (개발용 / 릴리즈용 각각 등록 필요)

> **키 해시 추출 방법:**
>
> ```bash
> # macOS — 디버그 키스토어 (개발용)
> keytool -exportcert -alias androiddebugkey \
>   -keystore ~/.android/debug.keystore \
>   -storepass android -keypass android \
>   | openssl sha1 -binary | openssl base64
> ```
>
> 릴리즈 키스토어는 `-keystore` 경로와 `-alias`, `-storepass`, `-keypass`를 실제 값으로 교체하세요.

### 2-3. 카카오 로그인 활성화

앱 설정 → **카카오 로그인** → **활성화 설정** → **ON**

---

## 3. 설치

```bash
npm install @chuseok22/capacitor-kakao-login
npx cap sync
```

---

## 4. iOS 설정

### 4-1. KakaoSDK 초기화

`AppDelegate.swift`에서 앱 시작 시 KakaoSDK를 초기화합니다.

```swift
import KakaoSDKCommon

func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    KakaoSDK.initSDK(appKey: "YOUR_NATIVE_APP_KEY")
    return true
}
```

`YOUR_NATIVE_APP_KEY`를 [2-1](#2-1-앱-등록-및-네이티브-앱-키-발급)에서 발급받은 네이티브 앱 키로 교체하세요.

### 4-2. URL 핸들러 등록

카카오톡 앱 로그인 후 앱으로 돌아오기 위한 URL 핸들러를 등록합니다.

**AppDelegate 방식 (SceneDelegate 미사용):**

`AppDelegate.swift`에 아래 메서드를 추가합니다.

```swift
import KakaoSDKAuth

func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
) -> Bool {
    if AuthApi.isKakaoTalkLoginUrl(url) {
        return AuthController.handleOpenUrl(url: url)
    }
    return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
}
```

**SceneDelegate 방식 (SceneDelegate 사용 시):**

`SceneDelegate.swift`에 아래 메서드를 추가합니다.

```swift
import KakaoSDKAuth

func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
) {
    if let url = URLContexts.first?.url {
        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
        }
    }
}
```

### 4-3. `Info.plist` 설정

Xcode에서 `Info.plist`를 열고 아래 항목을 추가합니다.

```xml
<!-- 카카오톡 앱 URL 스킴 쿼리 허용 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>storykompassauth</string>
  <string>kakaolink</string>
</array>

<!-- 앱의 커스텀 URL 스킴 등록 (kakao + 네이티브 앱 키) -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>kakaoYOUR_NATIVE_APP_KEY</string>
    </array>
  </dict>
</array>
```

`YOUR_NATIVE_APP_KEY`를 실제 네이티브 앱 키로 교체하세요. 예: 네이티브 앱 키가 `abc123` 이면 `kakaoabc123`.

---

## 5. Android 설정

### 5-1. Kotlin Gradle 플러그인 classpath 추가

`android/build.gradle`의 `buildscript` 블록에 Kotlin 플러그인 의존성을 추가합니다.

```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 이미 있는 항목은 그대로 두고 아래 줄만 추가
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.21'
    }
}
```

> 이 단계가 없으면 `cap sync` 후 Gradle sync 오류가 발생합니다.

### 5-2. KakaoSDK 초기화

`Application` 서브클래스를 생성하고 KakaoSDK를 초기화합니다.

```kotlin
import android.app.Application
import com.kakao.sdk.common.KakaoSdk

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        KakaoSdk.init(this, "YOUR_NATIVE_APP_KEY")
    }
}
```

`YOUR_NATIVE_APP_KEY`를 [2-1](#2-1-앱-등록-및-네이티브-앱-키-발급)에서 발급받은 네이티브 앱 키로 교체하세요.

`AndroidManifest.xml`에 Application 클래스를 등록합니다.

```xml
<application
    android:name=".MyApplication"
    ...>
```

### 5-3. 카카오 로그인 Activity 등록

카카오 계정 웹뷰 로그인 후 앱으로 돌아오기 위한 Activity를 `AndroidManifest.xml`에 등록합니다.

```xml
<activity
    android:name="com.kakao.sdk.auth.AuthCodeHandlerActivity"
    android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:host="oauth"
        android:scheme="kakaoYOUR_NATIVE_APP_KEY" />
  </intent-filter>
</activity>
```

`YOUR_NATIVE_APP_KEY`를 실제 네이티브 앱 키로 교체하세요. 예: `kakaoabc123`.

---

## 6. 사용법

### 기본 예제

```typescript
import { KakaoLogin } from '@chuseok22/capacitor-kakao-login';

async function loginWithKakao() {
  try {
    const { socialId } = await KakaoLogin.login();
    console.log('카카오 사용자 ID:', socialId);
    // socialId를 서버에 전달해 사용자 인증 처리
  } catch (error) {
    console.error('카카오 로그인 실패:', error);
  }
}
```

### React / React Native-like 예제

```typescript
import { KakaoLogin } from '@chuseok22/capacitor-kakao-login';

const handleKakaoLogin = async () => {
  try {
    const result = await KakaoLogin.login();
    // result.socialId: 카카오 회원 고유 ID (string)
    await sendToServer(result.socialId);
  } catch (error: unknown) {
    if (error instanceof Error) {
      alert(`로그인 실패: ${error.message}`);
    }
  }
};
```

### Ionic / Angular 예제

```typescript
import { Component } from '@angular/core';
import { KakaoLogin } from '@chuseok22/capacitor-kakao-login';

@Component({ ... })
export class LoginPage {
  async loginWithKakao() {
    try {
      const { socialId } = await KakaoLogin.login();
      // 서버 인증 로직
    } catch (error) {
      console.error(error);
    }
  }
}
```

---

## 7. API

### `KakaoLogin.login()`

카카오 로그인을 실행합니다.

```typescript
login(): Promise<KakaoLoginResult>
```

**동작:**
- 카카오톡 앱이 설치된 경우 → 카카오톡 앱 로그인
- 카카오톡 미설치 시 → 카카오 계정 웹뷰 로그인으로 자동 폴백

**반환값:**

```typescript
interface KakaoLoginResult {
  /** 카카오 회원 고유 ID. 서버에서 사용자를 식별하는 데 사용합니다. */
  socialId: string;
}
```

**에러:**

| 에러 메시지 | 원인 |
|------------|------|
| `카카오 로그인 실패: ...` | 사용자가 로그인을 취소하거나 카카오 인증 오류 발생 |
| `사용자 정보 조회 실패: ...` | 로그인 성공 후 카카오 API에서 사용자 정보 가져오기 실패 |
| `카카오 사용자 ID를 가져올 수 없습니다` | 카카오 API 응답에 사용자 ID가 없는 경우 |

---

## 8. 지원 플랫폼

| 플랫폼 | 지원 여부 | 최소 버전 |
|--------|-----------|-----------|
| iOS | ✅ 지원 | iOS 13.0+ |
| Android | ✅ 지원 | API 22 (Android 5.1)+ |
| Web | ❌ 미지원 | — |

---

## 9. 트러블슈팅

### iOS

**`cap sync` 시 `[warn] ... does not have a Package.swift` 경고**

- 플러그인 루트에 `Package.swift`가 포함된 버전(`0.1.5` 이상)을 사용하세요.
- `package.json`의 `@chuseok22/capacitor-kakao-login` 버전을 확인하고 `npm update`로 업데이트하세요.

**카카오톡 앱 로그인 후 앱으로 돌아오지 않는 경우**

- `Info.plist`의 `CFBundleURLSchemes`에 `kakao{네이티브앱키}` 형식으로 등록되었는지 확인하세요.
- `AppDelegate.swift` 또는 `SceneDelegate.swift`에 URL 핸들러가 올바르게 추가되었는지 확인하세요.

**`UNIMPLEMENTED` 에러**

- `npx cap sync`를 다시 실행하세요.
- Xcode에서 **Product → Clean Build Folder** 후 재빌드하세요.

---

### Android

**`Gradle sync` 오류 (`Unresolved reference: kotlin` 등)**

- `android/build.gradle`의 `buildscript.dependencies`에 `classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.21'`이 추가되어 있는지 확인하세요. ([5-1 참고](#5-1-kotlin-gradle-플러그인-classpath-추가))

**`KakaoSdk.init()` 호출 전 로그인 시도 오류**

- `Application` 서브클래스에서 `KakaoSdk.init()`을 올바르게 호출하고 `AndroidManifest.xml`에 `android:name=".MyApplication"`이 등록되어 있는지 확인하세요.

**카카오 개발자 콘솔에서 키 해시 불일치 오류**

- 디버그 빌드와 릴리즈 빌드의 키 해시를 각각 등록해야 합니다.
- 실제 기기에서 테스트할 때는 서명된 APK의 키 해시가 필요할 수 있습니다.

---

## License

MIT
