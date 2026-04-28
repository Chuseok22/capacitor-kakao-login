export interface KakaoLoginPlugin {
  /**
   * 카카오 로그인을 실행한다.
   * - 카카오톡 앱이 설치된 경우: 앱을 통한 로그인
   * - 미설치 시: 카카오 계정 웹뷰 로그인
   * @returns 카카오 사용자 정보. 동의한 스코프의 필드만 값이 채워진다.
   */
  login(): Promise<KakaoLoginResult>;
}

export interface KakaoLoginResult {
  /** 카카오 회원 고유 ID. 서버에 전달하여 사용자 식별에 사용한다. */
  socialId: string;
  /** 닉네임. 카카오 개발자 콘솔에서 profile 동의 항목 활성화 필요. */
  nickname?: string;
  /** 프로필 이미지 URL. profile 동의 항목 활성화 필요. */
  profileImageUrl?: string;
  /** 썸네일 이미지 URL. profile 동의 항목 활성화 필요. */
  thumbnailImageUrl?: string;
  /** 이메일. account_email 동의 항목 활성화 필요. */
  email?: string;
  /** 실명. name 동의 항목 활성화 필요. */
  name?: string;
  /** 전화번호. phone_number 동의 항목 활성화 필요. */
  phoneNumber?: string;
  /** 성별. 'male' | 'female' | 'other'. gender 동의 항목 활성화 필요. */
  gender?: string;
  /** 출생연도 4자리 (예: '1990'). birthdate 동의 항목 활성화 필요. */
  birthyear?: string;
  /** 생일 MMDD 형식 (예: '0101'). birthdate 동의 항목 활성화 필요. */
  birthday?: string;
}
