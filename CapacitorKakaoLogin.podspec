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
  s.dependency 'KakaoSDKAuth', '~> 2.23'
  s.dependency 'KakaoSDKUser', '~> 2.23'
end
