import 'types.dart';

class Generator {
  final String _keywordSeparator;
  final int _minKeywordLength;
  final List<String> _strictMatchLocales;
  final LocaleDataComparator? _comparator;
  final LocaleDataFilter? _filter;
  final Map<String, List<LocaleDataItem>> _data = {};

  Generator(
      {keywordSeparator = ",",
      minKeywordLength = 2,
      strictMatchLocales = const ["en"],
      comparator,
      filter})
      : _keywordSeparator = keywordSeparator,
        _minKeywordLength = minKeywordLength,
        _strictMatchLocales = strictMatchLocales,
        _comparator = comparator,
        _filter = filter;

  /* print時の文字列を定義 */
  @override
  String toString() {
    return 'Generator(keywordSeparator: $_keywordSeparator, minKeywordLength: $_minKeywordLength, strictMatchLocales: $_strictMatchLocales)';
  }

  /// 候補データをインスタンスにセットする
  /// @param locale ロケール
  /// @param localeData ロケールデータ
  loadData(String locale, List<LocaleDataItem> localeData) {
    if (localeData.isNotEmpty) {
      _data[locale] = localeData;
    }
  }

  /// 補完データを生成する
  /// @param input 入力文字列
  /// @param locale ロケール
  List<MatchedResultData> generateCompletions(String input, String locale) {
    if (input.isEmpty) {
      return [];
    }

    List<MatchedResultData> results = [];

    if (_data.containsKey(locale)) {
      List<LocaleDataItem>? localeData = _data[locale];

      if (localeData == null) {
        return [];
      }

      if (_comparator != null) {
        localeData.sort((a, b) => _comparator(a, b, input, locale));
      }

      if (_filter != null) {
        results = _filter(localeData, input, locale);
      } else {
        results = _getMatchedCompletions(localeData, input, locale);
      }
    }

    return results;
  }

  List<MatchedResultData> _getMatchedCompletions(
      List<LocaleDataItem> localeData, String input, String locale) {
    bool doStrictMatch = _strictMatchLocales.contains(locale);
    List<MatchedResultData> results = [];

    for (LocaleDataItem item in localeData) {
      MatchedResult checkResult = doStrictMatch
          ? _strictMatch(item, input.toLowerCase())
          : _match(item, input.toLowerCase());
      if (checkResult.isMatched) {
        results.add(checkResult.data);
      }
    }
    return results;
  }

  MatchedResult _match(LocaleDataItem item, String input) {
    String text = item.text.toLowerCase();
    String keywords = item.keywords.toLowerCase();

    int inputLength = input.length;
    List<MatchedKeyword> matchedKeywords = [];

    int startAt = 0;
    while (startAt < inputLength) {
      String matchedKeyword = "";
      String word = input[startAt];

      if (keywords.contains(word)) {
        int endAt = startAt;
        matchedKeyword = word;
        if (endAt < inputLength - 1) {
          // 次にまだ文字がある場合

          endAt += 1;
          // 最長のマッチできるキーワードを探し出す
          while (endAt < inputLength) {
            String checkWord = matchedKeyword + input[endAt];
            if (!keywords.contains(checkWord)) {
              endAt -= 1;
              break;
            }
            matchedKeyword = checkWord;
            endAt += 1;
          }
        }

        if (matchedKeyword.length >= _minKeywordLength) {
          matchedKeywords.add(MatchedKeyword(
              text: matchedKeyword, startAt: startAt, endAt: endAt));
        }

        startAt = endAt + 1;
      } else if (!text.contains(word)) {
        return MatchedResult(
            isMatched: false,
            data: MatchedResultData(text: item.text, keywords: item.keywords));
      } else {
        startAt += 1;
      }
    }

    List<String> unmatchedParts = [];

    int keywordIdx = 0;
    MatchedKeyword? prevKeyword;
    MatchedKeyword? currentKeyword;

    while (keywordIdx < matchedKeywords.length) {
      currentKeyword = matchedKeywords[keywordIdx];
      int prevEndAt = prevKeyword?.endAt ?? 0;
      int startAt = currentKeyword.startAt;

      if (startAt > prevEndAt) {
        unmatchedParts.add(input.substring(prevEndAt + 1, startAt));
      }

      prevKeyword = currentKeyword;
      keywordIdx += 1;
    }

    if (keywordIdx == 0) {
      unmatchedParts.add(input);
    } else if (currentKeyword != null) {
      int lastEndAt = currentKeyword.endAt;
      if (lastEndAt + 1 < inputLength) {
        unmatchedParts.add(input.substring(lastEndAt + 1, inputLength));
      }
    }

    bool isMatched = unmatchedParts.every((word) => text.contains(word));

    return MatchedResult(
        isMatched: isMatched,
        data: MatchedResultData(
            text: item.text,
            keywords: item.keywords,
            matchedKeywords: matchedKeywords));
  }

  MatchedResult _strictMatch(LocaleDataItem item, String input) {
    // 候補データの質問内容とキーワード
    String text = item.text.toLowerCase();

    // 英語などのスペース区切りの言語は、単語ごとにマッチする
    // NOTE: なるべくマッチしやすいよう、複数の単語でできたキーワードも分割して、一単語でもマッチ成功と見なす
    List<String> keywords = [];
    item.keywords.toLowerCase().split(_keywordSeparator).forEach((kparts) {
      kparts.split(" ").forEach((kp) {
        keywords.add(kp);
      });
    });

    List<String> inputs = input.split(" ");
    String lastInputPart = inputs.removeLast();

    // 最後の単語だけは入力途中なので、部分一致でマッチ
    bool lastInputMatched = text.contains(lastInputPart) ||
        keywords.any((kw) => kw.contains(lastInputPart));
    if (!lastInputMatched) {
      return MatchedResult(
          isMatched: false,
          data: MatchedResultData(text: item.text, keywords: item.keywords));
    }

    List<MatchedKeyword> matchedKeywords =
        inputs.where((ipt) => keywords.contains(ipt)).map((kw) {
      int startAt = input.indexOf(kw);
      int endAt = startAt + kw.length;
      return MatchedKeyword(text: kw, startAt: startAt, endAt: endAt);
    }).toList();

    List<String> unmatchedParts =
        inputs.where((ipt) => !keywords.contains(ipt)).toList();
    bool isMatched = unmatchedParts.every((word) => text.contains(word));

    return MatchedResult(
        isMatched: isMatched,
        data: MatchedResultData(
            text: item.text,
            keywords: item.keywords,
            matchedKeywords: matchedKeywords));
  }
}
