# capacitor-kakao-login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Capacitor 앱에서 카카오 소셜 로그인을 `npm install` + `npx cap sync` 만으로 동작시키는 공개 npm 패키지를 개발하고 배포한다.

**Architecture:** TypeScript 브릿지 레이어 → iOS Swift (KakaoSDK SPM) + Android Kotlin (Kakao Android SDK) 이중 플랫폼 Capacitor 플러그인. `npx cap sync` 실행 시 Capacitor CLI가 패키지를 자동 인식하도록 `capacitor.ios.src` / `capacitor.android.src` 필드를 `package.json`에 선언한다. Podspec은 하위 호환을 위해 함께 제공한다.

**Tech Stack:** TypeScript, Rollup, Swift 5.9 (SPM), Kotlin, Capacitor 6, KakaoSDK iOS 2.x, Kakao Android SDK 2.x

---

## 프로젝트 규모 예상

| 항목 | 수치 |
|------|------|
| 총 생성 파일 수 | ~18 개 |
| 예상 총 코드 라인 수 | ~600 줄 (README 제외) |
| 복잡도 | 중간 — 이중 플랫폼 + npm 배포 절차 |
| 주요 위험 요소 | SPM ↔ CocoaPods 호환, Android SDK Gradle DSL, npm publish scoped 패키지 설정 |

---

## 파일 구조 (생성 예정)

```
capacitor-kakao-login/
├── package.json                          # npm 패키지 설정, capacitor 플러그인 메타
├── tsconfig.json                         # TS 빌드 설정
├── rollup.config.js                      # JS 번들러 설정
├── .npmignore                            # npm 배포 시 제외 파일
├── CapacitorKakaoLogin.podspec           # CocoaPods 의존성 선언 (하위 호환)
├── src/
│   ├── definitions.ts                    # 플러그인 TypeScript 인터페이스
│   ├── index.ts                          # registerPlugin + re-export
│   └── web.ts                            # Web 폴백 (미지원 에러 반환)
├── ios/
│   ├── Package.swift                     # SPM 의존성 선언 (KakaoSDK)
│   └── Sources/
│       └── KakaoLoginPlugin/
│           └── KakaoLoginPlugin.swift    # iOS 플러그인 구현
└── android/
    ├── build.gradle                      # Kakao Android SDK 의존성
    └── src/
        └── main/
            ├── AndroidManifest.xml       # Android 매니페스트
            └── java/
                └── com/
                    └── capacitorkakaologin/
                        └── KakaoLoginPlugin.kt  # Android 플러그인 구현
```

---

## Task 1: 프로젝트 기반 설정 (package.json, tsconfig, rollup)

**목적:** Capacitor CLI가 이 패키지를 플러그인으로 인식하고 JS 빌드가 가능한 기반 설정.

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `rollup.config.js`
- Create: `.npmignore`
- Modify: `.gitignore`

- [ ] **Step 1-1: package.json 작성**

```json
{
  "name": "@chuseok22/capacitor-kakao-login",
  "version": "1.0.0",
  "description": "Capacitor plugin for Kakao social login (iOS & Android)",
  "main": "dist/plugin.cjs.js",
  "module": "dist/plugin.esm.js",
  "types": "dist/definitions.d.ts",
  "unpkg": "dist/plugin.js",
  "files": [
    "dist/",
    "ios/",
    "android/",
    "CapacitorKakaoLogin.podspec"
  ],
  "author": "Baek Jihoon",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/chuseok22/capacitor-kakao-login.git"
  },
  "keywords": [
    "capacitor",
    "plugin",
    "kakao",
    "kakao-login",
    "social-login",
    "ios",
    "android"
  ],
  "scripts": {
    "build": "npm run clean && npm run docgen && tsc && rollup -c rollup.config.js",
    "clean": "rimraf ./dist",
    "docgen": "docgen --api KakaoLoginPlugin --output-readme README.md",
    "lint": "eslint . --ext ts",
    "fmt": "prettier --write --parser typescript 'src/**/*.ts'",
    "verify": "npm run verify:ios && npm run verify:android && npm run verify:web",
    "verify:ios": "cd ios && pod install && xcodebuild -scheme Podfile-name ARCHS=x86_64 build",
    "verify:android": "cd android && ./gradlew build",
    "verify:web": "npm run build"
  },
  "devDependencies": {
    "@capacitor/android": "^6.0.0",
    "@capacitor/core": "^6.0.0",
    "@capacitor/docgen": "^0.0.18",
    "@capacitor/ios": "^6.0.0",
    "@ionic/eslint-config": "^0.3.0",
    "@ionic/prettier-config": "~1.0.1",
    "@ionic/swiftlint-config": "^1.1.2",
    "eslint": "^7.32.0",
    "prettier": "~2.3.2",
    "rimraf": "^5.0.0",
    "rollup": "^4.0.0",
    "@rollup/plugin-node-resolve": "^15.0.0",
    "typescript": "~5.1.3"
  },
  "peerDependencies": {
    "@capacitor/core": ">=5.0.0"
  },
  "capacitor": {
    "ios": {
      "src": "ios"
    },
    "android": {
      "src": "android"
    }
  },
  "publishConfig": {
    "access": "public"
  }
}
```

- [ ] **Step 1-2: tsconfig.json 작성**

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "module": "ES2015",
    "lib": ["ES2017", "dom"],
    "declaration": true,
    "sourceMap": true,
    "outDir": "./dist/esm",
    "moduleResolution": "node",
    "strict": true,
    "allowUnusedLabels": false,
    "allowUnreachableCode": false,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
```

- [ ] **Step 1-3: rollup.config.js 작성**

```javascript
import nodeResolve from '@rollup/plugin-node-resolve';

export default {
  input: 'dist/esm/index.js',
  output: [
    {
      file: 'dist/plugin.js',
      format: 'iife',
      name: 'capacitorKakaoLogin',
      globals: {
        '@capacitor/core': 'capacitorExports',
      },
      sourcemap: true,
      inlineDynamicImports: true,
    },
    {
      file: 'dist/plugin.cjs.js',
      format: 'cjs',
      sourcemap: true,
      inlineDynamicImports: true,
    },
    {
      file: 'dist/plugin.esm.js',
      format: 'esm',
      sourcemap: true,
      inlineDynamicImports: true,
    },
  ],
  plugins: [
    nodeResolve(),
  ],
  external: ['@capacitor/core'],
};
```

- [ ] **Step 1-4: .npmignore 작성**

```
.github/
.idea/
docs/
src/
ios/Tests/
android/build/
*.map
```

- [ ] **Step 1-5: .gitignore 업데이트**

기존 `.gitignore`에 아래 항목 추가:
```
dist/
node_modules/
*.js.map
android/build/
android/.gradle/
ios/build/
ios/DerivedData/
.DS_Store
```

- [ ] **Step 1-6: 의존성 설치**

```bash
npm install
```

Expected: `node_modules/` 생성, 에러 없음

- [ ] **Step 1-7: 커밋**

```bash
git add package.json tsconfig.json rollup.config.js .npmignore .gitignore
git commit -m "chore: 프로젝트 기반 설정 (package.json, tsconfig, rollup)"
```

---

## Task 2: TypeScript 레이어 구현

**목적:** JS/TS 사용자가 `KakaoLogin.login()` 을 호출하는 브릿지 레이어 구현.

**Files:**
- Create: `src/definitions.ts`
- Create: `src/index.ts`
- Create: `src/web.ts`

- [ ] **Step 2-1: src/definitions.ts 작성**

```typescript
export interface KakaoLoginPlugin {
  /**
   * 카카오 로그인을 실행한다.
   * - 카카오톡 앱이 설치된 경우: 앱을 통한 로그인
   * - 미설치 시: 카카오 계정 웹뷰 로그인
   * @returns 카카오 사용자 고유 ID (socialId)
   */
  login(): Promise<KakaoLoginResult>;
}

export interface KakaoLoginResult {
  /** 카카오 회원 고유 ID. 서버에 전달하여 사용자 식별에 사용한다. */
  socialId: string;
}
```

- [ ] **Step 2-2: src/index.ts 작성**

```typescript
import { registerPlugin } from '@capacitor/core';
import type { KakaoLoginPlugin } from './definitions';

const KakaoLogin = registerPlugin<KakaoLoginPlugin>('KakaoLogin', {
  web: () => import('./web').then(m => new m.KakaoLoginWeb()),
});

export * from './definitions';
export { KakaoLogin };
```

- [ ] **Step 2-3: src/web.ts 작성**

```typescript
import { WebPlugin } from '@capacitor/core';
import type { KakaoLoginPlugin, KakaoLoginResult } from './definitions';

export class KakaoLoginWeb extends WebPlugin implements KakaoLoginPlugin {
  async login(): Promise<KakaoLoginResult> {
    throw this.unimplemented('카카오 로그인은 네이티브 앱 환경에서만 지원됩니다.');
  }
}
```

- [ ] **Step 2-4: TypeScript 빌드 확인**

```bash
npx tsc
```

Expected: `dist/esm/` 디렉토리 생성, 에러 없음

- [ ] **Step 2-5: 커밋**

```bash
git add src/
git commit -m "feat: TypeScript 브릿지 레이어 구현 (definitions, index, web)"
```

---

## Task 3: iOS Swift 플러그인 구현

**목적:** KakaoSDK를 SPM으로 의존하고 `npx cap sync`에서 자동 인식되는 Swift 플러그인 구현.

**Files:**
- Create: `ios/Package.swift`
- Create: `ios/Sources/KakaoLoginPlugin/KakaoLoginPlugin.swift`
- Create: `CapacitorKakaoLogin.podspec`

- [ ] **Step 3-1: ios/Package.swift 작성**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KakaoLoginPlugin",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "KakaoLoginPlugin",
            targets: ["KakaoLoginPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", branch: "main"),
        .package(url: "https://github.com/kakao/kakao-ios-sdk", from: "2.23.0"),
    ],
    targets: [
        .target(
            name: "KakaoLoginPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "KakaoSDKAuth", package: "kakao-ios-sdk"),
                .product(name: "KakaoSDKUser", package: "kakao-ios-sdk"),
            ],
            path: "Sources/KakaoLoginPlugin"
        )
    ]
)
```

- [ ] **Step 3-2: ios/Sources/KakaoLoginPlugin/KakaoLoginPlugin.swift 작성**

중간 디렉토리 생성:
```bash
mkdir -p ios/Sources/KakaoLoginPlugin
```

파일 내용:
```swift
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
                    call.reject("카카오 사용자 ID를 가져올 수 없습니다")
                    return
                }

                call.resolve(["socialId": String(userId)])
            }
        }
    }
}
```

- [ ] **Step 3-3: CapacitorKakaoLogin.podspec 작성 (CocoaPods 하위 호환)**

```ruby
Pod::Spec.new do |s|
  s.name         = 'CapacitorKakaoLogin'
  s.version      = '1.0.0'
  s.summary      = 'Capacitor plugin for Kakao social login (iOS & Android)'
  s.homepage     = 'https://github.com/chuseok22/capacitor-kakao-login'
  s.license      = 'MIT'
  s.author       = { 'Baek Jihoon' => 'chuseok22@gmail.com' }
  s.source       = { :git => 'https://github.com/chuseok22/capacitor-kakao-login.git', :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.swift'
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.9'
  s.dependency 'Capacitor'
  s.dependency 'KakaoSDKAuth', '~> 2.0'
  s.dependency 'KakaoSDKUser', '~> 2.0'
end
```

- [ ] **Step 3-4: 커밋**

```bash
git add ios/ CapacitorKakaoLogin.podspec
git commit -m "feat: iOS Swift 플러그인 구현 (KakaoSDK SPM + Podspec)"
```

---

## Task 4: Android Kotlin 플러그인 구현

**목적:** Kakao Android SDK를 Gradle로 의존하는 Android 플러그인 구현.

**Files:**
- Create: `android/build.gradle`
- Create: `android/src/main/AndroidManifest.xml`
- Create: `android/src/main/java/com/capacitorkakaologin/KakaoLoginPlugin.kt`

- [ ] **Step 4-1: android/build.gradle 작성**

```groovy
apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    namespace "com.capacitorkakaologin"
    compileSdkVersion project.hasProperty('compileSdkVersion') ? rootProject.ext.compileSdkVersion : 34
    defaultConfig {
        minSdkVersion project.hasProperty('minSdkVersion') ? rootProject.ext.minSdkVersion : 22
        targetSdkVersion project.hasProperty('targetSdkVersion') ? rootProject.ext.targetSdkVersion : 34
        versionCode 1
        versionName "1.0"
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
    lintOptions {
        abortOnError false
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }
}

repositories {
    google()
    mavenCentral()
    maven { url 'https://devrepo.kakao.com/nexus/content/groups/public/' }
}

dependencies {
    implementation fileTree(dir: 'libs', include: ['*.jar'])
    implementation project(':capacitor-android')
    // Kakao Android SDK — 사용자 로그인 모듈만 포함
    implementation "com.kakao.sdk:v2-user:2.20.6"
}
```

- [ ] **Step 4-2: android/src/main/AndroidManifest.xml 작성**

중간 디렉토리 생성:
```bash
mkdir -p android/src/main/java/com/capacitorkakaologin
```

파일 내용:
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
</manifest>
```

- [ ] **Step 4-3: KakaoLoginPlugin.kt 작성**

```kotlin
package com.capacitorkakaologin

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.kakao.sdk.auth.model.OAuthToken
import com.kakao.sdk.user.UserApiClient

@CapacitorPlugin(name = "KakaoLogin")
class KakaoLoginPlugin : Plugin() {

    @PluginMethod
    fun login(call: PluginCall) {
        val context = context

        // OAuthToken 콜백 — 앱/계정 로그인 공통 처리
        val callback: (OAuthToken?, Throwable?) -> Unit = callback@{ token, error ->
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
            // 카카오톡 앱 로그인
            UserApiClient.instance.loginWithKakaoTalk(context, callback = callback)
        } else {
            // 카카오 계정 웹뷰 로그인
            UserApiClient.instance.loginWithKakaoAccount(context, callback = callback)
        }
    }
}
```

- [ ] **Step 4-4: 커밋**

```bash
git add android/
git commit -m "feat: Android Kotlin 플러그인 구현 (Kakao Android SDK v2-user)"
```

---

## Task 5: JS 빌드 완성 및 dist 검증

**목적:** Rollup 번들링 완료 후 dist 구조가 올바른지 확인한다.

**Files:**
- Generate: `dist/plugin.cjs.js`, `dist/plugin.esm.js`, `dist/plugin.js`
- Generate: `dist/definitions.d.ts`

- [ ] **Step 5-1: docgen 설치 확인 및 build 실행**

```bash
npm run build
```

Expected 출력:
```
dist/esm/index.js
dist/esm/definitions.js
dist/esm/web.js
dist/plugin.cjs.js
dist/plugin.esm.js
dist/plugin.js
```

- [ ] **Step 5-2: dist 구조 확인**

```bash
ls dist/
```

Expected:
```
definitions.d.ts  plugin.cjs.js  plugin.esm.js  plugin.js  esm/
```

- [ ] **Step 5-3: CJS 번들 내용 확인 — KakaoLogin 등록 확인**

```bash
grep "KakaoLogin" dist/plugin.cjs.js
```

Expected: `registerPlugin('KakaoLogin', ...)` 포함 확인

- [ ] **Step 5-4: 커밋**

```bash
git add dist/
git commit -m "build: Rollup 번들 빌드 완성 (dist 생성)"
```

---

## Task 6: README 작성 및 npm 배포

**목적:** 사용자가 패키지를 설치하고 설정할 수 있는 README 문서 작성 + npm 배포.

**Files:**
- Modify: `README.md`
- Modify: `TODO.md`

- [ ] **Step 6-1: README.md 작성**

````markdown
# @chuseok22/capacitor-kakao-login

Capacitor 앱에서 카카오 소셜 로그인을 쉽게 사용할 수 있는 플러그인입니다.
`npm install` + `npx cap sync` 만으로 iOS와 Android 모두 자동 설정됩니다.

## 설치

```bash
npm install @chuseok22/capacitor-kakao-login
npx cap sync
```

## 사용법

```typescript
import { KakaoLogin } from '@chuseok22/capacitor-kakao-login';

const { socialId } = await KakaoLogin.login();
console.log('카카오 사용자 ID:', socialId);
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

func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if AuthApi.isKakaoTalkLoginUrl(url) {
        return AuthController.handleOpenUrl(url: url)
    }
    return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
}
```

### 3. Info.plist 설정

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kakaokompassauth</string>
  <string>storykompassauth</string>
  <string>kakaolink</string>
</array>

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

## Android 설정

### 1. KakaoSDK 초기화 (`Application` 클래스)

```kotlin
import com.kakao.sdk.common.KakaoSdk

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        KakaoSdk.init(this, "YOUR_NATIVE_APP_KEY")
    }
}
```

### 2. AndroidManifest.xml 설정

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

## API

### `login() → Promise<KakaoLoginResult>`

카카오 로그인을 실행한다.

- 카카오톡 앱이 설치된 경우: 앱 로그인
- 미설치 시: 카카오 계정 웹뷰 로그인

**Returns:** `{ socialId: string }` — 카카오 회원 고유 ID

## 왜 이 패키지가 필요한가

`npx cap sync` 실행 시 Capacitor CLI는 `node_modules/` 내 npm 패키지만 플러그인으로 스캔한다. 로컬 Swift 파일은 자동으로 `packageClassList`에 등록되지 않아 `UNIMPLEMENTED` 에러가 발생한다. 이 패키지는 올바른 Capacitor 플러그인 구조를 갖추어 `npx cap sync`만으로 자동 등록되게 한다.

## License

MIT
````

- [ ] **Step 6-2: npm 배포 전 최종 빌드 확인**

```bash
npm run build
npm pack --dry-run
```

Expected: `dist/`, `ios/`, `android/`, `CapacitorKakaoLogin.podspec` 포함 확인

- [ ] **Step 6-3: npm 로그인 및 배포**

```bash
npm login
npm publish --access public
```

Expected: `+ @chuseok22/capacitor-kakao-login@1.0.0` 출력

- [ ] **Step 6-4: TODO.md 업데이트**

`TODO.md`의 진행 완료 항목 체크 및 진행된 사항 기록

- [ ] **Step 6-5: 최종 커밋**

```bash
git add README.md TODO.md
git commit -m "docs: README 작성 및 TODO.md 완료 처리"
```

---

## 자체 검토 (Spec Coverage)

| 요구사항 | 커버 Task |
|---------|-----------|
| `npm install` + `npx cap sync` 자동 인식 | Task 1 (capacitor 필드) |
| iOS 카카오 로그인 구현 | Task 3 |
| Android 카카오 로그인 구현 | Task 4 |
| TypeScript 타입 지원 | Task 2 |
| npm 배포 | Task 6 |
| 사용 문서 | Task 6 |
| SPM 의존성 선언 | Task 3 |
| CocoaPods 하위 호환 | Task 3 |

---

## 주의사항 및 위험 요소

1. **`@objc(KakaoLoginPlugin)` 어노테이션 필수** — Capacitor CLI가 이 패턴으로 클래스를 탐색하므로 절대 변경 금지
2. **`jsName = "KakaoLogin"`** — `registerPlugin('KakaoLogin', ...)` 과 반드시 일치해야 함
3. **Android SDK Nexus 저장소** — `devrepo.kakao.com` maven 저장소 선언 필수 (`build.gradle`)
4. **Scoped 패키지 publish** — `publishConfig.access = "public"` 없으면 `npm publish` 실패
5. **iOS SPM + Capacitor** — `capacitor-swift-pm` 패키지로 Capacitor 의존성 해결
