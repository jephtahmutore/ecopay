import 'dart:convert';

import 'package:ecopay/services/exchange_rate_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns the rate and caches it', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'result': 'success', 'rates': {'ZAR': 18.25, 'USD': 1}}), 200);
    });
    final service = ExchangeRateService(client: client);

    expect(await service.usdTo('ZAR'), 18.25);
    expect(await service.usdTo('ZAR'), 18.25);
    expect(calls, 1);
  });

  test('throws a clear error when the service fails', () async {
    final client = MockClient((_) async => http.Response('error', 500));
    final service = ExchangeRateService(client: client);

    expect(() => service.usdTo('ZAR'), throwsA(isA<ExchangeRateException>()));
  });

  test('throws when the currency is missing', () async {
    final client = MockClient((_) async =>
        http.Response(jsonEncode({'result': 'success', 'rates': {'USD': 1}}), 200));
    final service = ExchangeRateService(client: client);

    expect(() => service.usdTo('ZMW'), throwsA(isA<ExchangeRateException>()));
  });
}
