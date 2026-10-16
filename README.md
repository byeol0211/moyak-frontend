# MOYAK 소비자 앱

스마트 의약품 자판기 서비스의 Flutter 소비자 앱입니다. 키오스크는 별도 프로젝트에서 개발합니다.

백엔드 없이 확인하려면 실행 후 로그인 화면에서 **회원가입 없이 화면 미리보기**를 선택하세요.

```sh
flutter pub get
flutter run
```

실제 서버(Render)와 연결해서 실행하려면 서버 주소를 지정하고 로그인 화면에서 **게스트로 계속하기**를 선택하세요.

```sh
flutter run --dart-define=API_BASE_URL=https://moyak-backend.onrender.com
```

- 화면·파일 구성, 백엔드 연동 현황, Android 빌드 방법: [프론트엔드 구성](docs/frontend.md)
- 화면별 확인 방법과 미리보기 기능: [프론트 작업 현황](docs/frontend-progress.md)
- 화상 통화(Daily) 구현: [Daily 연동](docs/daily-integration.md)
