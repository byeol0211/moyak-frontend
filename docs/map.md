# 지도 연결

기존 지도 탭을 Flutter OpenStreetMap 지도로 교체했습니다.
이름·주소 검색, 자판기 마커 선택, 위치 이동, 주소·운영 시간·재고 합계 표시,
새로고침을 제공합니다. 자판기 좌표가 없으면 가짜 위치를 표시하지 않습니다.

백엔드 `hanbyeol` 브랜치의 `docs/map-api.md`를 따라 지도 API를 8002 포트에서 실행한 뒤:

```powershell
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8002
```

로그인 화면의 버튼을 누르고 지도 탭을 선택합니다. 로그인은 기존 시연 동작입니다.
`API_BASE_URL`을 생략하면 현재 웹앱과 같은 출처의 `/api/v1/map/machines`를 호출합니다.
배포 시 프론트 URL을 백엔드 `MAP_ALLOWED_ORIGINS`에 등록하세요.
지도만 포함한 이번 변경에는 영상통화·채팅 수정이나 비밀 키가 없습니다.

OpenStreetMap 지도는 별도 키 없이 표시합니다. 출처 표기를 유지하고 공개 타일 서버의
[이용 정책](https://operations.osmfoundation.org/policies/tiles/)을 준수해야 합니다.
서버는 브라우저의 Referer를 차단하지 않는 정책을 사용해야 합니다.
다운로드·오프라인 프리페치 기능은 구현하지 않았습니다.

검증: `flutter analyze`, `flutter test`, `flutter build web`.
대상은 PC 브라우저이며 모바일 네이티브 권한·네트워크 설정은 별도 확인이 필요합니다.
