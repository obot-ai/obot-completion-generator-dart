import 'dart:io';

import 'package:obot_completion_generator/obot_completion_generator.dart';

void main(List<String> args) async {
  String host = "";
  String apiKey = "";
  String locale = "ja";
  int? maxResults;

  for (var i = 0; i < args.length; i++) {
    if (i >= args.length - 1) {
      break;
    }
    if (args[i] == "--host") {
      host = args[i + 1];
    } else if (args[i] == "--key") {
      apiKey = args[i + 1];
    } else if (args[i] == "--locale") {
      locale = args[i + 1];
    } else if (args[i] == "--max-results") {
      maxResults = int.tryParse(args[i + 1]) ?? 0;
    }
  }

  MatcherProperties props = MatcherProperties();
  if (maxResults != null) {
    props.maxResults = maxResults;
  }
  KeywordForwardMatcher matcher = KeywordForwardMatcher.fromProperties(props);
  // KeywordForwardMatcher matcher = KeywordForwardMatcher(maxResults: 5);
  Generator generator = Generator.fromMatcher(matcher);

  print("Fetching [$locale] data from $host with API key $apiKey");
  Fetcher fetcher = Fetcher(
      apiKey: apiKey,
      getEndpoint: (String locale) {
        return "$host/input_completion/$locale/";
      });

  try {
    List<LocaleDataItem> localeData = await fetcher.fetch(locale);
    print("Fetched ${localeData.length} items: $localeData");

    generator.loadData(locale, localeData);
  } on FetchFailedException catch (e) {
    print("Failed to fetch data. Exception: $e");
    print("ResponseBody: ${e.responseBody}");
    return;
  } on UnexpectedResponseBodyException catch (e) {
    print("Unexpected response body. Exception: $e");
    return;
  }

  while (true) {
    print("Enter a keyword to get completions:");
    String input = stdin.readLineSync() ?? "";
    if (input.isEmpty) {
      break;
    }

    List<MatchedResultData> results =
        generator.generateCompletions(input, locale);
    print("Results:");
    for (var result in results) {
      print(result);
    }
  }
}
