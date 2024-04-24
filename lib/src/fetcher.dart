import 'dart:convert';
import 'dart:io';

import 'exceptions.dart';
import 'types.dart';

class Fetcher {
  final String _apiKey;
  final String _apiKeyHeaderName;
  final String _httpMethod;
  final GetEndpoint? _getEndpoint;
  final HandleResponse? _handleResponse;

  Fetcher(
      {required String apiKey,
      String apiKeyHeaderName = "X-Secret-Key",
      String httpMethod = "GET",
      GetEndpoint? getEndpoint,
      HandleResponse? handleResponse = _defaultHandleResponse})
      : _apiKey = apiKey,
        _apiKeyHeaderName = apiKeyHeaderName,
        _httpMethod = httpMethod,
        _getEndpoint = getEndpoint,
        _handleResponse = handleResponse;

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

    dynamic response = await _fetch(endpoint, headers);
    return _handleResponse!(response);
  }

  Future<dynamic> _fetch(String endpoint, Map<String, String> headers) async {
    // HTTPRequestでデータを取得する
    String? responseBody;

    HttpClient client = HttpClient();
    HttpClientRequest request =
        await client.openUrl(_httpMethod, Uri.parse(endpoint));
    headers.forEach((key, value) {
      request.headers.add(key, value);
    });
    HttpClientResponse response = await request.close();

    try {
      // レスポンスを読み取る
      responseBody = await response.transform(utf8.decoder).join();
    } catch (e) {
      // UTF-8でデコードできない場合は例外を投げる
      throw UnexpectedResponseBodyException(
          "Failed to read response from $endpoint", response.statusCode);
    } finally {
      client.close();
    }

    if (response.statusCode != 200) {
      // ステータスコードが200以外の場合は例外を投げる
      throw FetchFailedException("Failed to fetch data from $endpoint",
          response.statusCode, responseBody);
    }
    return responseBody;
  }
}
