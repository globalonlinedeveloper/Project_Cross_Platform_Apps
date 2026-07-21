import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:nikatru_core/nikatru_core.dart';
import 'package:nikatru_api_client/nikatru_api_client.dart';
import 'package:test/test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.status = 200});

  final String body;
  final int status;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }
}

void main() {
  test('attaches the bearer token and parses subscriptions', () async {
    final Dio dio = Dio();
    final _FakeAdapter adapter = _FakeAdapter(jsonEncode(<dynamic>[
      <String, dynamic>{
        'id': '1',
        'name': 'Netflix',
        'category': 'Streaming',
        'price': 15.0,
        'cycle': 'monthly',
        'next_renewal': '2026-08-01',
      },
    ]));
    dio.httpClientAdapter = adapter;

    final DioApiClient client = DioApiClient(
      baseUrl: 'https://example.test/v1',
      tokenProvider: () async => 'tok123',
      httpClient: dio,
    );

    final List<Subscription> subs = await client.getSubscriptions();
    expect(subs, hasLength(1));
    expect(subs.first.name, 'Netflix');
    expect(adapter.lastRequest!.headers['Authorization'], 'Bearer tok123');
  });

  test('maps error responses to ApiException', () {
    final Dio dio = Dio()
      ..httpClientAdapter = _FakeAdapter(
        jsonEncode(<String, dynamic>{'error': 'nope'}),
        status: 400,
      );
    final DioApiClient client = DioApiClient(
      baseUrl: 'https://example.test/v1',
      tokenProvider: () async => null,
      httpClient: dio,
    );
    expect(client.getSubscriptions(), throwsA(isA<ApiException>()));
  });
}
