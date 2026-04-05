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
