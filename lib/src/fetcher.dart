import 'dart:convert';
import 'dart:io';

import 'types.dart';

class Fetcher {
  final String _apiKey;
  final String _apiKeyHeaderName;
  final String _httpMethod;
  final GetEndpoint? _getEndpoint;
  final HandleResponse? _handleResponse;
  final HandleHttpResponse? _handleHttpResponse;

  Fetcher(
      {required String apiKey,
      String apiKeyHeaderName = "X-Secret-Key",
      String httpMethod = "GET",
      GetEndpoint? getEndpoint,
      HandleResponse? handleResponse = _defaultHandleResponse,
      HandleHttpResponse? handleHttpResponse})
      : _apiKey = apiKey,
        _apiKeyHeaderName = apiKeyHeaderName,
        _httpMethod = httpMethod,
        _getEndpoint = getEndpoint,
        _handleResponse = handleResponse,
        _handleHttpResponse = handleHttpResponse;

  static List<LocaleDataItem> _defaultHandleResponse(String responseBody) {
    List<LocaleDataItem> results = [];
    dynamic data = json.decode(responseBody);
    if (data['user_says'] != null && data['user_says'] is List) {
      data['user_says'].forEach((item) {
        results.add(LocaleDataItem(
            text: item['text'] as String,
            keywords: item['keywords'] as String));
      });
    }
    return results;
  }

  Future<List<LocaleDataItem>> fetch(String locale) async {
    String endpoint = _getEndpoint!(locale);
    Map<String, String> headers = {_apiKeyHeaderName: _apiKey};

    HttpClient client = HttpClient();
    HttpClientRequest request =
        await client.openUrl(_httpMethod, Uri.parse(endpoint));
    headers.forEach((key, value) {
      request.headers.add(key, value);
    });
    HttpClientResponse response = await request.close();

    if (_handleHttpResponse != null) {
      // HttpClientResponseを任意に扱うメソッドの定義があればそれを使う

      List<LocaleDataItem>? handled = await _handleHttpResponse(response);
      if (handled != null) {
        // レスポンスを処理した結果があればそれを返す、なければデフォルトの処理を行う
        client.close(force: true);
        return handled;
      }
    }

    String responseBody;
    try {
      responseBody = await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
    return _handleResponse!(responseBody);
  }
}
