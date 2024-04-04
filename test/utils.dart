import 'package:obot_completion_generator/index.dart';

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
  List<TestCase> testCases;
  List<LocaleDataItem> dataset;

  TestSuite(
      {required this.name,
      required this.locale,
      required this.generatorProps,
      required this.testCases,
      required this.dataset});

  @override
  String toString() {
    return 'TestSuite(name: $name, locale: $locale, generatorProps: $generatorProps, testCases: $testCases, dataset: $dataset)';
  }
}
