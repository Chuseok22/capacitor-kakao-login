import { registerPlugin } from '@capacitor/core';
import type { KakaoLoginPlugin } from './definitions';

// 플러그인 등록명은 iOS jsName 및 Android @CapacitorPlugin(name) 과 반드시 일치해야 한다.
const KakaoLogin = registerPlugin<KakaoLoginPlugin>('KakaoLogin', {
  web: () => import('./web').then(m => new m.KakaoLoginWeb()),
});

export * from './definitions';
export { KakaoLogin };
