import "types.dart";

List<int> range(int length, int startAt) {
  return List.generate(length, (index) => index + startAt);
}

bool isSameKeyword(MatchedKeyword kwA, MatchedKeyword kwB) {
  if (kwA.text != kwB.text || kwA.startAt != kwB.startAt || kwA.endAt != kwB.endAt) {
    return false;
  }
  return true;
}

List<LocaleDataItem> cloneLocaleData(List<LocaleDataItem> localeData) {
  return localeData.map((item) => item.clone()).toList();
}
