import 'package:obot_completion_generator/obot_completion_generator.dart';

class TestCase {
  String name;
  String input;
  List<int> expectedIdx;

  TestCase(
      {required this.name, required this.input, this.expectedIdx = const []});

  @override
  String toString() {
    return 'TestCase(name: $name, input: $input, expectedIdx: $expectedIdx)';
  }
}

class TestSuite {
  String name;
  String locale;
  Map generatorProps;
  String matcher;
  Map matcherProps;
  List<TestCase> testCases;
  List<LocaleDataItem> dataset;

  TestSuite(
      {required this.name,
      required this.locale,
      required this.generatorProps,
      this.matcher = "default",
      required this.matcherProps,
      required this.testCases,
      required this.dataset});

  @override
  String toString() {
    return 'TestSuite(name: $name, locale: $locale, generatorProps: $generatorProps, matcherProps: $matcherProps, testCases: $testCases, dataset: $dataset)';
  }
}

class ScoreTestCase {
  String input;
  List<int> expectedScores;

  ScoreTestCase({required this.input, required this.expectedScores});
}
