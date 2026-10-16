import 'dart:convert';

class MachineQr {
  const MachineQr({required this.machineId, required this.token});
  final String machineId;
  final String token;

  factory MachineQr.parse(String raw) {
    final dynamic value;
    try {
      value = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('자판기 QR이 아닙니다.');
    }
    if (value is! Map ||
        value['machine_id'] is! String ||
        value['qr_token'] is! String ||
        (value['machine_id'] as String).trim().isEmpty ||
        (value['qr_token'] as String).trim().isEmpty) {
      throw const FormatException('자판기 QR이 아닙니다.');
    }
    return MachineQr(machineId: value['machine_id'], token: value['qr_token']);
  }
}
