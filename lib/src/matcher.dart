import "types.dart";
import "utils.dart" show isSameKeyword, range, cloneLocaleData;

class MatcherProperties {
  String keywordSeparator;
  int minKeywordLength;
  List<String> strictMatchLocales;
  LocaleDataComparator? comparator;
  LocaleDataFilter? filter;
  MatchedResultDataScorer? scorer;
  MatchedResultDataSort? sort;
  int? maxResults;

  MatcherProperties(
      {this.keywordSeparator = ",",
      this.minKeywordLength = 2,
      this.strictMatchLocales = const ["en"],
      this.comparator,
      this.filter,
      this.scorer,
      this.sort,
      this.maxResults});
}

class Matcher {
  final String _keywordSeparator;
  final int _minKeywordLength;
  final List<String> _strictMatchLocales;
  final LocaleDataComparator? _comparator;
  final LocaleDataFilter? _filter;
  final MatchedResultDataScorer? _scorer;
  final MatchedResultDataSort? _sort;
  final Map<String, List<LocaleDataItem>> _data;
  final int? _maxResults;

  Matcher(
      {String keywordSeparator = ",",
      int minKeywordLength = 2,
      List<String> strictMatchLocales = const ["en"],
      LocaleDataComparator? comparator,
      LocaleDataFilter? filter,
      MatchedResultDataScorer? scorer,
      MatchedResultDataSort? sort,
      int? maxResults})
      : _keywordSeparator = keywordSeparator,
        _minKeywordLength = minKeywordLength,
        _strictMatchLocales = strictMatchLocales,
        _comparator = comparator,
        _filter = filter,
        _scorer = scorer,
        _sort = sort,
        _maxResults = maxResults,
        _data = {};

  Matcher.fromProperties(MatcherProperties props)
      : _keywordSeparator = props.keywordSeparator,
        _minKeywordLength = props.minKeywordLength,
        _strictMatchLocales = props.strictMatchLocales,
        _comparator = props.comparator,
        _filter = props.filter,
        _scorer = props.scorer,
        _sort = props.sort,
        _maxResults = props.maxResults,
        _data = {};

  void loadData(String locale, List<LocaleDataItem> localeData) {
    _data[locale] = localeData;
  }

  List<MatchedResultData> match(String input, String locale) {
    List<MatchedResultData> results = _match(input, locale);

    _scoreResults(results, input, locale);
    _sortResults(results, input, locale);

    if (_maxResults != null &&
        _maxResults > 0 &&
        _maxResults < results.length) {
      return results.sublist(0, _maxResults);
    }
    return results;
  }

  List<MatchedResultData> _match(String input, String locale) {
    return [];
  }

  void _scoreResults(
      List<MatchedResultData> results, String input, String locale) {
    MatchedResultDataScorer scorer;
    if (_scorer != null) {
      scorer = _scorer;
    } else {
      scorer = _defaultScorer;
    }
    for (MatchedResultData data in results) {
      data.score = scorer(data, input, locale);
    }
  }

  int _defaultScorer(MatchedResultData data, String input, String locale) {
    String text = data.text.toLowerCase();
    int score = 0;
    if (data.matchedKeywords != null) {
      score += 10 * data.matchedKeywords!.length;

      for (MatchedKeyword kw in data.matchedKeywords!) {
        String kwText = kw.text.toLowerCase();

        int plus = 0;
        if (text.contains(kwText)) {
          plus = kwText.length;
        }
        score += plus;
      }
    }
    if (data.noKeywordMatchedLength != null) {
      score += data.noKeywordMatchedLength!;
    }
    return score;
  }

  void _sortResults(
      List<MatchedResultData> results, String input, String locale) {
    MatchedResultDataSort sort;
    if (_sort != null) {
      sort = _sort;
    } else {
      sort = _defaultSort;
    }
    results.sort((rsA, rsB) => sort(rsA, rsB, input, locale));
  }

  int _defaultSort(MatchedResultData rsA, MatchedResultData rsB, String input,
      String locale) {
    if (rsA.score != null && rsB.score != null) {
      return rsB.score! - rsA.score!;
    }
    return 0;
  }
}

class ForwardMatcher extends Matcher {
  ForwardMatcher(
      {super.keywordSeparator,
      super.minKeywordLength,
      super.strictMatchLocales,
      super.comparator,
      super.filter,
      super.scorer,
      super.sort,
      super.maxResults})
      : super();
  ForwardMatcher.fromProperties(super.props) : super.fromProperties();

  @override
  List<MatchedResultData> _match(String input, String locale) {
    if (!_data.containsKey(locale)) {
      return [];
    }
    List<LocaleDataItem> localeDataOrigin = _data[locale]!;
    List<LocaleDataItem> localeData = List.from(localeDataOrigin);

    if (_comparator != null) {
      LocaleDataComparator comparator = _comparator;
      localeData
          .sort((itemA, itemB) => comparator(itemA, itemB, input, locale));
    }

    if (_filter != null) {
      LocaleDataFilter filter = _filter;
      return filter(localeData, input, locale);
    }

    return _forwardMatch(localeData, input.toLowerCase(), locale);
  }

  List<MatchedResultData> _forwardMatch(
      List<LocaleDataItem> localeData, String input, String locale) {
    bool doStrictMatch = _strictMatchLocales.contains(locale);

    List<MatchedResultData> results = [];
    for (LocaleDataItem item in localeData) {
      MatchedResult checkResult;
      if (doStrictMatch) {
        checkResult = _wordMatch(item, input);
      } else {
        checkResult = _charMatch(item, input);
      }

      if (checkResult.isMatched) {
        results.add(checkResult.data);
      }
    }
    return results;
  }

  MatchedResult _charMatch(LocaleDataItem dataItem, String input) {
    String text = dataItem.text.toLowerCase();
    String keywords = dataItem.keywords.toLowerCase();
    int minKeywordLength = _minKeywordLength;

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
          while (endAt < inputLength) {
            String checkWord = matchedKeyword + input[endAt];
            if (!keywords.contains(checkWord)) {
              endAt -= 1;
              break;
            }
            matchedKeyword = checkWord;
            endAt += 1;
          }
          if (endAt == inputLength) {
            endAt -= 1;
          }
        }

        if (matchedKeyword.length >= minKeywordLength) {
          matchedKeywords.add(MatchedKeyword(
              text: matchedKeyword, startAt: startAt, endAt: endAt));
        }

        startAt = endAt + 1;
      } else if (!text.contains(word)) {
        return MatchedResult(
            isMatched: false,
            data: MatchedResultData(
                text: dataItem.text, keywords: dataItem.keywords));
      } else {
        startAt += 1;
      }
    }

    List<NoMatchedKeywordPart> noMatchedKeywordParts = [];
    int keywordIdx = 0;
    MatchedKeyword? prevKeyword;
    MatchedKeyword? currentKeyword;
    while (keywordIdx < matchedKeywords.length) {
      currentKeyword = matchedKeywords[keywordIdx];
      int prevEndAt = prevKeyword?.endAt ?? -1;
      int startAt = currentKeyword.startAt;

      if (startAt > prevEndAt + 1) {
        noMatchedKeywordParts.add(NoMatchedKeywordPart(
            text: input.substring(prevEndAt + 1, startAt),
            startAt: prevEndAt + 1,
            endAt: startAt - 1));
      }

      prevKeyword = currentKeyword;
      keywordIdx += 1;
    }
    if (keywordIdx == 0) {
      noMatchedKeywordParts.add(NoMatchedKeywordPart(
          text: input, startAt: 0, endAt: inputLength - 1));
    } else if (currentKeyword != null) {
      int lastEndAt = currentKeyword.endAt;
      if (lastEndAt + 1 < inputLength) {
        noMatchedKeywordParts.add(NoMatchedKeywordPart(
            text: input.substring(lastEndAt + 1),
            startAt: lastEndAt + 1,
            endAt: inputLength - 1));
      }
    }
    bool isMatched =
        noMatchedKeywordParts.every((part) => text.contains(part.text));
    int noKeywordMatchedLength = 0;
    for (NoMatchedKeywordPart part in noMatchedKeywordParts) {
      noKeywordMatchedLength += part.text.length;
    }
    return MatchedResult(
        isMatched: isMatched,
        data: MatchedResultData(
            text: dataItem.text,
            keywords: dataItem.keywords,
            matchedKeywords: matchedKeywords,
            noKeywordMatchedLength: noKeywordMatchedLength));
  }

  MatchedResult _wordMatch(LocaleDataItem dataItem, String input) {
    String text = dataItem.text.toLowerCase();
    List<String> keywords = [];
    dataItem.keywords.toLowerCase().split(_keywordSeparator).forEach((kparts) {
      kparts.split(" ").forEach((kp) {
        keywords.add(kp);
      });
    });

    List<String> inputs = input.split(" ");
    String lastInputPart = inputs.removeLast();

    bool lastInputKeyword = keywords.any((kw) => kw.contains(lastInputPart));
    bool lastInputMatched = lastInputKeyword || text.contains(lastInputPart);
    if (!lastInputMatched) {
      return MatchedResult(
          isMatched: false,
          data: MatchedResultData(
              text: dataItem.text, keywords: dataItem.keywords));
    }

    List<MatchedKeyword> matchedKeywords = [];
    int lastEndAt = 0;
    for (String mkw in inputs.where((ipt) => keywords.contains(ipt))) {
      int startAt = input.indexOf(mkw, lastEndAt);
      int endAt = startAt + mkw.length - 1;
      matchedKeywords
          .add(MatchedKeyword(text: mkw, startAt: startAt, endAt: endAt));
      lastEndAt = endAt;
    }
    if (lastInputKeyword) {
      int startAt = input.indexOf(lastInputPart, lastEndAt);
      matchedKeywords.add(MatchedKeyword(
          text: lastInputPart,
          startAt: startAt,
          endAt: startAt + lastInputPart.length - 1));
    }

    List<String> unmatchedParts =
        inputs.where((ipt) => !keywords.contains(ipt)).toList();
    bool isMatched = unmatchedParts.every((word) => text.contains(word));

    int noKeywordMatchedLength = lastInputKeyword ? 0 : lastInputPart.length;
    for (String part in unmatchedParts) {
      noKeywordMatchedLength += part.length;
    }

    return MatchedResult(
        isMatched: isMatched,
        data: MatchedResultData(
            text: dataItem.text,
            keywords: dataItem.keywords,
            matchedKeywords: matchedKeywords,
            noKeywordMatchedLength: noKeywordMatchedLength));
  }
}

class KeywordMatcher extends Matcher {
  final Map<String, RegExp> _exactRegExpMap = {};
  final Map<String, RegExp> _partialRegExpMap = {};

  KeywordMatcher(
      {super.keywordSeparator,
      super.minKeywordLength,
      super.strictMatchLocales,
      super.comparator,
      super.filter,
      super.scorer,
      super.sort,
      super.maxResults})
      : super();

  KeywordMatcher.fromProperties(super.props) : super.fromProperties();

  @override
  void loadData(String locale, List<LocaleDataItem> localeData) {
    super.loadData(locale, localeData);

    Set<String> keywordSet = {};
    for (LocaleDataItem item in localeData) {
      String itemKeywords = item.keywords;
      List<String> splits = itemKeywords.split(_keywordSeparator);
      for (String kw in splits) {
        if (kw.isNotEmpty) {
          keywordSet.add(kw.toLowerCase());
        }
      }
    }

    List<String> allKeywords = List.from(keywordSet);
    if (allKeywords.isEmpty) {
      return;
    }

    allKeywords.sort((kwA, kwB) {
      return kwB.length - kwA.length;
    });

    _exactRegExpMap[locale] =
        RegExp(allKeywords.join("|"), caseSensitive: false);

    List<String> partialPatterns = [];
    for (String kw in allKeywords) {
      if (kw.length > _minKeywordLength) {
        String partStr = kw.substring(0, _minKeywordLength);
        List<String> parts = [partStr];
        for (int num
            in range(kw.length - _minKeywordLength, _minKeywordLength)) {
          partStr += kw[num];
          parts.add(partStr);
        }
        parts = parts.reversed.toList();
        partialPatterns.add(parts.join("|"));
      } else if (kw.isNotEmpty) {
        partialPatterns.add(kw);
      }
    }
    _partialRegExpMap[locale] =
        RegExp(partialPatterns.join("|"), caseSensitive: false);
  }

  @override
  List<MatchedResultData> _match(String input, String locale) {
    if (!_data.containsKey(locale)) {
      return [];
    }
    List<LocaleDataItem> localeDataOrigin = _data[locale]!;
    List<LocaleDataItem> localeData = List.from(localeDataOrigin);

    if (_comparator != null) {
      LocaleDataComparator comparator = _comparator;
      localeData
          .sort((itemA, itemB) => comparator(itemA, itemB, input, locale));
    }

    return _keywordMatch(localeData, input.toLowerCase(), locale);
  }

  List<MatchedResultData> _keywordMatch(
      List<LocaleDataItem> localeData, String input, String locale) {
    List<MatchedResultData> results = [];
    RegExp? exactRegExp = _exactRegExpMap[locale];
    if (localeData.isNotEmpty && exactRegExp != null) {
      List<RegExpMatch> matches = exactRegExp.allMatches(input).toList();
      if (matches.isEmpty) {
        RegExp? partialRegExp = _partialRegExpMap[locale];
        if (partialRegExp != null) {
          matches = partialRegExp.allMatches(input).toList();
        }
      }
      if (matches.isNotEmpty) {
        int lastEndAt = 0;
        List<MatchedKeyword> matchedKeywords = [];
        for (RegExpMatch match in matches) {
          int startAt = input.indexOf(match.group(0)!, lastEndAt);
          int endAt = startAt + match.group(0)!.length - 1;
          matchedKeywords.add(MatchedKeyword(
              text: match.group(0)!, startAt: startAt, endAt: endAt));
          lastEndAt = endAt;
        }
        for (LocaleDataItem item in localeData) {
          List<MatchedKeyword> matched = [];
          String itemKeywords = item.keywords.toLowerCase();
          for (MatchedKeyword kwItem in matchedKeywords) {
            if (itemKeywords.contains(kwItem.text)) {
              matched.add(kwItem);
            }
          }
          if (matched.isNotEmpty) {
            results.add(MatchedResultData(
                text: item.text,
                keywords: item.keywords,
                matchedKeywords: matched));
          }
        }
      }
    }

    return results;
  }
}

class ConcatMatcher extends Matcher {
  final List<Matcher> _matchers = [];

  ConcatMatcher(
      {super.keywordSeparator,
      super.minKeywordLength,
      super.strictMatchLocales,
      super.comparator,
      super.filter,
      super.scorer,
      super.sort,
      super.maxResults})
      : super();
  ConcatMatcher.fromProperties(super.props) : super.fromProperties();

  void addMatcherByClass(Type matcherClass) {
    if (matcherClass == ForwardMatcher) {
      addMatcher(ForwardMatcher(
        keywordSeparator: _keywordSeparator,
        minKeywordLength: _minKeywordLength,
        strictMatchLocales: _strictMatchLocales,
        comparator: _comparator,
      ));
    } else if (matcherClass == KeywordMatcher) {
      addMatcher(KeywordMatcher(
        keywordSeparator: _keywordSeparator,
        minKeywordLength: _minKeywordLength,
        strictMatchLocales: _strictMatchLocales,
        comparator: _comparator,
      ));
    }
  }

  void addMatcher(Matcher matcher) {
    _matchers.add(matcher);
  }

  @override
  void loadData(String locale, List<LocaleDataItem> localeData) {
    for (Matcher matcher in _matchers) {
      matcher.loadData(locale, cloneLocaleData(localeData));
    }
  }

  @override
  List<MatchedResultData> _match(String input, String locale) {
    List<MatchedResultData> results = [];
    for (Matcher matcher in _matchers) {
      List<MatchedResultData> matched = matcher.match(input, locale);
      for (MatchedResultData result in matched) {
        MatchedResultData? exists;
        try {
          exists = results.firstWhere((rt) => rt.text == result.text);
        } catch (e) {
          exists = null;
        }
        if (exists != null) {
          List<MatchedKeyword>? existsMatchedKeywords = exists.matchedKeywords;
          List<MatchedKeyword>? resultMatchedKeywords = result.matchedKeywords;
          List<MatchedKeyword> mergedMatchedKeywords = [];
          if (existsMatchedKeywords != null) {
            for (MatchedKeyword kw in existsMatchedKeywords) {
              if (!mergedMatchedKeywords.any((mkw) => isSameKeyword(kw, mkw))) {
                mergedMatchedKeywords.add(kw);
              }
            }
          }
          if (resultMatchedKeywords != null) {
            for (MatchedKeyword kw in resultMatchedKeywords) {
              if (!mergedMatchedKeywords.any((mkw) => isSameKeyword(kw, mkw))) {
                mergedMatchedKeywords.add(kw);
              }
            }
          }
          mergedMatchedKeywords = mergedMatchedKeywords.toSet().toList();
          exists.matchedKeywords = mergedMatchedKeywords;
        } else {
          results.add(result);
        }
      }
    }
    return results;
  }
}

class KeywordForwardMatcher extends ConcatMatcher {
  KeywordForwardMatcher(
      {super.keywordSeparator,
      super.minKeywordLength,
      super.strictMatchLocales,
      super.comparator,
      super.scorer,
      super.sort,
      super.maxResults})
      : super() {
    _initMatchers();
  }
  KeywordForwardMatcher.fromProperties(super.props) : super.fromProperties() {
    _initMatchers();
  }

  void _initMatchers() {
    addMatcher(ForwardMatcher(
      keywordSeparator: _keywordSeparator,
      minKeywordLength: _minKeywordLength,
      strictMatchLocales: _strictMatchLocales,
      comparator: _comparator,
    ));
    addMatcher(KeywordMatcher(
      keywordSeparator: _keywordSeparator,
      minKeywordLength: _minKeywordLength,
      strictMatchLocales: _strictMatchLocales,
      comparator: _comparator,
    ));
  }
}

typedef DefaultMatcher = ForwardMatcher;
