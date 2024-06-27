import 'types.dart';
import 'matcher.dart';

class Generator {
  final Matcher _matcher;

  factory Generator(
          {String keywordSeparator = ",",
          int minKeywordLength = 2,
          List<String> strictMatchLocales = const ["en"],
          LocaleDataComparator? comparator,
          LocaleDataFilter? filter,
          MatchedResultDataScorer? scorer,
          MatchedResultDataSort? sort,
          int? maxResults}) =>
      Generator.fromMatcher(DefaultMatcher(
          keywordSeparator: keywordSeparator,
          minKeywordLength: minKeywordLength,
          strictMatchLocales: strictMatchLocales,
          comparator: comparator,
          filter: filter,
          scorer: scorer,
          sort: sort,
          maxResults: maxResults));

  Generator.fromMatcher(Matcher matcher) : _matcher = matcher;

  /// 候補データをインスタンスにセットする
  /// @param locale ロケール
  /// @param localeData ロケールデータ
  loadData(String locale, List<LocaleDataItem> localeData) {
    if (localeData.isNotEmpty) {
      _matcher.loadData(locale, localeData);
    }
  }

  /// 補完データを生成する
  /// @param input 入力文字列
  /// @param locale ロケール
  List<MatchedResultData> generateCompletions(String input, String locale) {
    if (input.isEmpty) {
      return [];
    }

    List<MatchedResultData> results = _matcher.match(input, locale);
    return results;
  }
}
