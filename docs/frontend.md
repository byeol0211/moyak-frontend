# 프론트엔드 구성

모약 소비자 앱(Flutter)의 화면, 파일, 백엔드 연동 현황, 빌드 방법을 정리한 문서입니다.
화면 디자인과 동작의 기준은 백엔드 저장소(`moyak-backend`)의 `src/api/static/app/<화면>/` HTML/CSS와
[백엔드 Flutter 인수인계 문서](https://github.com/JONGBOK1/moyak-backend/blob/master/docs/flutter-handoff.md)입니다.

- 화면별 확인 방법과 미리보기 기능: [frontend-progress.md](frontend-progress.md)
- 화상 통화(Daily) 구현: [daily-integration.md](daily-integration.md)
- 카카오 지도 키와 도메인: [map.md](map.md)

## 실행

```powershell
flutter pub get

# 실제 서버(Render)와 연결해서 실행
flutter run --dart-define=API_BASE_URL=https://moyak-backend.onrender.com

# 웹으로 화면만 볼 때 (카카오 지도 등록 주소가 5555 포트)
flutter run -d chrome --web-port 5555
```

- 로그인 화면에서 들어가는 방식은 다음과 같습니다.
  - **로그인 / 회원가입**: 서버 계정과 Bearer 토큰으로 실제 API를 사용합니다. 토큰은 메모리에만 유지하며 앱 재실행 시 다시 로그인합니다.
  - **게스트로 계속하기** (debug 전용): 기기에 임시 사용자 ID(`moyak_user_id`)를 만들어 API에 씁니다.
  - **회원가입 없이 화면 미리보기**: 서버 없이 예시 데이터로 모든 화면 흐름을 확인합니다.
- `API_BASE_URL`이 없으면 웹에서는 같은 출처로, 앱에서는 서버 연결 안내를 보여줍니다.
- Render 무료 서버는 한동안 안 쓰면 잠들어 첫 요청이 1분쯤 걸립니다. 상담 요청은 70초까지 기다립니다.
- 검증: `flutter analyze`, `flutter test`

## 화면 흐름

```
스플래시 → 권한 안내 → 로그인 ─┬→ 온보딩 1~4 → 메인(AppShell)
                              └→ 회원가입 1~3 ─┘
```

메인(`AppShell`)은 하단 메뉴 5개를 탭으로 전환합니다.

| 탭 | 화면 | 비고 |
|---|---|---|
| 메인 | 연결 없음 홈 / 연결된 홈 | 지도에서 자판기를 선택하거나 QR로 연결하면 연결된 홈으로 바뀝니다 |
| 지도 | 내 주변 자판기 | 목록과 검색 → 재고 상세 → "이 자판기 선택" |
| 상담하기 (가운데) | 약사 연결 대기 → 화상 상담 입장 → 통화 | 진행 중인 상담은 탭을 옮겨도 유지됩니다 |
| 모약이 | 챗봇 | 답변의 "약사에게 바로 상담하기"는 대화 내용을 약사에게 넘기며 상담을 요청합니다 |
| 마이 | 마이페이지 | 내 상담 내역, 전자 구매 허가서, 로그아웃 |

주요 이동 경로:

- **자판기:** 지도 목록 또는 검색 → 자판기 상세(실제 재고) → 선택 → 홈에 "OO 선택됨" 표시
- **바로 상담:** 가운데 "상담하기" → 상담 요청 → 화상방이 준비되면 입장 화면으로 자동 이동 → 통화
- **챗봇에서 상담:** "약사에게 바로 상담하기" → 대기 화면에 머물며 입장 버튼 표시
- **지난 상담:** 마이 → 내 상담 내역 → "자세히 보기" → 그 상담의 결과 화면

홈의 "상품 구매하기"는 기획 변경으로 제거했습니다. 재고는 지도에서 확인하고, 구매와 결제는 자판기에서 합니다.
스토어 화면(`store_page.dart`)은 나중에 다시 쓸 수 있도록 파일만 남아 있습니다.

## 백엔드 연동 현황

| 기능 | 상태 | API | 코드 |
|---|---|---|---|
| 챗봇 답변 | ✅ 연결 | `POST /chat` | `screens/chatbot_screen.dart` |
| 지도 자판기 목록 | ✅ 연결 | `GET /api/v1/map/machines?lat&lng` | `screens/map_screen/map_screen.dart` |
| 자판기 상세 재고 | ✅ 연결 | `GET /api/v1/map/machines/{id}` | `data/machine_api.dart` |
| 상담 요청 (진행 중 상담 재사용) | ✅ 연결 | `GET /consultations?status=pending&user_id=` → `POST /consultations` | `data/consultation_api.dart` |
| 상담 상태 갱신 (3초) | ✅ 연결 | `GET /consultations/{id}` | `screens/consultation_screen.dart` |
| 약사 입장 알림 (3초) | ✅ 연결 | `GET /consultations/{id}/presence` | 〃 |
| 상담 취소 | ✅ 연결 | `POST /consultations/{id}/cancel` | 〃 |
| 화상 통화 입장 | ✅ 연결 (실제 통화 검증 전) | 상담 응답의 `room_url` → Daily | `calls/`, `video_consultation_page.dart` |
| 통화 중 채팅, 환자 퇴장 | ✅ 연결 (변경된 퇴장 흐름은 기기 검증 필요) | `GET·POST /consultations/{id}/messages`, `GET /consultations/{id}`; 퇴장은 미디어 연결만 해제 | `calls/consultation_chat.dart`, `screens/video_consultation_page.dart` |
| 내 상담 내역 | ✅ 연결 | `GET /consultations?user_id=` (취소 건 제외) | `data/consultation_api.dart` |
| 전자 구매 허가서 | ✅ 연결 | `GET /vending/purchases?user_id=` | 〃 |
| QR 스캔으로 자판기 연결 | ✅ 연결 (기기 확인 완료) | `POST /vending/scan` | `data/machine_api.dart`, `qr_camera_page.dart` |
| 통화 녹음·약사 검토 요약 | ❌ 미연결 | `/consultations/{cid}/session`, `/audio`, `/summary` | 없음 |
| 로그인·회원가입 | ✅ 연결 (실제 계정·기기 검증 필요) | `POST /auth/login` 응답 사용자 이름을 마이페이지에 표시, 회원가입 `POST /auth/signup`에 `name` 전송, `GET /auth/username-available` | `data/auth_api.dart`, `data/auth_session.dart`, `screens/signup_name_screen.dart` |

공통 규칙 (`data/api_client.dart`):

- 서버 오류는 `{"detail": "한국어 메시지"}`로 오며, 그 메시지를 화면에 그대로 보여줍니다.
- 서버 시간은 UTC이고 끝에 `Z`가 없어서 `parseServerTime`으로 기기 시간으로 바꿉니다.
- 미리보기 모드에서는 `data/demo_data.dart`의 예시 데이터를 씁니다.

## 폴더 구조

```
lib/
├─ main.dart                  앱 진입점, 라우팅, AppShell(탭, 상담 세션, 하위 화면 이동)
├─ kakao_config.dart          카카오 지도 JavaScript 키와 사이트 도메인
├─ config/app_config.dart     미리보기 모드, API 주소(API_BASE_URL)
├─ theme/app_theme.dart       앱 공통 색
├─ data/
│  ├─ models.dart             화면 데이터 모델 (자판기, 재고, 상담, 허가서)
│  ├─ api_client.dart         JSON API 공통 처리, 서버 시간 변환
│  ├─ machine_api.dart        자판기 재고 API
│  ├─ consultation_api.dart   상담·상담 내역·허가서 API
│  ├─ app_session.dart        사용자 ID, 현재 상담, 화상방 정보, 챗봇 대화 요약
│  ├─ machine_qr.dart         자판기 QR 내용 검사 ({"machine_id", "qr_token"})
│  └─ demo_data.dart          미리보기용 예시 데이터
├─ calls/                     Daily 화상 통화 엔진(모바일)·웹 대체, 통화 중 채팅 클라이언트
├─ utils/                     날짜·금액 표기, 입력 검증
├─ widgets/                   하단 메뉴, 상담 헤더, 하위 화면 틀, 카메라 미리보기, 공통 버튼 등
└─ screens/
   ├─ login_page.dart, signup_step1~3_screen.dart, screen_flows.dart
   ├─ onboarding_1~4_screen.dart, permission_screen.dart
   ├─ main_home_disconnected_screen.dart   연결 없음 / 연결된 홈
   ├─ map_screen/map_screen.dart            지도, 목록, 검색, 재고 상세
   ├─ qr_camera_page.dart                   QR 스캔
   ├─ consultation_screen.dart              약사 연결 대기 (실제/미리보기/지난 상담 보기)
   ├─ consultation_entry_page.dart          화상 상담 입장 전 기기 확인
   ├─ video_consultation_page.dart          화상 통화와 채팅
   ├─ chatbot_screen.dart                   모약이 챗봇
   ├─ consult_history_screen.dart           내 상담 내역
   ├─ permit_list_screen.dart               전자 구매 허가서
   ├─ mypage.dart                           마이페이지
   ├─ store_page.dart                       (현재 미사용) 자판기 스토어
   └─ inventory_request_page.dart           (현재 미사용) 재고 신청
```

## 화면별 메모

**지도** (`map_screen.dart`)
- 내 위치 버튼으로 현재 위치를 받아 거리순으로 정렬합니다. 위치를 못 받으면 기본 위치 기준입니다.
- 검색은 거리와 관계없이 서버가 준 **전체 자판기**에서 이름·주소·자판기 코드를 대상으로, 띄어쓰기와 대소문자를 무시하고 찾습니다. 서버가 한 번에 주는 자판기는 최대 500곳입니다.

**QR 연결** (`qr_camera_page.dart`, `machine_api.dart`)
- 키오스크 화면의 QR(`{"machine_id": "VM-001", "qr_token": "..."}`)을 읽어 사용자 ID와 함께 `POST /vending/scan`으로 보냅니다. 성공하면 키오스크가 2초 안에 환영 화면으로 넘어갑니다.
- 성공하면 홈이 "OO 연동됨"으로 바뀌고, 승인된 약이 있으면 "승인된 약품(약 이름)을 자판기에서 수령하실 수 있어요"를 안내합니다.
- QR의 `machine_id`는 자판기 코드라서 지도 목록에서 같은 코드를 찾아 이름을 보여줍니다. 못 찾으면 코드를 그대로 씁니다.
- 실패하면 서버 메시지(예: "유효하지 않은 QR입니다.", "만료된 QR입니다.")와 다시 스캔을 보여줍니다. 키오스크 QR은 55초마다 바뀝니다.
- 테스트용 키오스크 QR 화면: https://moyak-backend.onrender.com/kiosk/pairing/?machine=VM-001

**약사 상담** (`consultation_screen.dart`)
- 실제 모드: 상담 요청 → 3초마다 상태·약사 입장 확인 → 승인(처방약 표시)·거절(사유)·종료(요약) 반영. 환자 퇴장 후 결과를 기다리며, 서버 상담 종료 후에도 공개 요약이 없으면 조회를 계속합니다. 종료와 공개 요약을 모두 확인하거나 취소되면 조회를 멈춥니다.
- 하단 "상담하기"로 들어오면(`direct`) 대화 요약 없이 요청하고, 화상방이 준비되면 바로 입장 화면으로 갑니다.
- 챗봇에서 들어오면 지금까지의 대화를 `사용자: … / 모약이: …` 형식으로 약사에게 전달합니다.
- 요청에 실패하면 서버 메시지와 "다시 요청하기" 버튼을 보여줍니다.
- 미리보기 모드: 상단의 "예시 상담 상태"로 대기·승인·거절 화면을 확인합니다.

## Android 빌드 (Windows)

이 PC 기준으로 정리한 환경입니다. 다른 PC도 같은 문제를 피하려면 아래를 맞춰 주세요.

| 항목 | 설정 | 이유 |
|---|---|---|
| Android SDK | `E:\AndroidSdk` (공백 없는 경로) | SDK 경로에 공백이 있으면 NDK 빌드가 실패할 수 있음 |
| NDK | `30.0.15729638` | `daily_flutter` 0.40.0이 요구 |
| Flutter 패키지 캐시 `PUB_CACHE` | 프로젝트와 **같은 드라이브** (예: `E:\flutter-pub-cache`) | 다른 드라이브면 Kotlin 증분 빌드가 "different roots" 오류로 실패 |
| Gradle 캐시 `GRADLE_USER_HOME` | `E:\Android\.gradle` | C 드라이브 용량 절약 (첫 빌드 후 수 GB) |
| 플러그인 compileSdk | `android/build.gradle.kts`에서 36 미만이면 36으로 맞춤 | `daily_flutter`가 35로 고정돼 있어 다른 플러그인 요구(36)와 충돌 |

```powershell
# 폰을 USB로 연결(USB 디버깅 허용)한 뒤
flutter run --dart-define=API_BASE_URL=https://moyak-backend.onrender.com

# 설치 파일 만들기 (디버그 APK 약 240MB)
flutter build apk --debug --dart-define=API_BASE_URL=https://moyak-backend.onrender.com

# 배포용 (폰 종류별로 나뉘어 용량이 작음)
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://moyak-backend.onrender.com
```

- 빌드 결과: `build/app/outputs/flutter-apk/`
- 현재 디버그 서명과 패키지 이름 `com.example.moyak`를 씁니다. Play 스토어에 올리려면 업로드 키와 패키지 이름 변경이 필요합니다.
- 빌드가 실패한 뒤 "already registered" 같은 Kotlin 캐시 오류가 나면 `flutter clean` 후 다시 빌드합니다.

## 테스트

| 파일 | 내용 |
|---|---|
| `test/widget_test.dart` | 스플래시 → 권한 → 로그인 진입 |
| `test/chatbot_test.dart` | 챗봇 질문 전송, 대화 기록 전달, 서버 오류 표시 |
| `test/screens_smoke_test.dart` | 402×874 화면에서 상담 미리보기, 상담 내역, 허가서, 챗봇, 지도 목록·검색·실제 재고 API, 스토어 |
| `test/machine_scan_test.dart` | QR 로그인 요청 내용, 자판기 이름 찾기, 승인 약 안내, 만료·잘못된 QR 오류 |
| `test/consultation_live_test.dart` | 실제 상담 API 흐름(가짜 서버): 요청·대화 전달, 진행 중 상담 재사용, 약사 입장·승인 반영, 취소, 오류 후 재시도, 상담 내역·허가서 변환 |
| `test/frontend_flow_test.dart` | 입력 검증, QR 형식, 사용자 ID, 작은 화면과 키보드 배치 |
| `test/daily_call_test.dart` | 화상 통화 제어·재시도·채팅·종료 (가짜 통화 엔진) |

## 남은 과제

- **실제 화상 통화 검증:** 폰 앱과 약사 웹(`/pharmacist`)으로 같은 상담에 입장해 영상·음성·채팅·종료를 확인해야 합니다.
- **통화 녹음·약사 검토 요약** 연동
- **카메라·통화 수명 주기 실기기 재검증:** 2026-10-21 카메라 초기화·해제 순서와 권한 창 처리를 보완하고 Daily를 0.41.0으로 갱신했습니다. 자동 회귀 테스트는 통과했으며, S23에서 권한 허용·통화 퇴장·재입장을 반복 확인해야 합니다. [수정 내용](daily-integration.md#2026-10-21-오류-대응)
- **화면 배치 다듬기:** 실제 기기(갤럭시 S23)에서 조정이 필요한 부분이 있습니다.
- **카카오 지도 키:** 앱의 키와 서버(`/api/v1/map/config`)의 키가 서로 다릅니다. 하나로 통일하는 것이 좋습니다.
- **지도 '길찾기' 링크:** 외부 링크를 열려면 `url_launcher` 패키지가 필요합니다.

## 직접 설치용 APK 및 인증 연동 (2026-10-17)

로그인·아이디 중복 확인·가입을 서버 API에 연결했습니다. release APK에서는 실제 로그인 또는 화면 미리보기로 진입하며, 게스트 진입은 debug 전용입니다. 토큰은 메모리에만 유지하여 앱을 다시 실행하면 재로그인합니다. 위의 게스트 실행 안내는 debug 빌드 기준입니다.

[APK 빌드·설정·제한사항](apk-release.md)을 참고하세요. Render 환경 변수와 실제 계정·기기 통합 검증은 별도로 진행합니다.
