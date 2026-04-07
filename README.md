# @chuseok22/capacitor-kakao-login

Capacitor 앱에서 카카오 소셜 로그인을 `npm install` + `npx cap sync` 만으로 쉽게 사용할 수 있는 플러그인입니다. iOS와 Android 모두 지원합니다.

## 왜 이 패키지가 필요한가

`npx cap sync` 실행 시 Capacitor CLI는 `node_modules/` 내 npm 패키지만 플러그인으로 스캔합니다. 로컬 Swift 파일은 자동으로 `packageClassList`에 등록되지 않아 `UNIMPLEMENTED` 에러가 발생합니다. 이 패키지는 올바른 Capacitor 플러그인 구조를 갖추어 `npx cap sync`만으로 자동 등록되게 합니다.

## 설치

```bash
npm install @chuseok22/capacitor-kakao-login
npx cap sync
```

## 사용법

```typescript
import { KakaoLogin } from '@chuseok22/capacitor-kakao-login';

try {
  const { socialId } = await KakaoLogin.login();
  console.log('카카오 사용자 ID:', socialId);
} catch (error) {
  console.error('카카오 로그인 실패:', error);
}
```

## iOS 설정

### 1. KakaoSDK 초기화 (`AppDelegate.swift`)

```swift
import KakaoSDKCommon

func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    KakaoSDK.initSDK(appKey: "YOUR_NATIVE_APP_KEY")
    return true
}
```

### 2. URL 핸들러 등록 (`AppDelegate.swift`)

```swift
import KakaoSDKAuth

func application(_ app: UIApplication, open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if AuthApi.isKakaoTalkLoginUrl(url) {
        return AuthController.handleOpenUrl(url: url)
    }
    return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
}
```

### 3. `Info.plist` 설정

카카오톡 앱 연동 및 URL 스킴을 등록합니다.

```xml
<!-- 카카오톡 앱 링크 허용 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>storykompassauth</string>
  <string>kakaolink</string>
</array>

<!-- 앱 URL 스킴 등록 (kakao + 네이티브 앱 키) -->
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

`{NATIVE_APP_KEY}`를 [카카오 개발자 콘솔](https://developers.kakao.com)의 네이티브 앱 키로 교체하세요.

## Android 설정

### 0. Kotlin Gradle 플러그인 classpath 추가

`android/build.gradle`의 `buildscript` 블록에 Kotlin 플러그인 classpath를 추가합니다.

```groovy
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.21'
    }
}
```

> 이 단계가 없으면 `cap add android` 또는 `cap sync` 후 Gradle sync 오류가 발생합니다.

### 1. KakaoSDK 초기화 (`Application` 클래스)

`Application` 서브클래스를 생성하고 KakaoSDK를 초기화합니다.

```kotlin
import com.kakao.sdk.common.KakaoSdk

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        KakaoSdk.init(this, "YOUR_NATIVE_APP_KEY")
    }
}
```

`AndroidManifest.xml`에 Application 클래스를 등록합니다:

```xml
<application
    android:name=".MyApplication"
    ...>
```

### 2. `AndroidManifest.xml` — 카카오 로그인 Activity 등록

카카오 계정 웹뷰 로그인 후 앱으로 돌아오기 위한 Activity를 등록합니다.

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
        android:scheme="kakao{NATIVE_APP_KEY}" />
  </intent-filter>
</activity>
```

`{NATIVE_APP_KEY}`를 [카카오 개발자 콘솔](https://developers.kakao.com)의 네이티브 앱 키로 교체하세요.

## API

### `login() → Promise<KakaoLoginResult>`

카카오 로그인을 실행합니다.

- 카카오톡 앱이 설치된 경우: 카카오톡 앱을 통한 로그인
- 미설치 시: 카카오 계정 웹뷰 로그인

**반환값:**

```typescript
interface KakaoLoginResult {
  /** 카카오 회원 고유 ID. 서버 사용자 식별에 사용합니다. */
  socialId: string;
}
```

**에러:**

| 에러 메시지 | 원인 |
|------------|------|
| `카카오 로그인 실패: ...` | 사용자 취소 또는 카카오 인증 오류 |
| `사용자 정보 조회 실패: ...` | 카카오 API 호출 오류 |
| `카카오 사용자 ID를 가져올 수 없습니다` | 예상치 못한 응답 형식 |

## 지원 플랫폼

| 플랫폼 | 지원 |
|--------|------|
| iOS | ✅ iOS 13+ |
| Android | ✅ API 22+ |
| Web | ❌ 미지원 (네이티브 전용) |

## License

MIT
