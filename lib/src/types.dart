class LocaleDataItem {
  String text;
  String keywords;

  LocaleDataItem({required this.text, required this.keywords});

  LocaleDataItem clone() {
    return LocaleDataItem(text: text, keywords: keywords);
  }

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
  int? idx;
  String text;
  String keywords;
  List<MatchedKeyword>? matchedKeywords;
  int? noKeywordMatchedLength;
  int? score;

  MatchedResultData(
      {this.idx,
      required this.text,
      required this.keywords,
      this.matchedKeywords,
      this.noKeywordMatchedLength,
      this.score});

  @override
  String toString() {
    return 'MatchedResultData(score: $score, idx: $idx, text: $text, keywords: $keywords, matchedKeywords: $matchedKeywords, noKeywordMatchedLength: $noKeywordMatchedLength)';
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

class NoMatchedKeywordPart {
  String text;
  int startAt;
  int endAt;

  NoMatchedKeywordPart(
      {required this.text, required this.startAt, required this.endAt});

  @override
  String toString() {
    return 'NoMatchedKeywordPart(text: $text, startAt: $startAt, endAt: $endAt)';
  }
}

typedef LocaleDataComparator = int Function(
    LocaleDataItem itemA, LocaleDataItem itemB, String input, String locale);
typedef LocaleDataFilter = List<MatchedResultData> Function(
    List<LocaleDataItem> localeData, String input, String locale);
typedef MatchedResultDataScorer = int Function(
    MatchedResultData data, String input, String locale);
typedef MatchedResultDataSort = int Function(
    MatchedResultData rsA, MatchedResultData rsB, String input, String locale);

typedef GetEndpoint = String Function(String locale);
typedef HandleResponse = List<LocaleDataItem> Function(String responseBody);
