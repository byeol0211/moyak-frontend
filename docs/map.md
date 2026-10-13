# 지도 연결

지도 탭(`lib/screens/map_screen/map_screen.dart`)은 jmj 디자인에 OpenStreetMap 지도를 연결한 화면입니다.
이름·주소 검색, 자판기 마커 선택, 위치 이동, 주소·운영 시간·재고 합계 표시,
새로고침을 제공합니다. 자판기 좌표가 없으면 가짜 위치를 표시하지 않습니다.
하단 시트의 "재고 상품보기"는 스토어 화면으로 이동합니다.

백엔드 `hanbyeol` 브랜치의 `docs/map-api.md`를 따라 지도 API를 8002 포트에서 실행한 뒤:

```powershell
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8002
```

스플래시 → 권한 → 로그인 → 온보딩을 지나 하단의 지도 탭을 선택합니다. 로그인은 기존 시연 동작입니다.
`API_BASE_URL`을 생략하면 현재 웹앱과 같은 출처의 `/api/v1/map/machines`를 호출합니다.
앱(Android/iOS)에서는 같은 출처가 없으므로 반드시 `API_BASE_URL`을 지정해야 합니다.
배포 시 프론트 URL을 백엔드 `MAP_ALLOWED_ORIGINS`에 등록하세요.

OpenStreetMap 지도는 별도 키 없이 표시합니다. 출처 표기를 유지하고 공개 타일 서버의
[이용 정책](https://operations.osmfoundation.org/policies/tiles/)을 준수해야 합니다.
서버는 브라우저의 Referer를 차단하지 않는 정책을 사용해야 합니다.
다운로드·오프라인 프리페치 기능은 구현하지 않았습니다.

검증: `flutter analyze`, `flutter test`, `flutter build web`.
