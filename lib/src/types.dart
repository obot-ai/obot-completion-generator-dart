import 'dart:io';

class LocaleDataItem {
  String text;
  String keywords;

  LocaleDataItem({required this.text, required this.keywords});

  @override
  String toString() {
    return 'LocaleDataItem(text: $text, keywords: $keywords)';
  }
}

class MatchedResult {
  bool isMatched;
  MatchedResultData data;

  MatchedResult({required this.isMatched, required this.data});
}

class MatchedResultData {
  String text;
  String keywords;
  List<MatchedKeyword>? matchedKeywords;

  MatchedResultData(
      {required this.text, required this.keywords, this.matchedKeywords});

  @override
  String toString() {
    return 'MatchedResultData(text: $text, keywords: $keywords, matchedKeywords: $matchedKeywords)';
  }
}

class MatchedKeyword {
  String text;
  int startAt;
  int endAt;

  MatchedKeyword(
      {required this.text, required this.startAt, required this.endAt});

  @override
  String toString() {
    return 'MatchedKeyword(text: $text, startAt: $startAt, endAt: $endAt)';
  }
}

typedef LocaleDataComparator = int Function(
    LocaleDataItem itemA, LocaleDataItem itemB, String input, String locale);
typedef LocaleDataFilter = List<MatchedResultData> Function(
    List<LocaleDataItem> localeData, String input, String locale);

typedef GetEndpoint = String Function(String locale);
typedef HandleResponse = List<LocaleDataItem> Function(String responseBody);
typedef HandleHttpResponse = Future<List<LocaleDataItem>?> Function(
    HttpClientResponse response);
