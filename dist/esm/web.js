import { WebPlugin } from '@capacitor/core';
// 카카오 로그인은 네이티브 앱 환경 전용이므로, 웹 구현체는 unimplemented 에러를 던진다.
export class KakaoLoginWeb extends WebPlugin {
    async login() {
        throw this.unimplemented('카카오 로그인은 네이티브 앱 환경에서만 지원됩니다.');
    }
}
//# sourceMappingURL=web.js.map