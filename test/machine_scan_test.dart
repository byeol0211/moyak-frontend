import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/data/api_client.dart';
import 'package:moyak/data/machine_api.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _machines = {
  'items': [
    {
      'id': '760e9d5b',
      'code': 'VM-001',
      'name': '동양미래대학교 학생회관',
      'latitude': 37.5011,
      'longitude': 126.867,
    },
  ],
};

void main() {
  _findNearestTests();

  test('logs in to the machine and finds its name by code', () async {
    Map<String, dynamic>? sent;
    final client = MockClient((request) async {
      if (request.url.path == '/vending/scan') {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({
          'has_pending_purchase': true,
          'purchase': {'drug_item_name': '타이레놀정500밀리그람'},
        });
      }
      return _json(_machines);
    });
    final result = await scanMachineQr(
      machineId: 'VM-001',
      qrToken: 'token-1',
      userId: 'user-1',
      client: client,
    );
    expect(sent, {
      'machine_id': 'VM-001',
      'qr_token': 'token-1',
      'user_id': 'user-1',
    });
    expect(result.machine.name, '동양미래대학교 학생회관');
    expect(result.machine.id, '760e9d5b');
    expect(result.approvedDrugName, '타이레놀정500밀리그람');
  });

  test('still connects when the machine name cannot be found', () async {
    final client = MockClient(
      (request) async => request.url.path == '/vending/scan'
          ? _json({'has_pending_purchase': false, 'purchase': null})
          : _json({'detail': '지도 서버 오류'}, 503),
    );
    final result = await scanMachineQr(
      machineId: 'VM-099',
      qrToken: 'token-1',
      userId: 'user-1',
      client: client,
    );
    expect(result.machine.name, 'VM-099');
    expect(result.approvedDrugName, isNull);
  });

  test('passes the server reason when the QR has expired', () async {
    final client = MockClient(
      (_) async => _json({'detail': 'QR 코드가 만료되었습니다.'}, 400),
    );
    await expectLater(
      scanMachineQr(
        machineId: 'VM-001',
        qrToken: 'old',
        userId: 'user-1',
        client: client,
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'QR 코드가 만료되었습니다.',
        ),
      ),
    );
  });
}

void _findNearestTests() {
  test('rescan picks the closest machine for the given position', () async {
    Uri? requested;
    final client = MockClient((request) async {
      requested = request.url;
      return _json({
        'items': [
          {'id': 'no-position', 'name': '좌표 없는 자판기'},
          ..._machines['items']!,
        ],
      });
    });
    final machine = await findNearestMachine(
      latitude: 37.5,
      longitude: 126.86,
      client: client,
    );
    expect(requested!.path, '/api/v1/map/machines');
    expect(requested!.queryParameters, {'lat': '37.5', 'lng': '126.86'});
    expect(machine!.code, 'VM-001');
  });

  test('rescan returns null when no machine is nearby', () async {
    final client = MockClient((_) async => _json({'items': []}));
    expect(
      await findNearestMachine(latitude: 0, longitude: 0, client: client),
      isNull,
    );
  });
}
