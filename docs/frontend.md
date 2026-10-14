# 프론트엔드 구성

모약 앱(Flutter)의 화면, 파일, 데이터 연동 현황을 정리한 문서입니다.
화면 디자인의 기준은 백엔드 저장소(`moyak-backend`)의 `src/api/static/app/<화면>/` HTML/CSS입니다.

## 실행

```powershell
flutter pub get
flutter run -d chrome --web-port 5555
```

- VS Code에서는 `.vscode/launch.json`의 **moyak (Chrome, 5555)** 를 실행하면 됩니다.
- 카카오 지도는 Kakao Developers에 등록된 주소에서만 보입니다. 키와 도메인은 `lib/kakao_config.dart`에 있고, 자세한 내용은 [map.md](map.md)를 참고하세요.
- 백엔드 API 주소는 `--dart-define=API_BASE_URL=http://127.0.0.1:8002`로 지정합니다. 생략하면 웹앱과 같은 출처로 요청합니다.
- 검증: `flutter analyze`, `flutter test`

## 화면 흐름

```
스플래시 → 권한 안내 → 로그인 ─┬→ 온보딩 1~4 → 메인(AppShell)
                              └→ 회원가입 1~3 ─┘
```

메인(`AppShell`)은 하단 메뉴 5개를 탭으로 전환합니다.

| 탭 | 화면 | 비고 |
|---|---|---|
| 메인 | 연결 없음 홈 / 연결된 홈 | 자판기를 선택하거나 QR로 연결하면 연결된 홈으로 바뀝니다 |
| 지도 | 내 주변 자판기 | 목록 → 재고 상세 → "이 자판기 선택" |
| 상담하기 (가운데) | 약사 연결 대기 → 화상 상담 입장 | 탭에 들어올 때마다 새 상담 요청으로 시작합니다 |
| 모약이 | 챗봇 | 답변의 "약사에게 바로 상담하기"는 상담 탭으로 이동합니다 |
| 마이 | 마이페이지 | 내 상담 내역, 전자 구매 허가서, 재고 신청으로 이동합니다 |

QR 스캔은 탭이 아니라 홈, 상담, 챗봇 헤더의 **QR 스캔** 버튼으로 엽니다.

주요 이동 경로:

- **구매:** 지도에서 자판기 선택 → 연결된 홈에 "OO 연동됨" 표시 → **상품 구매하기** → 그 자판기 재고 조회 → 스토어
- **상담:** 가운데 "상담하기" → 연결 대기 → 화상방이 준비되면 입장 화면으로 자동 이동 → 입장하기 → 화상 상담 화면
- **챗봇에서 상담:** "약사에게 바로 상담하기" → 연결 대기 화면에 머물며 입장 버튼 표시
- **지난 상담:** 마이 → 내 상담 내역 → "자세히 보기" → 상담 결과(처방 완료, 거절) 화면

## 폴더 구조

```
lib/
├─ main.dart                 앱 진입점, 라우팅, AppShell(탭), 마이페이지, 재고 신청, 스토어
├─ kakao_config.dart         카카오 지도 JavaScript 키와 사이트 도메인
├─ data/
│  ├─ models.dart            화면에서 쓰는 데이터 모델
│  └─ demo_data.dart         백엔드 연동 전 데모 데이터 (연동할 때 이 파일만 바꿉니다)
├─ utils/
│  └─ format.dart            날짜(2025.01.15), 시각(오후 2:18), 금액(3,000원) 표기
├─ widgets/
│  ├─ app_status_bar.dart    상단 상태 표시줄(9:41, 신호, 배터리)
│  ├─ consult_header.dart    상담·챗봇 공통: 초록 팔레트, 크림색 헤더, QR 버튼, 상담 요약 본문
│  └─ sub_page_scaffold.dart 마이페이지 하위 화면 공통 틀(뒤로가기와 가운데 제목, 빈 목록 안내)
└─ screens/
   ├─ login_page.dart
   ├─ signup_step1_screen.dart / signup_step2_screen.dart / signup_step3_screen.dart
   ├─ onboarding_1_screen.dart ~ onboarding_4_screen.dart
   ├─ screen_flows.dart       회원가입, 온보딩 단계 묶음
   ├─ permission_screen.dart
   ├─ main_home_disconnected_screen.dart   연결 없음 / 연결된 홈
   ├─ map_screen/map_screen.dart
   ├─ qr_camera_page.dart
   ├─ consultation_screen.dart              약사 연결 대기 + 화상 상담 입장
   ├─ video_consultation_page.dart          화상 상담 중 화면
   ├─ chatbot_screen.dart
   ├─ consult_history_screen.dart           내 상담 내역
   └─ permit_list_screen.dart               전자 구매 허가서

assets/figma/                Figma에서 내보낸 이미지와 아이콘
test/                        위젯 테스트
```

## 파일별 설명

### 앱 뼈대

| 파일 | 주요 클래스 | 설명 |
|---|---|---|
| `main.dart` | `MoyakApp`, `SplashPage` | 테마, 스플래시(0.9초) 이후 권한 안내 → 로그인으로 이동 |
| `main.dart` | `AppShell` | 탭 전환, 연결된 자판기 상태, QR 스캔 열기, 재고 조회 후 스토어 열기, 상담 세션 관리 |
| `main.dart` | `AppBottomNavigation` | 하단 메뉴(메인/지도/상담하기/모약이/마이). 마이페이지 하위 화면에서도 같은 메뉴를 씁니다 |
| `screens/screen_flows.dart` | `SignupFlow`, `OnboardingFlow` | 회원가입 3단계와 온보딩 4장을 한 화면 안에서 넘깁니다 |

### 화면

| 파일 | 클래스 | HTML 기준 | 설명 |
|---|---|---|---|
| `screens/permission_screen.dart` | `PermissionScreen` | 없음(앱 전용) | 카메라, 위치, 마이크 권한 안내 |
| `screens/login_page.dart` | `LoginPage` | `login` | 아이디/비밀번호, SNS 로그인 버튼 |
| `screens/signup_step1~3_screen.dart` | `SignupStep1~3Screen` | `signup-step1~3` | 아이디 중복확인 → 비밀번호 → 인증 방식 선택 |
| `screens/onboarding_1~4_screen.dart` | `Onboarding1~4Screen` | `onboarding-1~4` | 공용 레이아웃은 `onboarding_2_screen.dart`의 `OnboardingPage` |
| `screens/main_home_disconnected_screen.dart` | `MainHomeDisconnectedScreen` | `main-home-disconnected` | 기기 재탐색, QR 스캔 |
| 〃 | `MainHomeConnectedScreen` | `main-home-connected` | 선택한 자판기 이름, 상품 구매하기(재고 조회 중 로딩 표시) |
| `screens/map_screen/map_screen.dart` | `MapScreen` | `map-screen` | 카카오 지도 번호 핀, 가까운 자판기 목록(거리, 운영시간, 재고 배지), 재고 상세, 선택/선택 해제 |
| `screens/qr_camera_page.dart` | `QrCameraPage` | `qr-camera` | QR 스캔 화면(현재는 가짜 QR을 누르면 생체 인증 후 연결) |
| `screens/consultation_screen.dart` | `ConsultationScreen` | `pharmacist-waiting`, `video-consult-entry` | 연결 대기(경과 시간, 진행 단계, 입장 버튼, 상담 요약, 결과 상태)와 입장 전 기기 확인 |
| `screens/video_consultation_page.dart` | `VideoConsultationPage` | 없음 | 화상 상담 중 화면(이미지 기반 시안) |
| `screens/chatbot_screen.dart` | `ChatPage` | `chatbot` | 질문, 서식 있는 답변 카드, 원문 근거 시트, 약사 상담 버튼 |
| `screens/consult_history_screen.dart` | `ConsultHistoryScreen` | `consult-history` | 상담 상태, 처방약/거절 사유, 펼쳐 보는 상담 요약 |
| `screens/permit_list_screen.dart` | `PermitListScreen` | `permit-list` | 허가서 상태(사용 가능/기간 만료/수령 완료/취소됨), 유효기간, 발급 약사 |
| `main.dart` | `Mypage` | `mypage` | 프로필, 결제 수단, 허가서/재고 신청 카드, 메뉴 |
| `main.dart` | `InventoryRequestPage` | 없음 | 없는 약품 재고 신청 |
| `main.dart` | `StorePage` | 없음(키오스크 `otc-list`와 유사) | 넘겨받은 자판기 재고로 상품 카드 표시, 품절과 의약품 잠금 표시 |

`ConsultationScreen`은 들어온 방식에 따라 다르게 동작합니다.

- `direct: true`(가운데 "상담하기"): 화상방이 준비되면 입장 화면으로 자동 이동합니다.
- `direct: false`(챗봇에서 이동): 대기 화면에 머물며 입장 버튼을 보여줍니다.
- `record:`를 넘기면(상담 내역): 그 상담의 결과 상태를 보여줍니다.

## 데이터와 백엔드 연동 현황

| 기능 | 현재 | 연동할 API |
|---|---|---|
| 챗봇 답변 | **실제 API** (`chatbot_screen.dart`) | `POST /chat` |
| 지도 자판기 목록 | **실제 API** (`map_screen.dart`) | `GET /api/v1/map/machines` |
| 자판기 재고 | 데모 `fetchMachineStock` | `GET /api/v1/map/machines/{id}` |
| 내 상담 내역 | 데모 `fetchConsultHistory` | `GET /consultations?user_id=` |
| 전자 구매 허가서 | 데모 `fetchPermits` | `GET /vending/purchases?user_id=` |
| 상담 요청, 대기, 취소 | 화면 안에서 시간차로 흉내(화상방 준비 3초, 약사 입장 8초) | `POST /consultations`, `GET /consultations/{id}`(3초 폴링), `POST /consultations/{id}/cancel` |
| 화상 상담 | 정지 이미지 미리보기, 가짜 통화 화면 | 서버가 내려주는 Daily.co `room_url` |
| QR 연결 | 가짜 QR, 데모 자판기(`demoConnectedMachine`)로 연결 | `POST /vending/scan` |
| 로그인, 회원가입 | 시연 동작 | 백엔드 HTML도 아직 API 없음 |

연동 방법:

1. `lib/data/demo_data.dart`의 함수 본문을 API 호출로 바꿉니다. 함수 이름과 반환 타입은 그대로 둡니다.
2. 모델(`lib/data/models.dart`)의 필드 이름은 백엔드 JSON에 맞춰 두었습니다. 응답 변환은 `VendingMachine.fromJson`처럼 `fromJson`을 추가합니다.
3. 백엔드 HTML은 요청 헤더로 사용자 ID(`X-Moyak-User-Id`)를 보냅니다. 앱에는 아직 사용자 ID 저장이 없어 함께 만들어야 합니다.

## 디자인 기준

화면마다 백엔드 HTML의 색을 그대로 씁니다.

| 영역 | 주요 색 |
|---|---|
| 상담, 챗봇 | 초록 `#176B5B`, 진초록 `#105348`, 민트 `#DDEEE8`, 크림 배경 `#F6F2E9`, 글자 `#342521` / `#776A64` (`widgets/consult_header.dart`에 상수로 정의) |
| 화상 상담 입장 | 헤더 `#1F2624`, 본문 `#18201E`, 강조 `#65D6A8` |
| 지도 | 배경 `#F2EBDD`, 노랑 `#FFD54F`, 글자 `#3E2723` / `#7D6D6A` |
| 상담 내역, 허가서 | 배경 `#F5F5F3`, 글자 `#3E2723` / `#7D6D6A` (`widgets/sub_page_scaffold.dart`) |
| 그 외 앱 공통 | `main.dart`의 `brandYellow #F1C744`, `ink #252525`, `mutedInk #8C8B82` |

화면 크기 기준은 Figma 프레임 402×874입니다.

## 테스트

| 파일 | 내용 |
|---|---|
| `test/widget_test.dart` | 스플래시 → 권한 → 로그인 화면 진입 |
| `test/chatbot_test.dart` | 챗봇 질문 전송, 대화 기록 전달, 서버 오류 표시 |
| `test/screens_smoke_test.dart` | 402×874 크기에서 상담 흐름, 취소 확인, 상담 내역, 허가서, 챗봇 답변 카드, 지도 목록·재고·선택, 스토어 |

## 남은 과제와 주의사항

- **목록과 상세 재고가 다를 수 있습니다.** 지도 목록의 재고 배지는 실제 API 값이고 상세 재고는 데모 데이터입니다.
- **거리는 기본 위치 기준입니다.** 위치 권한(geolocation) 연동이 없습니다.
- **'길찾기' 링크가 없습니다.** 외부 링크를 열려면 `url_launcher` 패키지 추가가 필요합니다.
- **카카오 지도 모서리:** 웹에서는 지도 박스의 둥근 모서리가 적용되지 않을 수 있습니다.
- **하단 메뉴 이름:** 백엔드 HTML 안에서도 "홈/주변약국/챗봇/내정보"와 "메인/지도/모약이/마이"가 섞여 있습니다. 앱은 후자를 씁니다.
- **QR 화면 하단 버튼:** HTML은 손전등인데 앱은 마이크 토글입니다.
- **[map.md](map.md)는 일부 예전 내용입니다.** 검색창과 "재고 상품보기" 설명은 지금 지도 화면과 다릅니다.
