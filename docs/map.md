# 지도 연결

지도 탭(`lib/screens/map_screen/map_screen.dart`)은 jmj 디자인에 카카오 지도(`kakao_map_plugin`)를 연결한 화면입니다.
이름·주소 검색, 자판기 마커 선택, 위치 이동, 주소·운영 시간·재고 합계 표시,
새로고침을 제공합니다. 자판기 좌표가 없으면 가짜 위치를 표시하지 않습니다.
하단 시트의 "재고 상품보기"는 스토어 화면으로 이동합니다.

백엔드 `hanbyeol` 브랜치의 `docs/map-api.md`를 따라 지도 API를 8002 포트에서 실행한 뒤:

```powershell
flutter pub get
flutter run -d chrome --web-port 8000 --dart-define=API_BASE_URL=http://127.0.0.1:8002
```

스플래시 → 권한 → 로그인 → 온보딩을 지나 하단의 지도 탭을 선택합니다. 로그인은 기존 시연 동작입니다.
`API_BASE_URL`을 생략하면 현재 웹앱과 같은 출처의 `/api/v1/map/machines`를 호출합니다.
앱(Android/iOS)에서는 같은 출처가 없으므로 반드시 `API_BASE_URL`을 지정해야 합니다.
배포 시 프론트 URL을 백엔드 `MAP_ALLOWED_ORIGINS`에 등록하세요.

## 카카오 지도 키

`lib/kakao_config.dart`의 `kakaoJavaScriptKey`에 Kakao Developers의 JavaScript 키를 넣습니다.
키가 비어 있으면 지도 대신 안내 문구가 표시됩니다.

`kakaoSiteDomain`은 Kakao Developers → 내 애플리케이션 → 플랫폼 → Web → 사이트 도메인에 등록된 주소입니다
(현재 `http://localhost:8000`). Android/iOS 앱은 WebView 페이지 주소로 이 값을 쓰고,
웹은 같은 주소로 실행해야 지도가 표시됩니다.

```powershell
flutter run -d chrome --web-port 8000
```

등록되지 않은 도메인에서는 SDK가 401을 돌려주고 콘솔에 `domain mismatched!` 오류가 찍힙니다.
웹에서 지도 위에 겹치는 위젯은 `KakaoMapPointerInterceptor`로 감싸야 탭을 받습니다.

검증: `flutter analyze`, `flutter test`, `flutter build web`.
