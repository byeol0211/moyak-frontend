/// Ephemeral room credentials supplied by the consultation API.
/// Never store these in preferences or include them in diagnostic strings.
class CallRoom {
  CallRoom({required String roomUrl, this.token, this.displayName = '모약 사용자'})
    : url = _parse(roomUrl);

  final Uri url;
  final String? token;
  final String displayName;

  factory CallRoom.fromJson(
    Map<String, dynamic> json, {
    String displayName = '모약 사용자',
  }) {
    final url = json['room_url'];
    final token = json['meeting_token'];
    if (url is! String || (token != null && token is! String)) {
      throw const FormatException('상담방 입장 정보가 올바르지 않습니다.');
    }
    return CallRoom(
      roomUrl: url,
      token: token as String?,
      displayName: displayName,
    );
  }

  static Uri _parse(String value) {
    final url = Uri.tryParse(value.trim());
    if (url == null ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.pathSegments.where((s) => s.isNotEmpty).isEmpty) {
      throw const FormatException('HTTPS 상담방 주소를 확인해주세요.');
    }
    return url;
  }

  @override
  String toString() => 'CallRoom(credentials: hidden)';
}
