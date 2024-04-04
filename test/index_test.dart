import 'dart:convert';
import 'dart:io';

import 'package:obot_completion_generator/index.dart';
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
        testCases: testCases,
        dataset: localeData));
  }

  return results;
}

void main() {
  List<TestSuite> testSuites = loadTestSuites();

  for (TestSuite suite in testSuites) {
    group(suite.name, () {
      Map generatorProps = suite.generatorProps;
      int minKeywordLength = 2;
      if (generatorProps["minKeywordLength"] != null) {
        minKeywordLength = generatorProps["minKeywordLength"];
      }
      Generator generator = Generator(
        minKeywordLength: minKeywordLength,
      );
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
}
