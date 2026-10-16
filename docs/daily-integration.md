# Daily Flutter 통화 연결

2026-10-16. 소비자 앱의 프론트 구현이며 백엔드·키오스크 코드는 변경하지 않았습니다.

## 구현 상태

- `daily_flutter` 0.40.0을 Android/iOS 통화 엔진으로 연결했습니다. 웹/데스크톱은 실제 통화 미지원 안내와 기존 화면 미리보기를 제공합니다.
- 방 주소와 선택적 입장 토큰으로 입장, 상대/내 영상 표시, 카메라·마이크 켜기/끄기, 카메라 전환을 구현했습니다.
- 입장 중, 상대방 대기·카메라 꺼짐·퇴장, 연결 실패·재시도, 권한 오류를 표시합니다. 네트워크 자동 복구는 SDK가 담당하며, 연결이 종료된 경우에는 다시 연결 버튼을 제공합니다.
- 입장 전 카메라 미리보기를 해제하고 기존 장치 설정을 통화에 전달합니다. 직접 통화 화면을 열 경우 기본 카메라·마이크는 꺼져 있습니다.
- 백그라운드에서는 카메라·마이크와 채팅 갱신을 중지하고 복귀 시 선택한 설정으로 재개합니다. 화면 폐기/퇴장 시 이벤트 구독과 미디어 클라이언트를 해제합니다.
- 기존 반투명 채팅 UI를 유지합니다. 실제 통화에서는 상담 API의 메시지를 사용하며 Daily app-message 기능으로 대체하지 않았습니다.
- 채팅 3초 갱신, ID 중복 제거, 서버 순서 유지, 전송 실패 시 입력 보존, 상대방의 상담 종료 반영을 구현했습니다.
- 상담 종료 시 미디어를 먼저 해제한 뒤 기존 서버 종료 API를 호출합니다. 서버 반영 실패 시 재시도하거나 통화만 나갈 수 있습니다. 통화만 나가는 동작은 상담 기록을 종료하지 않습니다.
- 방/토큰은 메모리에서만 사용하고 진단 문자열에 노출하지 않습니다. 서버 API 키를 앱에 넣거나 방 생성 API를 호출하지 않습니다.

## Render와 연결한 지점

2026-10-17: 상담 생성·조회 API를 연결했습니다. `ConsultationScreen`이 상담 응답을 받으면 아래처럼 화상방을 전달합니다(`_applySnapshot`). 자세한 흐름은 [프론트엔드 구성](frontend.md#백엔드-연동-현황)을 참고하세요.

```dart
if (response['room_url'] is String) {
  AppSession.instance.attachCallRoom(
    CallRoom.fromJson(response),
    consultationId: response['id']?.toString(),
  );
}
```

`CallRoom.fromJson`은 `room_url`과 선택적인 `meeting_token`을 읽습니다. 현재 백엔드에 별도 토큰 필드가 없다면 생략하며, 이후 서버의 토큰 필드명이 다르면 이 변환 부분만 맞춥니다. 기기에 저장된 임시 사용자 ID가 있어야 상담 채팅 클라이언트가 함께 생성됩니다. 기존 세션 ID는 실제 인증이 아닙니다.

화면을 직접 여는 경우:

```dart
VideoConsultationPage(
  room: CallRoom(roomUrl: roomUrl, token: meetingToken),
  chat: ApiConsultationChat(
    consultationId: consultationId,
    userId: userId,
  ),
)
```

`chat`은 호출자가 소유하며 화면을 닫은 후 또는 세션 종료 시 `dispose()` 해야 합니다. `AppSession.attachCallRoom`으로 생성한 클라이언트는 세션이 관리합니다. 방 정보 없이 열면 기존 로컬 미리보기로 동작합니다. 실제 방에 입장했지만 상담 ID가 없으면 채팅은 비활성화되며 전송에 성공한 것처럼 표시하지 않습니다.

호출하는 기존 API:

- `GET /consultations/{id}/messages`
- `POST /consultations/{id}/messages`: `sender_role: user`, `sender_id`, `content`
- `GET /consultations/{id}`: `ended_at`, `status`로 종료 확인
- `POST /consultations/{id}/end`
- `POST /consultations/{id}/cancel`

서버 주소는 기존 `API_BASE_URL` 설정을 사용합니다.

## 실제 통화 검증은 보류

사용자 요청에 따라 Render/Daily 방에 접속하는 실제 통화 검증은 수행하지 않았습니다. 개발 모드의 화상 입장 화면에는 **개발용 Daily 테스트 방 연결** 버튼이 있습니다. 나중에 생성된 방 주소와 필요한 입장 토큰을 직접 입력할 수 있습니다. 이 화면은 방을 생성하지 않으며, 실제 상담 ID가 없으면 채팅/서버 상담 종료는 연결되지 않습니다.

Render 준비 후 Android/iOS 기기와 기존 약사 웹을 이용해 다음을 확인합니다.

1. 동일 상담의 `room_url`로 양쪽 입장, 영상·음성 송수신.
2. 권한 거부, 카메라·마이크 설정, 렌즈 전환, 앱 백그라운드/복귀.
3. 네트워크 단절과 다시 연결, 약사 입장·퇴장·카메라 끄기.
4. 상담 ID를 연결한 상태에서 앱 ↔ 기존 약사 웹 채팅과 메시지 중복 여부.
5. 양쪽에서 상담 종료, 앱의 종료 상태와 서버 요약·기록 확인.
6. 토큰이 필요한 방에서 정상·만료 토큰 처리.

## 빌드 환경

- Android: 최소 API 24, Daily 0.40.0이 사용하는 NDK `30.0.15729638`로 설정했습니다. 카메라·마이크·오디오 설정 권한을 선언했습니다.
- iOS: 프로젝트의 기존 배포 대상 15.0을 유지합니다. CocoaPods 설정과 Daily 내부 permission_handler의 카메라·마이크 권한 매크로를 추가했습니다. Mac에서 `flutter pub get` 후 `cd ios && pod install`을 진행합니다.
- 현재 작업 환경에는 Android SDK가 없어 APK 빌드를 확인하지 못했습니다. Windows 환경이므로 iOS 빌드 역시 별도 확인이 필요합니다.
- 자동 테스트는 실제 Daily 연결 대신 가짜 통화 엔진과 HTTP 응답으로 제어·재시도·정리·메시지·종료 흐름을 확인합니다. 웹 빌드는 모바일 SDK 코드가 웹 번들에서 제외되는지 확인하는 용도이며 모바일 통화 검증을 대신하지 않습니다.

참고: [Daily Flutter SDK](https://pub.dev/packages/daily_flutter), [CallClient API](https://pub.dev/documentation/daily_flutter/latest/daily_flutter/CallClient-class.html), [백엔드 Flutter 인수인계](https://github.com/JONGBOK1/moyak-backend/blob/master/docs/flutter-handoff.md).
