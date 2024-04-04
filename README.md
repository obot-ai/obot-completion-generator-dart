ObotAI入力補完サーバーデータを基づき、渡される入力テキストに対し、補完候補を生成するためのパッケージ

## Features

Fetcherを利用してデータを取得し、Generatorを用いて、入力内容に対して補完データが生成できる

## Usage

```dart
import 'package:obot_completion_generator/index.dart';

void main() async {
  // Fetcherを利用してサーバーからデータを取得
  Fetcher fetcher = Fetcher(
  apiKey: "$your_api_key",
  getEndpoint: (String locale) {
      return "$api_host/input_completion/$locale/";
  }
  );
  List<LocaleDataItem> jaData = await fetcher.fetch("ja");


  Generator generator = Generator(
  minKeywordLength: 2,
  keywordSeparator: ",",
  strictMatchLocales: ["en"]
  );
  generator.loadData("ja", jaData);


  List<MatchedResultData> completions = generator.generateCompletions("こんにちは", "ja");

  print(completions);
}
```
