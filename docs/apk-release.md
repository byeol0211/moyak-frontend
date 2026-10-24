# 팀원 직접 설치용 APK

API 서버: `https://moyak-backend.onrender.com`. Render 환경 변수는 별도 설정해야 합니다. 앱에 Supabase·OpenAI·Daily 비밀 키를 넣지 않습니다.

## 이번 연결

- 로그인: `POST /auth/login`, 중복 확인: `GET /auth/username-available`, 가입: `POST /auth/signup`.
- 실제 가입은 아이디·이름·비밀번호 입력 후 `name`을 서버에 전송하고 가입 성공 시 앱으로 이동합니다. 로그인 응답의 사용자 이름은 마이페이지에 표시합니다. 본인인증 화면은 미리보기 전용이며 실제 본인인증을 수행하지 않습니다.
- 서버 사용자 ID와 Bearer 토큰을 상담·채팅·챗봇 등 API에 사용합니다. 비밀번호·토큰은 디스크에 저장하지 않습니다. 재실행 시 다시 로그인하며 로그아웃 시 토큰을 삭제합니다.
- release에서는 인증 없는 게스트 진입을 숨깁니다. 서버 없는 화면 미리보기는 유지합니다.
- Render 인증 설정이 완료되기 전에는 실제 로그인·가입이 실패할 수 있으며, 앱은 성공으로 처리하지 않습니다.

## 빌드

```powershell
$env:PUB_CACHE = 'E:\flutter-pub-cache'
$env:GRADLE_USER_HOME = 'E:\Android\.gradle'
E:\flutter\bin\flutter.bat build apk --release --dart-define=API_BASE_URL=https://moyak-backend.onrender.com
```

결과: `build/app/outputs/flutter-apk/app-release.apk`.
현재 프로젝트의 디버그 서명을 사용하는 release 빌드입니다. 팀원 직접 설치·테스트용이며 스토어 제출용 서명은 아닙니다. 기존 설치 앱의 서명이 다르면 업데이트 설치가 거절될 수 있습니다.
