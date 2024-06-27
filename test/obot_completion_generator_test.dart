import 'dart:convert';
import 'dart:io';

import 'package:obot_completion_generator/obot_completion_generator.dart' hide Matcher;
import 'package:obot_completion_generator/obot_completion_generator.dart' as obot_completion_generator show Matcher;
import 'package:test/test.dart';

import 'utils.dart';

List<TestSuite> loadTestSuites() {
  /* fixtures/test-suites.jsonファイルからテストデータを読み込む */
  String jsonStr = File("./test/fixtures/test-suites.json").readAsStringSync();
  List<dynamic> data = json.decode(jsonStr);

  List<TestSuite> results = [];
  for (var item in data) {
    List<TestCase> testCases = [];
    for (var testCase in item["cases"]) {
      List<int> expectedIdx = [];
      for (var item in testCase["expectedIdx"]) {
        if (item is int) {
          expectedIdx.add(item);
        }
      }

      testCases.add(TestCase(
          name: testCase["name"],
          input: testCase["input"],
          expectedIdx: expectedIdx));
    }

    List<LocaleDataItem> localeData = [];
    for (var item in item["dataset"]) {
      localeData.add(LocaleDataItem(
          text: item['text'] as String, keywords: item['keywords'] as String));
    }

    results.add(TestSuite(
        name: item["suiteName"],
        locale: item["locale"],
        generatorProps: item["generatorProperties"],
        matcher: item["matcher"] ?? "default",
        matcherProps: item["matcherProperties"],
        testCases: testCases,
        dataset: localeData));
  }

  return results;
}

void main() {
  List<TestSuite> testSuites = loadTestSuites();

  for (TestSuite suite in testSuites) {
    group(suite.name, () {
      Generator generator;
      
      Map generatorProps = suite.generatorProps;
      Map matcherProps = suite.matcherProps;
      if (generatorProps.isNotEmpty) {
        int minKeywordLength = 2;
        if (generatorProps["minKeywordLength"] != null) {
          minKeywordLength = generatorProps["minKeywordLength"];
        }
        generator = Generator(
          minKeywordLength: minKeywordLength,
        );
      } else if (suite.matcher != "default") {
        obot_completion_generator.Matcher matcher;

        MatcherProperties matcherProperties = MatcherProperties();
        if (matcherProps["keywordSeparator"] != null) {
          matcherProperties.keywordSeparator = matcherProps["keywordSeparator"];
        }
        if (matcherProps["minKeywordLength"] != null) {
          matcherProperties.minKeywordLength = matcherProps["minKeywordLength"];
        }
        if (matcherProps["strictMatchLocales"] != null) {
          matcherProperties.strictMatchLocales = matcherProps["strictMatchLocales"];
        }
        if (matcherProps["maxResults"] != null) {
          matcherProperties.maxResults = matcherProps["maxResults"];
        }
        if (suite.matcher == "keyword") {
          matcher = KeywordMatcher.fromProperties(matcherProperties);
        } else if (suite.matcher == "keyword_forward") {
          matcher = KeywordForwardMatcher.fromProperties(matcherProperties);  
        } else if (suite.matcher == "forward") {
          matcher = ForwardMatcher.fromProperties(matcherProperties);
        } else {
          matcher = DefaultMatcher.fromProperties(matcherProperties);
        }
        generator = Generator.fromMatcher(matcher);
      } else {
        generator = Generator();
      }

      generator.loadData(suite.locale, suite.dataset);

      for (TestCase testCase in suite.testCases) {
        test(testCase.name, () {
          List<String> expectedTexts = [];
          for (int idx in testCase.expectedIdx) {
            expectedTexts.add(suite.dataset[idx].text);
          }
          List<MatchedResultData> results =
              generator.generateCompletions(testCase.input, suite.locale);
          expect(results.map((res) => res.text), equals(expectedTexts));
        });
      }
    });
  }

  group("Tests for some custom options", () {
    test("ForwardMatcher scorer ja", () {
      ForwardMatcher matcher = ForwardMatcher.fromProperties(MatcherProperties());
      Generator generator = Generator.fromMatcher(matcher);
      generator.loadData("ja", [
        LocaleDataItem(
            text: "新型コロナウイルス感染症とは何ですか？",
            keywords: ""),
        LocaleDataItem(
            text: "コロナウイルスとはどのようなウイルスですか？",
            keywords:
                "コロナウイルス,Corona Virus,COVID19,COVID-19,ころなういるす,新型コロナウイルス,Covid-19,Covid19,covid19,covid-19,COVID,コロナウィルス,ころな,COVIDー19,コロナ,新型コロナウイルス感染症,新型コロナウィルス感染症,コロな,ｺﾛﾅ,ｃoｖiｄ19,新型コロナ,新型コロナウィルス"),
        LocaleDataItem(
            text:
                "新型コロナウイルス感染症によって、事業の休止などを余儀なくされ、やむを得ず休業とする場合等にどのようなことに心がければよいのでしょうか。",
            keywords:
                "コロナウイルス,Corona Virus,COVID19,COVID-19,ころなういるす,新型コロナウイルス,Covid-19,Covid19,covid19,covid-19,COVID,コロナウィルス,ころな,COVIDー19,コロナ,新型コロナウイルス感染症,新型コロナウィルス感染症,コロな,ｺﾛﾅ,ｃoｖiｄ19,新型コロナ,新型コロナウィルス,休業,一時休業")
      ]);
      List<ScoreTestCase> cases = [
        ScoreTestCase(input: "ですか", expectedScores: [3, 3]),
        ScoreTestCase(input: "コロナウイルス", expectedScores: [17, 17, 7]),
        ScoreTestCase(input: "新型コロナウイルス", expectedScores: [19, 10, 9]),
        ScoreTestCase(input: "新型コロナウイルスとは", expectedScores: [12]),
        ScoreTestCase(input: "cOVIDとは", expectedScores: [12]),
        ScoreTestCase(input: "コロナで休業になったらどうする？", expectedScores: []),
        ScoreTestCase(input: "こんにちは、COVIDについて教えてもらえますか？", expectedScores: []),
        ScoreTestCase(input: "こんにちは、新型コロナウイルスについて教えてもらえますか？", expectedScores: [])
      ];
      for (ScoreTestCase testCase in cases) {
        List<MatchedResultData> results =
            generator.generateCompletions(testCase.input, "ja");
        expect(results.map((res) => res.score), equals(testCase.expectedScores));
      }
    });

    test("KeywordForwardMatcher scorer ja", () {
      KeywordForwardMatcher matcher = KeywordForwardMatcher.fromProperties(MatcherProperties());
      Generator generator = Generator.fromMatcher(matcher);
      generator.loadData("ja", [
        LocaleDataItem(
            text: "新型コロナウイルス感染症とは何ですか？",
            keywords: ""),
        LocaleDataItem(
            text: "コロナウイルスとはどのようなウイルスですか？",
            keywords:
                "コロナウイルス,Corona Virus,COVID19,COVID-19,ころなういるす,新型コロナウイルス,Covid-19,Covid19,covid19,covid-19,COVID,コロナウィルス,ころな,COVIDー19,コロナ,新型コロナウイルス感染症,新型コロナウィルス感染症,コロな,ｺﾛﾅ,ｃoｖiｄ19,新型コロナ,新型コロナウィルス"),
        LocaleDataItem(
            text:
                "新型コロナウイルス感染症によって、事業の休止などを余儀なくされ、やむを得ず休業とする場合等にどのようなことに心がければよいのでしょうか。",
            keywords:
                "コロナウイルス,Corona Virus,COVID19,COVID-19,ころなういるす,新型コロナウイルス,Covid-19,Covid19,covid19,covid-19,COVID,コロナウィルス,ころな,COVIDー19,コロナ,新型コロナウイルス感染症,新型コロナウィルス感染症,コロな,ｺﾛﾅ,ｃoｖiｄ19,新型コロナ,新型コロナウィルス,休業,一時休業")
      ]);
      List<ScoreTestCase> cases = [
        ScoreTestCase(input: "ですか", expectedScores: [3, 3]),
        ScoreTestCase(input: "コロナウイルス", expectedScores: [17, 17, 7]),
        ScoreTestCase(input: "新型コロナウイルス", expectedScores: [19, 10, 9]),
        ScoreTestCase(input: "新型コロナウイルスとは", expectedScores: [19, 12]),
        ScoreTestCase(input: "コロナで休業になったらどうする？", expectedScores: [25, 13]),
        ScoreTestCase(input: "こんにちは、COVIDについて教えてもらえますか？", expectedScores: [10, 10]),
        ScoreTestCase(input: "こんにちは、新型コロナウイルスについて教えてもらえますか？", expectedScores: [19, 10])
      ];
      for (ScoreTestCase testCase in cases) {
        List<MatchedResultData> results =
            generator.generateCompletions(testCase.input, "ja");
        expect(results.map((res) => res.score), equals(testCase.expectedScores));
      }
    });

    test("ForwardMatcher scorer en", () {
      ForwardMatcher matcher = ForwardMatcher.fromProperties(MatcherProperties());
      Generator generator = Generator.fromMatcher(matcher);
      generator.loadData("en", [
        LocaleDataItem(
            text: "How is the weather today?",
            keywords: ""),
        LocaleDataItem(
            text: "Can you tell me what the weather is today?",
            keywords: "today,yesterday,tomorrow,how,what"),
        LocaleDataItem(
            text: "The weather is likely to be bad tomorrow.",
            keywords: "today,yesterday,tomorrow,good,bad")
      ]);
      List<ScoreTestCase> cases = [
        ScoreTestCase(input: "how", expectedScores: [10, 3]),
        ScoreTestCase(input: "how is the weather today", expectedScores: [37, 20]),
        ScoreTestCase(input: "It seems to be a bad day today.", expectedScores: [])
      ];
      for (ScoreTestCase testCase in cases) {
        List<MatchedResultData> results =
            generator.generateCompletions(testCase.input, "en");
        expect(results.map((res) => res.score), equals(testCase.expectedScores));
      }
    });

    test("KeywordForwardMatcher scorer en", () {
      KeywordForwardMatcher matcher = KeywordForwardMatcher.fromProperties(MatcherProperties());
      Generator generator = Generator.fromMatcher(matcher);
      generator.loadData("en", [
        LocaleDataItem(
            text: "How is the weather today?",
            keywords: ""),
        LocaleDataItem(
            text: "Can you tell me what the weather is today?",
            keywords: "today,yesterday,tomorrow,how,what"),
        LocaleDataItem(
            text: "The weather is likely to be bad tomorrow.",
            keywords: "today,yesterday,tomorrow,good,bad")
      ]);
      List<ScoreTestCase> cases = [
        ScoreTestCase(input: "how", expectedScores: [10, 3]),
        ScoreTestCase(input: "how is the weather today", expectedScores: [37, 20, 10]),
        ScoreTestCase(input: "It seems to be a bad day today.", expectedScores: [23, 15])
      ];
      for (ScoreTestCase testCase in cases) {
        List<MatchedResultData> results =
            generator.generateCompletions(testCase.input, "en");
        expect(results.map((res) => res.score), equals(testCase.expectedScores));
      }
    });
  });
}
