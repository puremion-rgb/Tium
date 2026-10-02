/// 받침에 맞춰 '으로/로'를 붙인다. (ㄹ 받침은 '로')
String withRo(String word) {
  if (word.isEmpty) return word;
  final code = word.codeUnitAt(word.length - 1) - 0xAC00;
  if (code < 0 || code > 11171) return '$word(으)로';
  final jong = code % 28;
  return jong == 0 || jong == 8 ? '$word로' : '$word으로';
}

/// 받침에 맞춰 '이/가'를 붙인다.
String withIga(String word) {
  if (word.isEmpty) return word;
  final code = word.codeUnitAt(word.length - 1) - 0xAC00;
  if (code < 0 || code > 11171) return '$word이(가)';
  return code % 28 == 0 ? '$word가' : '$word이';
}
