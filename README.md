# @chuseok22/capacitor-kakao-login

Capacitor 앱에서 카카오 소셜 로그인을 최소한의 설정으로 사용할 수 있는 플러그인입니다.

- iOS / Android 지원
- 카카오톡 앱 로그인 우선, 미설치 시 카카오 계정 웹뷰 로그인으로 자동 폴백
- Capacitor 6.x 이상

---

## 빠른 시작

**사용자가 해야 할 일은 총 4가지입니다.**

```
1. npm install + cap sync
2. capacitor.config.ts에 appKey 설정
3. iOS Info.plist에 URL 스킴 등록
4. Android build.gradle에 manifestPlaceholders 1줄 추가
```

SDK 초기화, URL 핸들러 등록, AuthCodeHandlerActivity는 플러그인이 자동으로 처리합니다.

---

## 목차

1. [사전 요구사항](#1-사전-요구사항)
2. [카카오 개발자 콘솔 설정](#2-카카오-개발자-콘솔-설정)
3. [설치](#3-설치)
4. [앱 키 설정 (공통)](#4-앱-키-설정-공통)
5. [iOS 설정](#5-ios-설정)
6. [Android 설정](#6-android-설정)
7. [사용법](#7-사용법)
8. [API](#8-api)
9. [지원 플랫폼](#9-지원-플랫폼)
10. [트러블슈팅](#10-트러블슈팅)

---

## 1. 사전 요구사항

| 항목 | 최소 버전 |
|------|-----------|
| Capacitor | 6.x 이상 |
| iOS | 13.0 이상 |
| Android | API 22 (Android 5.1) 이상 |

---

## 2. 카카오 개발자 콘솔 설정

### 2-1. 앱 등록 및 네이티브 앱 키 발급

1. [카카오 개발자 콘솔](https://developers.kakao.com) → **내 애플리케이션 → 애플리케이션 추가하기**
2. 앱 이름, 회사명 입력 후 저장
3. **앱 키** 탭에서 **네이티브 앱 키** 복사

### 2-2. 플랫폼 등록

**iOS:** 앱 설정 → 플랫폼 → iOS 플랫폼 등록 → **번들 ID** 입력 (Xcode 프로젝트의 Bundle Identifier)

**Android:** 앱 설정 → 플랫폼 → Android 플랫폼 등록 → **패키지명** 입력 + **키 해시** 등록

> **키 해시 추출 (개발용):**
> ```bash
> keytool -exportcert -alias androiddebugkey \
>   -keystore ~/.android/debug.keystore \
>   -storepass android -keypass android \
>   | openssl sha1 -binary | openssl base64
> ```

### 2-3. 카카오 로그인 활성화

앱 설정 → **카카오 로그인 → 활성화 설정 → ON**

---

## 3. 설치

```bash
npm install @chuseok22/capacitor-kakao-login
npx cap sync
```

---

## 4. 앱 키 설정 (공통)

`capacitor.config.ts`에 카카오 네이티브 앱 키를 설정합니다.  
플러그인이 이 값을 읽어 iOS/Android 모두 SDK를 자동 초기화합니다.

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.example.myapp',
  appName: 'My App',
  webDir: 'dist',
  plugins: {
    KakaoLogin: {
      appKey: 'YOUR_NATIVE_APP_KEY'   // ← 여기에 네이티브 앱 키 입력
    }
  }
};

export default config;
```

---

## 5. iOS 설정

**AppDelegate 수정 없이 Info.plist만 설정하면 됩니다.**

`ios/App/App/Info.plist`에 아래 항목을 추가합니다.

```xml
<!-- 카카오톡 설치 여부 확인을 위한 URL 스킴 허용 -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>storykompassauth</string>
  <string>kakaolink</string>
</array>

<!-- OAuth 콜백 수신을 위한 커스텀 URL 스킴 등록 -->
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

`YOUR_NATIVE_APP_KEY`를 실제 네이티브 앱 키로 교체하세요.  
예: 앱 키가 `abc1234567` 이면 → `kakaoabc1234567`

> **왜 Info.plist는 직접 수정해야 하나요?**  
> iOS는 외부 패키지가 호스트 앱의 Info.plist를 수정할 수 없습니다. 이 2가지 항목은 OS 제약상 불가피하게 수동 설정이 필요합니다.

---

## 6. Android 설정

**Application 클래스 생성, AndroidManifest 수정 없이 build.gradle 1줄만 추가하면 됩니다.**

`android/app/build.gradle`의 `defaultConfig` 블록에 아래 한 줄을 추가합니다.

```groovy
android {
    defaultConfig {
        // 기존 항목들 유지...

        manifestPlaceholders = [kakaoNativeAppKey: "YOUR_NATIVE_APP_KEY"]  // ← 이 줄만 추가
    }
}
```

`YOUR_NATIVE_APP_KEY`를 실제 네이티브 앱 키로 교체하세요.

> **이것만으로 충분한 이유:**
> - `AuthCodeHandlerActivity`는 플러그인 AndroidManifest에 선언되어 Gradle이 자동으로 호스트 앱 Manifest에 병합합니다.
> - `KakaoSdk.init()`는 플러그인 `load()` 시 자동으로 호출됩니다.

### Kotlin Gradle 플러그인 (필요한 경우)

Gradle sync 오류가 발생하면 `android/build.gradle`의 `buildscript.dependencies`에 아래를 추가하세요.

```groovy
classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.21'
```

---

## 7. 사용법

```typescript
import { KakaoLogin } from '@chuseok22/capacitor-kakao-login';

async function loginWithKakao() {
  try {
    const { socialId } = await KakaoLogin.login();
    // socialId를 서버에 전달해 사용자 인증 처리
    await authenticateWithServer(socialId);
  } catch (error) {
    console.error('카카오 로그인 실패:', error);
  }
}
```

---

## 8. API

### `KakaoLogin.login()`

```typescript
login(): Promise<KakaoLoginResult>
```

**동작:**
- 카카오톡 설치 → 카카오톡 앱 로그인
- 카카오톡 미설치 → 카카오 계정 웹뷰 로그인 (자동 폴백)

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
| `카카오 로그인 실패: ...` | 사용자 취소 또는 카카오 인증 오류 |
| `사용자 정보 조회 실패: ...` | 카카오 API 호출 오류 |
| `카카오 사용자 ID를 가져올 수 없습니다` | 예상치 못한 응답 형식 |

---

## 9. 지원 플랫폼

| 플랫폼 | 지원 | 최소 버전 |
|--------|------|-----------|
| iOS | ✅ | iOS 13.0+ |
| Android | ✅ | API 22+ |
| Web | ❌ | — |

---

## 10. 트러블슈팅

### `appKey is not set` 경고가 콘솔에 출력되는 경우

`capacitor.config.ts`의 `plugins.KakaoLogin.appKey`가 설정되어 있는지 확인하세요.  
설정 후 `npx cap sync`를 다시 실행해야 반영됩니다.

### iOS — 카카오톡 앱 로그인 후 앱으로 돌아오지 않는 경우

`Info.plist`의 `CFBundleURLSchemes`에 `kakao{네이티브앱키}` 형식으로 등록되어 있는지 확인하세요.

### iOS — `UNIMPLEMENTED` 에러

`npx cap sync`를 다시 실행하고, Xcode에서 **Product → Clean Build Folder** 후 재빌드하세요.

### Android — Gradle sync 오류 (`Unresolved reference: kotlin`)

`android/build.gradle`의 `buildscript.dependencies`에 Kotlin 플러그인 classpath를 추가하세요. ([6번 참고](#6-android-설정))

### Android — 로그인 후 앱으로 돌아오지 않는 경우

`android/app/build.gradle`의 `manifestPlaceholders`에 앱 키가 올바르게 입력되어 있는지 확인하세요.  
값을 변경하면 `npx cap sync` 후 앱을 다시 빌드해야 합니다.

### 카카오 개발자 콘솔 — 키 해시 불일치 오류 (Android)

디버그 키해시와 릴리즈 키해시를 각각 콘솔에 등록해야 합니다.

---

## License

MIT
