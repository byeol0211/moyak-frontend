import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'auth_session.dart';
import '../calls/call_room.dart';
import '../calls/consultation_chat.dart';

/// App-side session only. It does not authenticate or approve purchases.
class AppSession extends ChangeNotifier {
  static final instance = AppSession();
  String? userId;
  String? userName;
  String? username;
  String get displayName => userName?.trim().isNotEmpty == true
      ? userName!.trim()
      : username?.trim().isNotEmpty == true
      ? username!.trim()
      : userId == null
      ? '로그인 정보 없음'
      : '사용자';

  /// `/auth/me` 응답으로 받은 이름을 반영한다. username이 없으면 기존 값을 유지한다.
  void updateProfile({String? name, String? username}) {
    userName = name;
    if (username != null) this.username = username;
    notifyListeners();
  }

  String chatSummary = '';
  String consultationChatSummary = '';
  ConsultRecord? consultation;
  CallRoom? callRoom;
  String? callConsultationId;
  ConsultationChat? callChat;

  /// Called by the frontend consultation repository once its API response arrives.
  void attachCallRoom(CallRoom room, {String? consultationId}) {
    clearCallRoom();
    callRoom = room;
    callConsultationId = consultationId;
    if (consultationId != null && userId != null) {
      callChat = ApiConsultationChat(
        consultationId: consultationId,
        userId: userId!,
      );
    }
    notifyListeners();
  }

  void clearCallRoom() {
    callRoom = null;
    callConsultationId = null;
    callChat?.dispose();
    callChat = null;
  }

  final List<ConsultRecord> history = [];
  final List<PermitRecord> permits = [];
  final Set<String> _previewPermitIds = {};

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    userId = preferences.getString('moyak_user_id');
    if (userId == null) {
      userId = const Uuid().v4();
      await preferences.setString('moyak_user_id', userId!);
    }
  }

  void startConsultation({required bool direct}) {
    if (consultation?.status == ConsultStatus.pending &&
        consultation?.endedAt == null) {
      return;
    }
    consultationChatSummary = direct ? '' : chatSummary;
    consultation = ConsultRecord(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      status: ConsultStatus.pending,
      direct: direct,
    );
    notifyListeners();
  }

  /// 실제 상담 API 응답으로 받은 현재 상담 상태를 저장한다.
  void setLiveConsultation(ConsultRecord record) {
    consultation = record;
    notifyListeners();
  }

  void previewDecision(ConsultStatus status) {
    final previous = consultation;
    if (previous == null) return;
    consultation = ConsultRecord(
      id: previous.id,
      createdAt: previous.createdAt,
      status: status,
      direct: previous.direct,
      approvedDrugName: status == ConsultStatus.approved ? '예시 승인 약품' : null,
      decisionReason: status == ConsultStatus.rejected
          ? '화면 확인용 거절 사유입니다.'
          : null,
      summary: status == ConsultStatus.pending
          ? null
          : '화면 확인을 위한 예시 상담입니다. 실제 상담·처방 기록이 아닙니다.',
    );
    history.removeWhere((record) => record.id == previous.id);
    if (status != ConsultStatus.pending) history.insert(0, consultation!);
    if (status == ConsultStatus.approved &&
        _previewPermitIds.add(previous.id)) {
      permits.add(
        PermitRecord(
          drugName: '예시 승인 약품',
          status: PermitStatus.available,
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          pharmacist: '미리보기 약사',
        ),
      );
    }
    notifyListeners();
  }

  void cancelConsultation() {
    consultation = null;
    consultationChatSummary = '';
    notifyListeners();
  }

  void endPreviewConsultation() {
    final previous = consultation;
    if (previous == null) return;
    consultation = ConsultRecord(
      id: previous.id,
      createdAt: previous.createdAt,
      status: previous.status,
      direct: previous.direct,
      approvedDrugName: previous.approvedDrugName,
      decisionReason: previous.decisionReason,
      endedAt: DateTime.now(),
      summary: '통화 화면 미리보기를 종료했어요. 실제 상담·처방은 진행되지 않았습니다.',
    );
    history.removeWhere((record) => record.id == previous.id);
    history.insert(0, consultation!);
    notifyListeners();
  }

  Future<void> logout() async {
    AuthSession.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('moyak_user_id');
    userId = null;
    userName = null;
    username = null;
    clearCallRoom();
    chatSummary = '';
    consultationChatSummary = '';
    consultation = null;
    history.clear();
    permits.clear();
    _previewPermitIds.clear();
    notifyListeners();
  }
}
