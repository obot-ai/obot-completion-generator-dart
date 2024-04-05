import 'dart:io';

import 'package:obot_completion_generator/obot_completion_generator.dart';

void main(List<String> args) async {
  String host = "";
  String apiKey = "";
  String locale = "ja";

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
    }
  }

  print("Fetching [$locale] data from $host with API key $apiKey");

  Fetcher fetcher = Fetcher(
      apiKey: apiKey,
      getEndpoint: (String locale) {
        return "$host/input_completion/$locale/";
      });

  List<LocaleDataItem> jaData = await fetcher.fetch(locale);
  print("Fetched ${jaData.length} items: $jaData");

  Generator generator = Generator();
  generator.loadData(locale, jaData);

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
