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
- 환자가 종료 버튼을 누르고 **통화 나가기**를 선택하면 미디어 연결을 해제하고 결과 대기 화면으로 돌아갑니다. 환자 화면은 서버 종료 API를 호출하지 않습니다. 서버 상담 종료·요약 검토·공개는 약사 흐름에서 처리합니다.
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
- `POST /consultations/{id}/cancel`

서버 주소는 기존 `API_BASE_URL` 설정을 사용합니다.

## 실제 통화 검증 (남은 작업)

2026-10-17 기준 실제 Daily 방에 접속하는 통화 검증은 아직 하지 않았습니다. 상담 API가 연결돼 있어서, 앱을 **게스트로 계속하기**로 실행해 상담을 요청하면 Render가 만든 실제 방(`room_url`)과 상담 ID가 통화 화면에 전달됩니다.

개발 모드의 화상 입장 화면에는 **개발용 Daily 테스트 방 연결** 버튼도 있습니다. 이미 만들어진 방 주소와 필요한 입장 토큰을 직접 입력할 수 있습니다. 이 버튼은 방을 생성하지 않으며, 실제 상담 ID가 없으면 채팅/서버 상담 종료는 연결되지 않습니다.

Android 기기(앱)와 약사 웹(https://moyak-backend.onrender.com/pharmacist)으로 다음을 확인합니다.

1. 동일 상담의 `room_url`로 양쪽 입장, 영상·음성 송수신.
2. 권한 거부, 카메라·마이크 설정, 렌즈 전환, 앱 백그라운드/복귀.
3. 네트워크 단절과 다시 연결, 약사 입장·퇴장·카메라 끄기.
4. 상담 ID를 연결한 상태에서 앱 ↔ 기존 약사 웹 채팅과 메시지 중복 여부.
5. 환자가 통화 나가기 → 결과 대기 화면 이동 → 약사가 상담 종료·요약 검토·공개 → 앱에 공개 요약 표시. 환자 퇴장만으로 서버 상담이 종료되지 않는지도 확인.
6. 토큰이 필요한 방에서 정상·만료 토큰 처리.

## 빌드 환경

- Android: 최소 API 24, Daily 0.40.0이 사용하는 NDK `30.0.15729638`로 설정했습니다. 카메라·마이크·오디오 설정 권한을 선언했습니다.
- iOS: 프로젝트의 기존 배포 대상 15.0을 유지합니다. CocoaPods 설정과 Daily 내부 permission_handler의 카메라·마이크 권한 매크로를 추가했습니다. Mac에서 `flutter pub get` 후 `cd ios && pod install`을 진행합니다.
- Android: Windows에서 APK를 빌드해 갤럭시 S23(Android 16)에 설치·실행했습니다(2026-10-17). `daily_flutter`가 compileSdk 35로 고정돼 있어 `android/build.gradle.kts`에서 플러그인 compileSdk를 36으로 맞춥니다. 빌드 환경 설정은 [프론트엔드 구성](frontend.md#android-빌드-windows)을 참고하세요.
- iOS: Windows 환경이라 빌드를 확인하지 못했습니다. Mac에서 별도 확인이 필요합니다.
- 자동 테스트는 실제 Daily 연결 대신 가짜 통화 엔진과 HTTP 응답으로 제어·재시도·정리·메시지·종료 흐름을 확인합니다. 웹 빌드는 모바일 SDK 코드가 웹 번들에서 제외되는지 확인하는 용도이며 모바일 통화 검증을 대신하지 않습니다.

참고: [Daily Flutter SDK](https://pub.dev/packages/daily_flutter), [CallClient API](https://pub.dev/documentation/daily_flutter/latest/daily_flutter/CallClient-class.html), [백엔드 Flutter 인수인계](https://github.com/JONGBOK1/moyak-backend/blob/master/docs/flutter-handoff.md).

## 환자 퇴장과 요약 대기 (2026-10-17)

- `VideoConsultationPage`: 환자는 통화 연결만 닫고 상위 화면에 복귀합니다. 기존 `ApiConsultationChat.end()` 메서드는 남아 있지만 환자 종료 버튼에서는 사용하지 않습니다.
- `ConsultationScreen`: 결과 대기 화면에서 3초마다 상담을 조회합니다. `ended_at`이 있어도 `summary`가 없으면 조회를 계속하며, 상담 종료와 요약 공개가 모두 확인되거나 상담이 취소되면 중지합니다. 화면 폐기 시에도 타이머를 해제합니다.
- 요약을 공개하지 않은 상담은 화면이 살아 있는 동안 조회를 계속합니다. 요약을 생성하지 않는 상담의 최종 상태 처리는 추후 서버 계약과 함께 정해야 합니다.
- 앱은 상담 조회 응답의 공개된 `summary`만 표시합니다. 녹음 업로드·동의·약사 검토 API를 앱에서 직접 구현한 것은 아닙니다.

검증: `daily_call_test.dart`, `consultation_live_test.dart`, `frontend_flow_test.dart` 총 25개 통과. 수정한 코드·테스트 4개 파일의 정적 분석 오류 없음. 이번 종료 흐름의 실제 두 기기 통합 검증은 별도로 필요합니다.
