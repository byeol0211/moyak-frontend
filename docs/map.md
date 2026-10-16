# 지도 연결

지도 탭(`lib/screens/map_screen/map_screen.dart`)은 카카오 지도(`kakao_map_plugin`)와 백엔드 지도 API로
내 주변 자판기를 보여주는 화면입니다. 화면 구성은 백엔드 HTML `app/map-screen`을 따릅니다.

## 화면 동작

- **목록:** "가까운 자판기 N곳". 번호, 이름, 거리·도보 시간, 운영시간, 재고 배지(재고 있음 / 재고 적음 / 품절)를 보여줍니다.
- **지도:** 목록과 같은 번호의 핀을 찍고, 상세를 연 자판기만 이름까지 표시합니다.
- **내 위치:** 내 위치 버튼으로 현재 위치를 받아 거리순으로 다시 정렬합니다. 위치 권한이 없거나 위치를 못 받으면 기본 위치 기준으로 안내합니다.
- **검색:** 거리와 관계없이 서버가 준 전체 자판기에서 이름·주소·자판기 코드를 대상으로, 띄어쓰기와 대소문자를 무시하고 찾습니다.
- **상세:** 자판기를 누르면 품목별 재고(이름, 가격, 수량, 품절)를 보여주고 "이 자판기 선택 / 선택 해제"를 할 수 있습니다. 선택하면 홈이 "OO 선택됨"으로 바뀝니다.
- 지도 화면에는 구매 기능이 없습니다. 구매와 결제는 자판기에서 합니다.

## 백엔드 API

| API | 용도 |
|---|---|
| `GET /api/v1/map/machines?lat=&lng=` | 자판기 목록(가까운 순, `distance_m` 포함, 최대 500곳) |
| `GET /api/v1/map/machines/{id}` | 자판기 상세와 품목별 재고(`items`) |

```powershell
flutter run --dart-define=API_BASE_URL=https://moyak-backend.onrender.com
```

로그인 화면에서 **게스트로 계속하기**를 선택하면 위 API를 씁니다. **화면 미리보기**를 선택하면 예시 자판기 두 곳으로 동작합니다.
`API_BASE_URL`을 생략하면 웹에서는 현재 웹앱과 같은 출처로 요청합니다. 앱(Android/iOS)에서는 반드시 지정해야 합니다.

## 카카오 지도 키

`lib/kakao_config.dart`의 `kakaoJavaScriptKey`에 Kakao Developers의 JavaScript 키를 넣습니다.
키가 비어 있으면 지도 대신 안내 문구가 표시되고, 목록과 상세는 그대로 쓸 수 있습니다.

`kakaoSiteDomain`(현재 `http://localhost`)은 Kakao Developers → 내 애플리케이션 → 플랫폼 → Web → 사이트 도메인에 등록된 주소여야 합니다.
Android/iOS 앱은 지도를 띄우는 WebView 페이지 주소로 이 값을 씁니다.
웹으로 실행할 때는 실행 주소(예: `http://localhost:5555`)도 사이트 도메인에 등록해야 합니다.

```powershell
flutter run -d chrome --web-port 5555
```

- 등록되지 않은 도메인에서는 SDK가 401을 돌려주고 콘솔에 `domain mismatched!` 오류가 찍힙니다.
- 웹에서 지도 위에 겹치는 위젯은 `KakaoMapPointerInterceptor`로 감싸야 탭을 받습니다.
- 앱의 카카오 키와 서버(`GET /api/v1/map/config`)가 주는 키가 서로 다릅니다. 하나로 통일하는 것이 좋습니다.

검증: `flutter analyze`, `flutter test`
