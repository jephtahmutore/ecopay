import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ExchangeRateException implements Exception {
  ExchangeRateException(this.message);
  final String message;

  @override
  String toString() => 'ExchangeRateException: $message';
}

/// Fetches live exchange rates (base USD) and caches them for a short time
/// so the app does not call the API on every keystroke.
class ExchangeRateService {
  ExchangeRateService({
    http.Client? client,
    this.cacheFor = const Duration(minutes: 10),
    Uri? endpoint,
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? Uri.parse('https://open.er-api.com/v6/latest/USD');

  final http.Client _client;
  final Uri _endpoint;
  final Duration cacheFor;

  Map<String, double>? _rates;
  DateTime? _fetchedAt;

  bool get _cacheIsFresh =>
      _rates != null &&
      _fetchedAt != null &&
      DateTime.now().difference(_fetchedAt!) < cacheFor;

  /// Returns how many units of [currency] one US dollar buys.
  Future<double> usdTo(String currency) async {
    if (!_cacheIsFresh) {
      await _refresh();
    }
    final rate = _rates![currency];
    if (rate == null) {
      throw ExchangeRateException('No rate available for $currency');
    }
    return rate;
  }

  Future<void> _refresh() async {
    final http.Response response;
    try {
      response = await _client.get(_endpoint).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw ExchangeRateException('The rate service took too long to respond');
    } catch (_) {
      throw ExchangeRateException('Could not reach the rate service');
    }

    if (response.statusCode != 200) {
      throw ExchangeRateException('Rate service returned ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['result'] != 'success' || body['rates'] is! Map) {
      throw ExchangeRateException('Unexpected response from the rate service');
    }

    _rates = (body['rates'] as Map<String, dynamic>)
        .map((code, value) => MapEntry(code, (value as num).toDouble()));
    _fetchedAt = DateTime.now();
  }
}
