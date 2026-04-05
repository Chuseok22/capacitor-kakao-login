import { WebPlugin } from '@capacitor/core';
import type { KakaoLoginPlugin, KakaoLoginResult } from './definitions';
export declare class KakaoLoginWeb extends WebPlugin implements KakaoLoginPlugin {
    login(): Promise<KakaoLoginResult>;
}
