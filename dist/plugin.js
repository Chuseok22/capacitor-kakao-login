var capacitorKakaoLogin = (function (exports, core) {
    'use strict';

    // 플러그인 등록명은 iOS jsName 및 Android @CapacitorPlugin(name) 과 반드시 일치해야 한다.
    const KakaoLogin = core.registerPlugin('KakaoLogin', {
        web: () => Promise.resolve().then(function () { return web; }).then(m => new m.KakaoLoginWeb()),
    });

    // 카카오 로그인은 네이티브 앱 환경 전용이므로, 웹 구현체는 unimplemented 에러를 던진다.
    class KakaoLoginWeb extends core.WebPlugin {
        async login() {
            throw this.unimplemented('카카오 로그인은 네이티브 앱 환경에서만 지원됩니다.');
        }
    }

    var web = /*#__PURE__*/Object.freeze({
        __proto__: null,
        KakaoLoginWeb: KakaoLoginWeb
    });

    exports.KakaoLogin = KakaoLogin;

    return exports;

})({}, capacitorExports);
//# sourceMappingURL=plugin.js.map
